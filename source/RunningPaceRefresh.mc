import Toybox.Application;
import Toybox.Lang;
import Toybox.Time;

// Shared compute-and-persist logic for the weighted pace and trend, backing
// both RunningPaceBackgroundService's recurring temporal event and the
// synchronous foreground-open call from running_pace_trendApp.getInitialView()
// (#36, extended to run on every open by #40, not just first install, so a
// just-completed run is reflected promptly). Runs outside the Glance's
// execution budget (glance-standards.md Data Refresh); RunningPaceGlanceView
// only ever reads the Application.Storage values this writes. On the very
// first successful run (no snapshots stored yet), RunningPaceTrendBackfill
// seeds that history retroactively from the same `records` already loaded
// this call, so the graph screen has real trend data immediately instead of
// only accumulating forward from install day (#29).
class RunningPaceRefresh {

    private static const SECONDS_PER_DAY = 86400;

    // THIS CLASS MUST NEVER BE INVOKED FROM GLANCE SCOPE. It is not
    // (:glance), so it does not exist in the Glance's separate 32kB binary,
    // and calling into it from there aborts the Glance process natively with
    // "Illegal Access (Out of Bounds) / Failed invoking <symbol>" - not a
    // catchable exception. That is exactly what #47 turned out to be: it was
    // called from running_pace_trendApp.onStart(), which the Glance also
    // runs, so the Glance died on every render once the 60s refresh throttle
    // expired. Its callers are now getInitialView() (widget-only) and
    // RunningPaceBackgroundService.onTemporalEvent() (background-only).
    //
    // #40's bisection also concluded that ADDING a method to this class
    // crashed onStart() while changing an existing signature did not. That
    // rule was derived before the scope mechanism above was understood and
    // may simply have been the same symbol-resolution failure in another
    // guise, so it is no longer stated as law - but treat this class as
    // load-bearing and re-test on-device (not just in the simulator, which
    // never reproduced #47) after changing its shape. See RESEARCH.md.

    // Returns whether the run succeeded, so RunningPaceBackgroundService's
    // scheduled path (#40) can retry a failed/throwing attempt; the
    // foreground caller in getInitialView() ignores the return value.
    static function run() as Boolean {
        try {
            var now = Time.now();
            var windowStart = RunningPaceDayBoundary.startOfDay(now).subtract(new Time.Duration(RunningPaceTrendCalculator.TOTAL_LOOKBACK_DAYS * SECONDS_PER_DAY)) as Time.Moment;

            var reader = new RunningActivityHistoryReader();
            var records = reader.readAll(windowStart);
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

            return true;
        } catch (exception instanceof Lang.Exception) {
            // Leave any previously computed Storage values in place rather than
            // overwrite good data with a transient read failure; both callers
            // (the scheduled background tick, which retries on this false
            // return per #40, and the foreground open refresh) keep
            // showing the last successful result until the next chance to run.
            return false;
        }
    }

}
