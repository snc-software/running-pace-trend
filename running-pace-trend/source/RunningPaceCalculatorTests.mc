import Toybox.Activity;
import Toybox.Lang;
import Toybox.Test;
import Toybox.Time;

(:test)
function calculatesWeightedPaceForSingleQualifyingRun(logger as Logger) as Boolean {
    var now = new Time.Moment(100000000);
    var records = [
        new RunningActivityRecord(5000, 1800, 100000000, Activity.SPORT_RUNNING)
    ] as Array<RunningActivityRecord>;

    var result = RunningPaceCalculator.calculate(records, now);

    Test.assertEqualMessage(result["runningPaceHasSufficientData"], true, "expected sufficient data for one qualifying run");
    Test.assertEqualMessage(result["runningPaceSecondsPerKm"], 360, "5000m in 1800s should be 360 seconds/km");
    return true;
}

(:test)
function calculatesWeightedPaceAcrossMultipleQualifyingRuns(logger as Logger) as Boolean {
    var now = new Time.Moment(100000000);
    var records = [
        new RunningActivityRecord(5000, 1500, 100000000, Activity.SPORT_RUNNING),
        new RunningActivityRecord(10000, 3600, 100000000, Activity.SPORT_RUNNING)
    ] as Array<RunningActivityRecord>;

    var result = RunningPaceCalculator.calculate(records, now);

    // total duration / total distance = 5100 / 15000 = 340 s/km, not the simple
    // average of the two individual paces (300 and 360), proving the weighting.
    Test.assertEqualMessage(result["runningPaceSecondsPerKm"], 340, "pace must be distance-weighted, not averaged per-run");
    return true;
}

(:test)
function excludesNonRunningActivities(logger as Logger) as Boolean {
    var now = new Time.Moment(100000000);
    var records = [
        new RunningActivityRecord(5000, 1800, 100000000, Activity.SPORT_RUNNING),
        new RunningActivityRecord(50000, 3600, 100000000, Activity.SPORT_CYCLING)
    ] as Array<RunningActivityRecord>;

    var result = RunningPaceCalculator.calculate(records, now);

    Test.assertEqualMessage(result["runningPaceSecondsPerKm"], 360, "cycling activity must not contribute to the pace");
    return true;
}

(:test)
function excludesActivitiesOutsideRollingThirtyDayWindow(logger as Logger) as Boolean {
    var now = new Time.Moment(100000000);
    var thirtyDaysInSeconds = 30 * 86400;
    var records = [
        new RunningActivityRecord(5000, 1800, 100000000 - thirtyDaysInSeconds - 1, Activity.SPORT_RUNNING)
    ] as Array<RunningActivityRecord>;

    var result = RunningPaceCalculator.calculate(records, now);

    Test.assertEqualMessage(result["runningPaceHasSufficientData"], false, "a run older than 30 days must not contribute");
    return true;
}

(:test)
function includesActivityAtThirtyDayBoundary(logger as Logger) as Boolean {
    var now = new Time.Moment(100000000);
    var thirtyDaysInSeconds = 30 * 86400;
    var records = [
        new RunningActivityRecord(5000, 1800, 100000000 - thirtyDaysInSeconds, Activity.SPORT_RUNNING)
    ] as Array<RunningActivityRecord>;

    var result = RunningPaceCalculator.calculate(records, now);

    Test.assertEqualMessage(result["runningPaceHasSufficientData"], true, "a run exactly at the 30-day boundary must count");
    return true;
}

(:test)
function excludesActivityJustOutsideThirtyDayBoundary(logger as Logger) as Boolean {
    var now = new Time.Moment(100000000);
    var thirtyDaysInSeconds = 30 * 86400;
    var records = [
        new RunningActivityRecord(5000, 1800, 100000000 - thirtyDaysInSeconds - 1, Activity.SPORT_RUNNING)
    ] as Array<RunningActivityRecord>;

    var result = RunningPaceCalculator.calculate(records, now);

    Test.assertEqualMessage(result["runningPaceHasSufficientData"], false, "a run one second outside the 30-day boundary must not count");
    return true;
}

(:test)
function returnsInsufficientDataWhenNoQualifyingRuns(logger as Logger) as Boolean {
    var now = new Time.Moment(100000000);
    var records = [] as Array<RunningActivityRecord>;

    var result = RunningPaceCalculator.calculate(records, now);

    Test.assertEqualMessage(result["runningPaceHasSufficientData"], false, "no records must yield insufficient data, not an exception");
    Test.assertMessage(result["runningPaceSecondsPerKm"] == null, "pace must be null when there is insufficient data");
    return true;
}

(:test)
function handlesZeroDistanceActivitySafely(logger as Logger) as Boolean {
    var now = new Time.Moment(100000000);
    var records = [
        new RunningActivityRecord(0, 1800, 100000000, Activity.SPORT_RUNNING)
    ] as Array<RunningActivityRecord>;

    var result = RunningPaceCalculator.calculate(records, now);

    Test.assertEqualMessage(result["runningPaceHasSufficientData"], false, "a zero-distance run must not be divided by zero or counted as sufficient");
    return true;
}

(:test)
function handlesRecordsWithNullFieldsSafely(logger as Logger) as Boolean {
    var now = new Time.Moment(100000000);
    var records = [
        new RunningActivityRecord(null, 1800, 100000000, Activity.SPORT_RUNNING),
        new RunningActivityRecord(5000, null, 100000000, Activity.SPORT_RUNNING),
        new RunningActivityRecord(5000, 1800, null, Activity.SPORT_RUNNING),
        new RunningActivityRecord(5000, 1800, 100000000, null)
    ] as Array<RunningActivityRecord>;

    var result = RunningPaceCalculator.calculate(records, now);

    Test.assertEqualMessage(result["runningPaceHasSufficientData"], false, "records with any null field must be skipped rather than crash");
    return true;
}
