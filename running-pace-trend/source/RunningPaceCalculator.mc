import Toybox.Activity;
import Toybox.Lang;
import Toybox.Time;

// Pure calculation logic, decoupled from the Garmin activity-history API and from
// Application.Storage, so it can be unit tested without a device (coding-standards.md
// Testing section). Product Rule: pace is total duration / total distance across
// qualifying runs (a distance-weighted average), not an average of per-run paces.
class RunningPaceCalculator {

    private static const ROLLING_WINDOW_DAYS = 30;
    private static const SECONDS_PER_DAY = 86400;
    private static const METERS_PER_KM = 1000;

    // "now" is injectable so tests can pin the rolling window instead of depending
    // on wall-clock time.
    static function calculate(records as Array<RunningActivityRecord>, now as Time.Moment) as Dictionary {
        var windowStart = now.subtract(new Time.Duration(ROLLING_WINDOW_DAYS * SECONDS_PER_DAY)) as Time.Moment;
        var result = calculateForWindow(records, windowStart, null);

        return {
            "runningPaceHasSufficientData" => result["runningPaceHasSufficientData"],
            "runningPaceSecondsPerKm" => result["runningPaceSecondsPerKm"],
            "runningPaceLastComputedAt" => now.value(),
            "runningPaceTotalDistanceMeters" => result["runningPaceTotalDistanceMeters"],
            "runningPaceQualifyingActivityCount" => result["runningPaceQualifyingActivityCount"]
        };
    }

    // Shared aggregation logic behind `calculate()` and RunningPaceTrendCalculator,
    // so the distance-weighted pace formula lives in exactly one place. A null
    // `windowEndExclusive` means "no upper bound" (matches `calculate()`'s own
    // "up to now" behaviour).
    static function calculateForWindow(records as Array<RunningActivityRecord>, windowStart as Time.Moment, windowEndExclusive as Time.Moment?) as Dictionary {
        var totalDistanceMeters = 0;
        var totalDurationSeconds = 0;
        var qualifyingActivityCount = 0;

        for (var i = 0; i < records.size(); i++) {
            var record = records[i];

            if (record.sport != Activity.SPORT_RUNNING) {
                continue;
            }

            var distanceMeters = record.distanceMeters;
            var durationSeconds = record.durationSeconds;
            var startTimeEpoch = record.startTimeEpoch;

            if (distanceMeters == null || durationSeconds == null || startTimeEpoch == null) {
                continue;
            }
            if (distanceMeters <= 0) {
                continue;
            }

            var startMoment = new Time.Moment(startTimeEpoch);
            if (startMoment.lessThan(windowStart)) {
                continue;
            }
            if (windowEndExclusive != null && !startMoment.lessThan(windowEndExclusive)) {
                continue;
            }

            totalDistanceMeters += distanceMeters;
            totalDurationSeconds += durationSeconds;
            qualifyingActivityCount += 1;
        }

        if (totalDistanceMeters <= 0) {
            return {
                "runningPaceHasSufficientData" => false,
                "runningPaceSecondsPerKm" => null,
                "runningPaceTotalDistanceMeters" => totalDistanceMeters,
                "runningPaceQualifyingActivityCount" => qualifyingActivityCount
            };
        }

        // Integer rounding to the nearest whole second/km, avoiding Float math
        // per coding-standards.md's Memory and Performance section.
        var secondsPerKm = (totalDurationSeconds * METERS_PER_KM + totalDistanceMeters / 2) / totalDistanceMeters;

        return {
            "runningPaceHasSufficientData" => true,
            "runningPaceSecondsPerKm" => secondsPerKm,
            "runningPaceTotalDistanceMeters" => totalDistanceMeters,
            "runningPaceQualifyingActivityCount" => qualifyingActivityCount
        };
    }

}
