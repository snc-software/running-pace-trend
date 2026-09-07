import Toybox.Application;
import Toybox.Lang;
import Toybox.Time;

// Shared compute-and-persist logic for the weighted pace and trend, backing
// both RunningPaceBackgroundService's recurring temporal event and the
// synchronous first-launch call from running_pace_trendApp.onStart() (#36).
// Runs outside the Glance's execution budget (glance-standards.md Data
// Refresh); RunningPaceGlanceView only ever reads the Application.Storage
// values this writes. On the very first successful run (no snapshots stored
// yet), RunningPaceTrendBackfill seeds that history retroactively from the
// same `records` already loaded this call, so the graph screen has real
// trend data immediately instead of only accumulating forward from install
// day (#29).
class RunningPaceRefresh {

    private static const SECONDS_PER_DAY = 86400;

    static function run() as Void {
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
            // overwrite good data with a transient read failure; both callers
            // (the daily background tick and the one-time first-launch call)
            // keep showing the last successful result until the next chance to run.
        }
    }

}
