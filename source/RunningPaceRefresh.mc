import Toybox.Application;
import Toybox.Lang;
import Toybox.System;
import Toybox.Time;

// Shared compute-and-persist logic for the weighted pace and trend. Since #49
// it has exactly three callers, and two of them are in background scope:
//
//  - RunningPaceBackgroundService.onActivityCompleted() - fires when a run
//    finishes, so the Glance reflects it without the widget being opened.
//  - RunningPaceBackgroundService.onTemporalEvent() - the local-midnight
//    backstop that catches anything the event missed.
//  - running_pace_trendApp.getInitialView(), on a fresh or upgraded install
//    ONLY, where there is nothing drawable in Storage yet.
//
// #49 removed the fourth: the on-open foreground refresh (#40, deferred to a
// post-first-frame timer and then chunked by #47's follow-up). Every regression
// since v1.7.5 came from trying to find somewhere on the UI thread to put a
// 2.7-second synchronous scan, and there isn't one - Monkey C cannot yield
// mid-computation. Background scope removes the problem rather than relocating
// it, and the data now updates right after the run instead of on the next open.
//
// Runs outside the Glance's execution budget (glance-standards.md Data
// Refresh); RunningPaceGlanceView only ever reads the Application.Storage
// values this writes. On the very first successful run (no snapshots stored
// yet), RunningPaceTrendBackfill seeds that history retroactively from the same
// `records` already loaded this call, so the graph screen has real trend data
// immediately instead of only accumulating forward from install day (#29).
class RunningPaceRefresh {

    private static const SECONDS_PER_DAY = 86400;

    // THIS CLASS MUST NEVER BE INVOKED FROM GLANCE SCOPE. It is not
    // (:glance), so it does not exist in the Glance's separate 32kB binary,
    // and calling into it from there aborts the Glance process natively with
    // "Illegal Access (Out of Bounds) / Failed invoking <symbol>" - not a
    // catchable exception. That is exactly what #47 turned out to be: it was
    // called from running_pace_trendApp.onStart(), which the Glance also
    // runs, so the Glance died on every render once the 60s refresh throttle
    // expired. Its callers are listed in the class comment above; none of them
    // is reachable from the Glance.
    //
    // #40's bisection also concluded that ADDING a method to this class
    // crashed onStart() while changing an existing signature did not. That
    // rule was derived before the scope mechanism above was understood and
    // may simply have been the same symbol-resolution failure in another
    // guise, so it is no longer stated as law - but treat this class as
    // load-bearing and re-test on-device (not just in the simulator, which
    // never reproduced #47) after changing its shape. See RESEARCH.md.

    // Runs the whole refresh synchronously - scan included. Measured at ~2.7s
    // on-device, essentially all of it inside the scan, so this BLOCKS its
    // caller for that long. All three callers can afford it: two are background
    // events with no UI to freeze, and the third has nothing drawable to show
    // until it finishes.
    //
    // Returns whether the run succeeded, so RunningPaceBackgroundService's
    // midnight path (#40) can retry a failed/throwing attempt.
    //
    // #49 folded the former computeAndStore() tail back in here. It was split
    // out by #47's follow-up so the chunked foreground caller could finish
    // without re-scanning; that caller is gone, and this was its only other
    // one.
    static function run() as Boolean {
        var now = Time.now();

        var reader = new RunningActivityHistoryReader();
        var records;
        var scannedCount;
        try {
            records = reader.readAll(_windowStartFor(now));
            scannedCount = reader.lastScannedCount;
        } catch (exception instanceof Lang.Exception) {
            // Leave any previously computed Storage values in place rather than
            // overwrite good data with a transient read failure. The midnight
            // path retries on this false return per #40; the activity-completed
            // path lets midnight catch it.
            return false;
        }

        try {
            var result = RunningPaceCalculator.calculate(records, now);
            var trendResult = RunningPaceTrendCalculator.compare(records, now, result);

            Application.Storage.setValue("runningPaceHasSufficientData", result["runningPaceHasSufficientData"] as Boolean);
            Application.Storage.setValue("runningPaceSecondsPerKm", result["runningPaceSecondsPerKm"] as Number?);
            Application.Storage.setValue("runningPaceLastComputedAt", result["runningPaceLastComputedAt"] as Number);
            Application.Storage.setValue("runningPaceTotalDistanceMeters", result["runningPaceTotalDistanceMeters"] as Number?);
            Application.Storage.setValue("runningPaceQualifyingActivityCount", result["runningPaceQualifyingActivityCount"] as Number?);

            Application.Storage.setValue("runningPaceTrendHasSufficientData", trendResult["runningPaceTrendHasSufficientData"] as Boolean);
            Application.Storage.setValue("runningPaceTrendDirection", trendResult["runningPaceTrendDirection"] as Number?);
            Application.Storage.setValue("runningPaceTrendDeltaSecondsPerKm", trendResult["runningPaceTrendDeltaSecondsPerKm"] as Number?);
            Application.Storage.setValue("runningPaceTrendCurrentSecondsPerKm", trendResult["runningPaceTrendCurrentSecondsPerKm"] as Number?);
            Application.Storage.setValue("runningPaceTrendPreviousSecondsPerKm", trendResult["runningPaceTrendPreviousSecondsPerKm"] as Number?);
            Application.Storage.setValue("runningPaceTrendPercentChangeTenths", trendResult["runningPaceTrendPercentChangeTenths"] as Number?);
            Application.Storage.setValue("runningPaceTrendPreviousWindowStartEpoch", trendResult["runningPaceTrendPreviousWindowStartEpoch"] as Number);
            Application.Storage.setValue("runningPaceTrendCurrentWindowStartEpoch", trendResult["runningPaceTrendCurrentWindowStartEpoch"] as Number);
            Application.Storage.setValue("runningPaceTrendCurrentWindowEndEpoch", trendResult["runningPaceTrendCurrentWindowEndEpoch"] as Number);

            if (result["runningPaceHasSufficientData"] as Boolean) {
                var existingSnapshots = Application.Storage.getValue("runningPaceTrendSnapshots") as Array<Dictionary>?;
                if (existingSnapshots == null) {
                    existingSnapshots = RunningPaceTrendBackfill.buildSnapshots(records, now);
                }

                var updatedSnapshots = RunningPaceTrendHistory.recordSnapshot(
                    existingSnapshots,
                    now.value(),
                    result["runningPaceSecondsPerKm"] as Number
                );
                Application.Storage.setValue("runningPaceTrendSnapshots", updatedSnapshots);
            }

            // How deep the scan went and how much of it landed inside the trend
            // window. #49 dropped the two companions these used to be recorded
            // with - the refresh's wall-clock duration and the iterator's
            // observed ordering. Both were answered conclusively (~11ms an
            // entry, oldest-first over 246 entries, now in RESEARCH.md) and
            // nothing branched on either, so they were measurement scaffolding
            // outliving the question. These two are different: a retained count
            // that moves is how you tell a refresh actually picked up a new run.
            Application.Storage.setValue("runningPaceLastScanScannedCount", scannedCount);
            Application.Storage.setValue("runningPaceLastScanRetainedCount", records.size());

            return true;
        } catch (exception instanceof Lang.Exception) {
            // Same reasoning as the scan's catch above - a transient failure
            // must not overwrite the last good result.
            return false;
        }
    }

    // Start of the trend window: the boundary the history scan filters on.
    // Private again since #49 - it was public only so the chunked foreground
    // caller could compute it exactly the way run() does, and that caller is
    // gone.
    private static function _windowStartFor(now as Time.Moment) as Time.Moment {
        return RunningPaceDayBoundary.startOfDay(now).subtract(new Time.Duration(RunningPaceTrendCalculator.TOTAL_LOOKBACK_DAYS * SECONDS_PER_DAY)) as Time.Moment;
    }

}
