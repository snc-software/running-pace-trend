import Toybox.Application;
import Toybox.Lang;
import Toybox.Time;

// Shared compute-and-persist logic for the weighted pace and trend, backing
// both RunningPaceBackgroundService's recurring temporal event and the
// synchronous foreground-open call from running_pace_trendApp.onStart()
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

    // TEMPORARY SIMULATOR SEED CONSTANTS — REVERT BEFORE MERGE (see run()).
    private static const SEED_SNAPSHOT_DAYS = 60;
    private static const SEED_START_SECONDS_PER_KM = 485;
    private static const SEED_CURRENT_SECONDS_PER_KM = 464;
    private static const SEED_PREVIOUS_SECONDS_PER_KM = 478;

    // No new methods may be added to this class. It is reached from both
    // running_pace_trendApp.onStart() (foreground) and
    // RunningPaceBackgroundService.onTemporalEvent() (background), and this
    // app builds with "the 'Background' permission was enabled but no source
    // code was annotated. The entire application will be loaded as a
    // background process". Adding a method here shifts the layout the two
    // scopes disagree about and crashes onStart() at runtime with "Illegal
    // Access (Out of Bounds) / Failed invoking <symbol>" - confirmed in the
    // simulator (see RESEARCH.md). Changing an existing method's signature,
    // as run() does below, is safe; adding one is not. New shared helpers
    // belong in a class reached from a single entry point, the way
    // RunningPaceBackgroundSchedule is.

    // Returns whether the run succeeded, so RunningPaceBackgroundService's
    // scheduled path (#40) can retry a failed/throwing attempt; the
    // foreground caller in onStart() ignores the return value.
    static function run() as Boolean {
        // ================= TEMPORARY SIMULATOR SEED — REVERT BEFORE MERGE =================
        // The simulator has no way to supply UserProfile.getUserActivityHistory()
        // with real activities, so the real read below always yields "no data" and
        // the trend screens can't be reviewed. This block hard-codes an
        // Application.Storage state modelled on running-data.csv (a ~60-day
        // improving trend, roughly 8:05/km down to 7:44/km) so the graph and
        // Glance render fully. Delete this block and uncomment the real body to
        // restore normal behaviour.
        //
        // Inlined deliberately rather than extracted into a helper method: no new
        // method may be added to this class (see the note above and RESEARCH.md).
        var seedNow = Time.now();
        var seedTodayStart = RunningPaceDayBoundary.startOfDay(seedNow);

        var seedSnapshots = [] as Array<Dictionary>;
        for (var i = SEED_SNAPSHOT_DAYS - 1; i >= 0; i--) {
            var seedDay = seedTodayStart.subtract(new Time.Duration(i * SECONDS_PER_DAY)) as Time.Moment;
            var elapsedDays = SEED_SNAPSHOT_DAYS - 1 - i;
            var seedPace = SEED_START_SECONDS_PER_KM - (elapsedDays * (SEED_START_SECONDS_PER_KM - SEED_CURRENT_SECONDS_PER_KM)) / (SEED_SNAPSHOT_DAYS - 1);
            // A little week-to-week wobble so the graph isn't a straight line.
            if (i % 3 == 0) {
                seedPace += 4;
            } else if (i % 5 == 0) {
                seedPace -= 3;
            }
            seedSnapshots.add({
                "date" => seedDay.value(),
                "secondsPerKm" => seedPace
            });
        }

        Application.Storage.setValue("runningPaceHasSufficientData", true);
        Application.Storage.setValue("runningPaceSecondsPerKm", SEED_CURRENT_SECONDS_PER_KM);
        Application.Storage.setValue("runningPaceLastComputedAt", seedNow.value());
        Application.Storage.setValue("runningPaceTotalDistanceMeters", 152400);
        Application.Storage.setValue("runningPaceQualifyingActivityCount", 18);

        Application.Storage.setValue("runningPaceTrendHasSufficientData", true);
        Application.Storage.setValue("runningPaceTrendDirection", RUNNING_PACE_TREND_DIRECTION_FASTER);
        Application.Storage.setValue("runningPaceTrendDeltaSecondsPerKm", SEED_CURRENT_SECONDS_PER_KM - SEED_PREVIOUS_SECONDS_PER_KM);
        Application.Storage.setValue("runningPaceTrendCurrentSecondsPerKm", SEED_CURRENT_SECONDS_PER_KM);
        Application.Storage.setValue("runningPaceTrendPreviousSecondsPerKm", SEED_PREVIOUS_SECONDS_PER_KM);
        Application.Storage.setValue("runningPaceTrendPercentChangeTenths", -29);
        Application.Storage.setValue("runningPaceTrendPreviousWindowStartEpoch", seedTodayStart.subtract(new Time.Duration(RunningPaceTrendCalculator.TOTAL_LOOKBACK_DAYS * SECONDS_PER_DAY)).value());
        Application.Storage.setValue("runningPaceTrendCurrentWindowStartEpoch", seedTodayStart.subtract(new Time.Duration(30 * SECONDS_PER_DAY)).value());
        Application.Storage.setValue("runningPaceTrendCurrentWindowEndEpoch", seedNow.value());
        Application.Storage.setValue("runningPaceTrendSnapshots", seedSnapshots);

        return true;
        // =============== END TEMPORARY SIMULATOR SEED — REVERT BEFORE MERGE ===============

        /* REAL BODY — restore this (and delete the seed block above) before merge:
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
            // return per #40, and the foreground onStart() refresh) keep
            // showing the last successful result until the next chance to run.
            return false;
        }
        */
    }

}
