import Toybox.Lang;
import Toybox.Time;

// Reconstructs the rolling-30-day weighted-pace snapshots RunningPaceTrendHistory
// would already hold had the background service been running since before
// `records` was collected (#29) — a fresh install otherwise shows "Not enough
// history yet" on the graph screen regardless of how much real on-watch
// running history exists, since RunningPaceBackgroundService only ever
// appends one snapshot per day going forward from whenever it first runs.
// Bounded to the same lookback RunningActivityHistoryReader.readAll() already
// retains (RunningPaceTrendCalculator.TOTAL_LOOKBACK_DAYS) rather than
// reading further history, per the issue owner's own scoping decision — this
// only ever backfills what `records` already contains, it never triggers an
// additional history read of its own.
class RunningPaceTrendBackfill {

    // Matches RunningPaceCalculator's/RunningPaceTrendCalculator's own
    // duplicated 30-day rolling window constant (this codebase's existing
    // convention rather than new cross-class coupling for a single Number).
    private static const ROLLING_WINDOW_DAYS = 30;
    private static const SECONDS_PER_DAY = 86400;

    // Builds one snapshot per day strictly before `now`'s calendar day, oldest
    // first, for every day whose full trailing 30-day window fits inside
    // `records`' retained lookback. `now`'s own calendar day is deliberately
    // excluded - RunningPaceBackgroundService.onTemporalEvent() already
    // records that day's snapshot itself via its own already-computed
    // `result`, so backfilling it here would just redo that work. A day whose
    // window has no qualifying runs is omitted, mirroring
    // onTemporalEvent()'s own existing rule of only ever storing a snapshot
    // when RunningPaceCalculator reports sufficient data.
    static function buildSnapshots(records as Array<RunningActivityRecord>, now as Time.Moment) as Array<Dictionary> {
        var snapshots = [] as Array<Dictionary>;

        var todayStart = RunningPaceDayBoundary.startOfDay(now);
        var backfillDays = RunningPaceTrendCalculator.TOTAL_LOOKBACK_DAYS - ROLLING_WINDOW_DAYS;

        for (var dayOffset = backfillDays; dayOffset >= 1; dayOffset--) {
            var windowEndExclusive = todayStart.subtract(new Time.Duration(dayOffset * SECONDS_PER_DAY)) as Time.Moment;
            var windowStart = windowEndExclusive.subtract(new Time.Duration(ROLLING_WINDOW_DAYS * SECONDS_PER_DAY)) as Time.Moment;

            var result = RunningPaceCalculator.calculateForWindow(records, windowStart, windowEndExclusive);
            if (result["runningPaceHasSufficientData"] as Boolean) {
                snapshots.add({
                    "date" => windowEndExclusive.value(),
                    "secondsPerKm" => result["runningPaceSecondsPerKm"] as Number
                });
            }
        }

        return snapshots;
    }

}
