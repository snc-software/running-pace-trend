import Toybox.Lang;
import Toybox.Time;

enum {
    RUNNING_PACE_TREND_DIRECTION_FASTER,
    RUNNING_PACE_TREND_DIRECTION_SLOWER,
    RUNNING_PACE_TREND_DIRECTION_UNCHANGED
}

// Compares the current rolling-30-day weighted pace against the preceding
// 30-day period, reusing RunningPaceCalculator.calculateForWindow() so the
// weighted-pace formula itself lives in exactly one place (US-03).
class RunningPaceTrendCalculator {

    private static const ROLLING_WINDOW_DAYS = 30;
    private static const SECONDS_PER_DAY = 86400;

    // "now" is injectable so tests can pin both windows instead of depending
    // on wall-clock time.
    static function compare(records as Array<RunningActivityRecord>, now as Time.Moment) as Dictionary {
        var currentWindowStart = now.subtract(new Time.Duration(ROLLING_WINDOW_DAYS * SECONDS_PER_DAY)) as Time.Moment;
        var previousWindowStart = now.subtract(new Time.Duration(2 * ROLLING_WINDOW_DAYS * SECONDS_PER_DAY)) as Time.Moment;

        var current = RunningPaceCalculator.calculateForWindow(records, currentWindowStart, null);
        var previous = RunningPaceCalculator.calculateForWindow(records, previousWindowStart, currentWindowStart);

        var currentHasSufficientData = current["runningPaceHasSufficientData"] as Boolean;
        var previousHasSufficientData = previous["runningPaceHasSufficientData"] as Boolean;
        var hasSufficientData = currentHasSufficientData && previousHasSufficientData;

        var direction = null;
        var deltaSecondsPerKm = null;
        var percentChangeTenths = null;
        if (hasSufficientData) {
            var currentSecondsPerKm = current["runningPaceSecondsPerKm"] as Number;
            var previousSecondsPerKm = previous["runningPaceSecondsPerKm"] as Number;

            if (currentSecondsPerKm < previousSecondsPerKm) {
                direction = RUNNING_PACE_TREND_DIRECTION_FASTER;
            } else if (currentSecondsPerKm > previousSecondsPerKm) {
                direction = RUNNING_PACE_TREND_DIRECTION_SLOWER;
            } else {
                direction = RUNNING_PACE_TREND_DIRECTION_UNCHANGED;
            }

            deltaSecondsPerKm = (currentSecondsPerKm - previousSecondsPerKm).abs();

            // Integer rounding to the nearest tenth of a percent, avoiding Float
            // math per coding-standards.md's Memory and Performance section.
            percentChangeTenths = (deltaSecondsPerKm * 1000 + previousSecondsPerKm / 2) / previousSecondsPerKm;
        }

        return {
            "runningPaceTrendHasSufficientData" => hasSufficientData,
            "runningPaceTrendCurrentSecondsPerKm" => current["runningPaceSecondsPerKm"],
            "runningPaceTrendPreviousSecondsPerKm" => previous["runningPaceSecondsPerKm"],
            "runningPaceTrendDirection" => direction,
            "runningPaceTrendDeltaSecondsPerKm" => deltaSecondsPerKm,
            "runningPaceTrendPercentChangeTenths" => percentChangeTenths
        };
    }

}
