import Toybox.Application;
import Toybox.Background;
import Toybox.Lang;
import Toybox.System;
import Toybox.Time;

// Runs outside the Glance's execution budget (glance-standards.md Data Refresh),
// computing the weighted pace and caching it to Application.Storage for
// RunningPaceGlanceView to read, and recording a historical snapshot via
// RunningPaceTrendHistory for a future longer-term trend view (US-08). On the
// very first successful run (no snapshots stored yet), RunningPaceTrendBackfill
// seeds that history retroactively from the same `records` already loaded
// this tick, so the graph screen has real trend data immediately instead of
// only accumulating forward from install day (#29).
// running-pace-trendApp registers the recurring temporal event with a
// Duration, which the platform repeats automatically, so this delegate does
// not need to re-register itself on every firing.
class RunningPaceBackgroundService extends System.ServiceDelegate {

    private static const SECONDS_PER_DAY = 86400;

    function initialize() {
        System.ServiceDelegate.initialize();
    }

    function onTemporalEvent() as Void {
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
        } catch (exception instanceof Lang.Exception) {
            // Leave any previously computed Storage values in place rather than
            // overwrite good data with a transient read failure; the Glance keeps
            // showing the last successful result until the next scheduled refresh.
        }

        // The Glance reads Application.Storage directly and never consumes
        // onBackgroundData (see RESEARCH.md), so there's nothing to hand back here.
        Background.exit(null);
    }

}
