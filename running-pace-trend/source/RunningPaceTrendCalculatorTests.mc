import Toybox.Activity;
import Toybox.Lang;
import Toybox.Test;
import Toybox.Time;

(:test)
function identifiesFasterTrendWhenCurrentPaceIsBetterThanPrevious(logger as Logger) as Boolean {
    var now = new Time.Moment(100000000);
    var records = [
        new RunningActivityRecord(5000, 1500, 100000000, Activity.SPORT_RUNNING),
        new RunningActivityRecord(5000, 1800, 100000000 - (40 * 86400), Activity.SPORT_RUNNING)
    ] as Array<RunningActivityRecord>;

    var result = RunningPaceTrendCalculator.compare(records, now);

    Test.assertEqualMessage(result["runningPaceTrendHasSufficientData"], true, "both periods have qualifying runs");
    Test.assertEqualMessage(result["runningPaceTrendDirection"], RUNNING_PACE_TREND_DIRECTION_FASTER, "300 s/km current vs 360 s/km previous is faster");
    return true;
}

(:test)
function identifiesSlowerTrendWhenCurrentPaceIsWorseThanPrevious(logger as Logger) as Boolean {
    var now = new Time.Moment(100000000);
    var records = [
        new RunningActivityRecord(5000, 1800, 100000000, Activity.SPORT_RUNNING),
        new RunningActivityRecord(5000, 1500, 100000000 - (40 * 86400), Activity.SPORT_RUNNING)
    ] as Array<RunningActivityRecord>;

    var result = RunningPaceTrendCalculator.compare(records, now);

    Test.assertEqualMessage(result["runningPaceTrendHasSufficientData"], true, "both periods have qualifying runs");
    Test.assertEqualMessage(result["runningPaceTrendDirection"], RUNNING_PACE_TREND_DIRECTION_SLOWER, "360 s/km current vs 300 s/km previous is slower");
    return true;
}

(:test)
function identifiesUnchangedTrendWhenPacesAreEqual(logger as Logger) as Boolean {
    var now = new Time.Moment(100000000);
    var records = [
        new RunningActivityRecord(5000, 1800, 100000000, Activity.SPORT_RUNNING),
        new RunningActivityRecord(5000, 1800, 100000000 - (40 * 86400), Activity.SPORT_RUNNING)
    ] as Array<RunningActivityRecord>;

    var result = RunningPaceTrendCalculator.compare(records, now);

    Test.assertEqualMessage(result["runningPaceTrendHasSufficientData"], true, "both periods have qualifying runs");
    Test.assertEqualMessage(result["runningPaceTrendDirection"], RUNNING_PACE_TREND_DIRECTION_UNCHANGED, "equal weighted pace in both periods is unchanged");
    return true;
}

(:test)
function reportsInsufficientDataWhenCurrentPeriodHasNoQualifyingRuns(logger as Logger) as Boolean {
    var now = new Time.Moment(100000000);
    var records = [
        new RunningActivityRecord(5000, 1800, 100000000 - (40 * 86400), Activity.SPORT_RUNNING)
    ] as Array<RunningActivityRecord>;

    var result = RunningPaceTrendCalculator.compare(records, now);

    Test.assertEqualMessage(result["runningPaceTrendHasSufficientData"], false, "current period has no qualifying runs");
    Test.assertMessage(result["runningPaceTrendCurrentSecondsPerKm"] == null, "current pace must be null without current-period data");
    Test.assertMessage(result["runningPaceTrendPreviousSecondsPerKm"] != null, "previous pace should still be populated");
    Test.assertMessage(result["runningPaceTrendDirection"] == null, "direction must be null when data is insufficient");
    return true;
}

(:test)
function reportsInsufficientDataWhenPreviousPeriodHasNoQualifyingRuns(logger as Logger) as Boolean {
    var now = new Time.Moment(100000000);
    var records = [
        new RunningActivityRecord(5000, 1800, 100000000, Activity.SPORT_RUNNING)
    ] as Array<RunningActivityRecord>;

    var result = RunningPaceTrendCalculator.compare(records, now);

    Test.assertEqualMessage(result["runningPaceTrendHasSufficientData"], false, "previous period has no qualifying runs");
    Test.assertMessage(result["runningPaceTrendPreviousSecondsPerKm"] == null, "previous pace must be null without previous-period data");
    Test.assertMessage(result["runningPaceTrendCurrentSecondsPerKm"] != null, "current pace should still be populated");
    Test.assertMessage(result["runningPaceTrendDirection"] == null, "direction must be null when data is insufficient");
    return true;
}

(:test)
function reportsInsufficientDataWhenNeitherPeriodHasQualifyingRuns(logger as Logger) as Boolean {
    var now = new Time.Moment(100000000);
    var records = [] as Array<RunningActivityRecord>;

    var result = RunningPaceTrendCalculator.compare(records, now);

    Test.assertEqualMessage(result["runningPaceTrendHasSufficientData"], false, "no records must yield insufficient data, not an exception");
    Test.assertMessage(result["runningPaceTrendCurrentSecondsPerKm"] == null, "current pace must be null");
    Test.assertMessage(result["runningPaceTrendPreviousSecondsPerKm"] == null, "previous pace must be null");
    Test.assertMessage(result["runningPaceTrendDirection"] == null, "direction must be null");
    return true;
}

(:test)
function excludesRunsOlderThanSixtyDays(logger as Logger) as Boolean {
    var now = new Time.Moment(100000000);
    var records = [
        new RunningActivityRecord(5000, 1800, 100000000 - (100 * 86400), Activity.SPORT_RUNNING)
    ] as Array<RunningActivityRecord>;

    var result = RunningPaceTrendCalculator.compare(records, now);

    Test.assertEqualMessage(result["runningPaceTrendHasSufficientData"], false, "a run older than 60 days must contribute to neither period");
    Test.assertMessage(result["runningPaceTrendCurrentSecondsPerKm"] == null, "current pace must be null");
    Test.assertMessage(result["runningPaceTrendPreviousSecondsPerKm"] == null, "previous pace must be null");
    return true;
}

(:test)
function assignsBoundaryRunToCurrentPeriodNotPrevious(logger as Logger) as Boolean {
    var now = new Time.Moment(100000000);
    var thirtyDaysInSeconds = 30 * 86400;
    var records = [
        new RunningActivityRecord(5000, 1800, 100000000 - thirtyDaysInSeconds, Activity.SPORT_RUNNING)
    ] as Array<RunningActivityRecord>;

    var result = RunningPaceTrendCalculator.compare(records, now);

    Test.assertMessage(result["runningPaceTrendCurrentSecondsPerKm"] != null, "a run exactly at the current period's start boundary must count toward the current period");
    Test.assertMessage(result["runningPaceTrendPreviousSecondsPerKm"] == null, "the same boundary run must not also be counted in the previous period");
    return true;
}

(:test)
function includesRunAtSixtyDayBoundaryInPreviousPeriod(logger as Logger) as Boolean {
    var now = new Time.Moment(100000000);
    var sixtyDaysInSeconds = 60 * 86400;
    var records = [
        new RunningActivityRecord(5000, 1800, 100000000 - sixtyDaysInSeconds, Activity.SPORT_RUNNING)
    ] as Array<RunningActivityRecord>;

    var result = RunningPaceTrendCalculator.compare(records, now);

    Test.assertMessage(result["runningPaceTrendPreviousSecondsPerKm"] != null, "a run exactly at the previous period's start boundary must count toward the previous period");
    Test.assertMessage(result["runningPaceTrendCurrentSecondsPerKm"] == null, "the boundary run must not be counted in the current period");
    return true;
}

(:test)
function excludesRunJustOutsideSixtyDayBoundary(logger as Logger) as Boolean {
    var now = new Time.Moment(100000000);
    var sixtyDaysInSeconds = 60 * 86400;
    var records = [
        new RunningActivityRecord(5000, 1800, 100000000 - sixtyDaysInSeconds - 1, Activity.SPORT_RUNNING)
    ] as Array<RunningActivityRecord>;

    var result = RunningPaceTrendCalculator.compare(records, now);

    Test.assertEqualMessage(result["runningPaceTrendHasSufficientData"], false, "a run one second outside the 60-day boundary must not count in either period");
    return true;
}

(:test)
function excludesNonRunningActivitiesFromBothPeriods(logger as Logger) as Boolean {
    var now = new Time.Moment(100000000);
    var records = [
        new RunningActivityRecord(5000, 1800, 100000000, Activity.SPORT_CYCLING),
        new RunningActivityRecord(5000, 1800, 100000000 - (40 * 86400), Activity.SPORT_CYCLING)
    ] as Array<RunningActivityRecord>;

    var result = RunningPaceTrendCalculator.compare(records, now);

    Test.assertEqualMessage(result["runningPaceTrendHasSufficientData"], false, "non-running activities must not contribute to either period");
    return true;
}
