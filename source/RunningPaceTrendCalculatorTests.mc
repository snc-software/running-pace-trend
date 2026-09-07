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

    var currentResult = RunningPaceCalculator.calculate(records, now);
    var result = RunningPaceTrendCalculator.compare(records, now, currentResult);

    Test.assertEqualMessage(result["runningPaceTrendHasSufficientData"], true, "both periods have qualifying runs");
    Test.assertEqualMessage(result["runningPaceTrendDirection"], RUNNING_PACE_TREND_DIRECTION_FASTER, "300 s/km current vs 360 s/km previous is faster");
    Test.assertEqualMessage(result["runningPaceTrendDeltaSecondsPerKm"], 60, "delta must be the absolute difference regardless of direction");
    Test.assertEqualMessage(result["runningPaceTrendPercentChangeTenths"], 167, "(60*1000+180)/360 rounds to 167 tenths of a percent");
    return true;
}

(:test)
function identifiesSlowerTrendWhenCurrentPaceIsWorseThanPrevious(logger as Logger) as Boolean {
    var now = new Time.Moment(100000000);
    var records = [
        new RunningActivityRecord(5000, 1800, 100000000, Activity.SPORT_RUNNING),
        new RunningActivityRecord(5000, 1500, 100000000 - (40 * 86400), Activity.SPORT_RUNNING)
    ] as Array<RunningActivityRecord>;

    var currentResult = RunningPaceCalculator.calculate(records, now);
    var result = RunningPaceTrendCalculator.compare(records, now, currentResult);

    Test.assertEqualMessage(result["runningPaceTrendHasSufficientData"], true, "both periods have qualifying runs");
    Test.assertEqualMessage(result["runningPaceTrendDirection"], RUNNING_PACE_TREND_DIRECTION_SLOWER, "360 s/km current vs 300 s/km previous is slower");
    Test.assertEqualMessage(result["runningPaceTrendDeltaSecondsPerKm"], 60, "delta must be the absolute difference regardless of direction");
    Test.assertEqualMessage(result["runningPaceTrendPercentChangeTenths"], 200, "(60*1000+150)/300 rounds to 200 tenths of a percent");
    return true;
}

(:test)
function identifiesUnchangedTrendWhenPacesAreEqual(logger as Logger) as Boolean {
    var now = new Time.Moment(100000000);
    var records = [
        new RunningActivityRecord(5000, 1800, 100000000, Activity.SPORT_RUNNING),
        new RunningActivityRecord(5000, 1800, 100000000 - (40 * 86400), Activity.SPORT_RUNNING)
    ] as Array<RunningActivityRecord>;

    var currentResult = RunningPaceCalculator.calculate(records, now);
    var result = RunningPaceTrendCalculator.compare(records, now, currentResult);

    Test.assertEqualMessage(result["runningPaceTrendHasSufficientData"], true, "both periods have qualifying runs");
    Test.assertEqualMessage(result["runningPaceTrendDirection"], RUNNING_PACE_TREND_DIRECTION_UNCHANGED, "equal weighted pace in both periods is unchanged");
    Test.assertEqualMessage(result["runningPaceTrendDeltaSecondsPerKm"], 0, "equal weighted pace in both periods must report a zero delta");
    Test.assertEqualMessage(result["runningPaceTrendPercentChangeTenths"], 0, "equal weighted pace in both periods must report a zero percent change");
    return true;
}

(:test)
function reportsInsufficientDataWhenCurrentPeriodHasNoQualifyingRuns(logger as Logger) as Boolean {
    var now = new Time.Moment(100000000);
    var records = [
        new RunningActivityRecord(5000, 1800, 100000000 - (40 * 86400), Activity.SPORT_RUNNING)
    ] as Array<RunningActivityRecord>;

    var currentResult = RunningPaceCalculator.calculate(records, now);
    var result = RunningPaceTrendCalculator.compare(records, now, currentResult);

    Test.assertEqualMessage(result["runningPaceTrendHasSufficientData"], false, "current period has no qualifying runs");
    Test.assertMessage(result["runningPaceTrendCurrentSecondsPerKm"] == null, "current pace must be null without current-period data");
    Test.assertMessage(result["runningPaceTrendPreviousSecondsPerKm"] != null, "previous pace should still be populated");
    Test.assertMessage(result["runningPaceTrendDirection"] == null, "direction must be null when data is insufficient");
    Test.assertMessage(result["runningPaceTrendDeltaSecondsPerKm"] == null, "delta must be null when data is insufficient");
    Test.assertMessage(result["runningPaceTrendPercentChangeTenths"] == null, "percent change must be null when data is insufficient");
    return true;
}

(:test)
function reportsInsufficientDataWhenPreviousPeriodHasNoQualifyingRuns(logger as Logger) as Boolean {
    var now = new Time.Moment(100000000);
    var records = [
        new RunningActivityRecord(5000, 1800, 100000000, Activity.SPORT_RUNNING)
    ] as Array<RunningActivityRecord>;

    var currentResult = RunningPaceCalculator.calculate(records, now);
    var result = RunningPaceTrendCalculator.compare(records, now, currentResult);

    Test.assertEqualMessage(result["runningPaceTrendHasSufficientData"], false, "previous period has no qualifying runs");
    Test.assertMessage(result["runningPaceTrendPreviousSecondsPerKm"] == null, "previous pace must be null without previous-period data");
    Test.assertMessage(result["runningPaceTrendCurrentSecondsPerKm"] != null, "current pace should still be populated");
    Test.assertMessage(result["runningPaceTrendDirection"] == null, "direction must be null when data is insufficient");
    Test.assertMessage(result["runningPaceTrendDeltaSecondsPerKm"] == null, "delta must be null when data is insufficient");
    Test.assertMessage(result["runningPaceTrendPercentChangeTenths"] == null, "percent change must be null when data is insufficient");
    return true;
}

(:test)
function reportsInsufficientDataWhenNeitherPeriodHasQualifyingRuns(logger as Logger) as Boolean {
    var now = new Time.Moment(100000000);
    var records = [] as Array<RunningActivityRecord>;

    var currentResult = RunningPaceCalculator.calculate(records, now);
    var result = RunningPaceTrendCalculator.compare(records, now, currentResult);

    Test.assertEqualMessage(result["runningPaceTrendHasSufficientData"], false, "no records must yield insufficient data, not an exception");
    Test.assertMessage(result["runningPaceTrendCurrentSecondsPerKm"] == null, "current pace must be null");
    Test.assertMessage(result["runningPaceTrendPreviousSecondsPerKm"] == null, "previous pace must be null");
    Test.assertMessage(result["runningPaceTrendDirection"] == null, "direction must be null");
    Test.assertMessage(result["runningPaceTrendDeltaSecondsPerKm"] == null, "delta must be null");
    Test.assertMessage(result["runningPaceTrendPercentChangeTenths"] == null, "percent change must be null");
    return true;
}

(:test)
function calculatesPercentChangeMatchingIssueExample(logger as Logger) as Boolean {
    var now = new Time.Moment(100000000);
    var records = [
        new RunningActivityRecord(1000, 462, 100000000, Activity.SPORT_RUNNING),
        new RunningActivityRecord(1000, 473, 100000000 - (40 * 86400), Activity.SPORT_RUNNING)
    ] as Array<RunningActivityRecord>;

    var currentResult = RunningPaceCalculator.calculate(records, now);
    var result = RunningPaceTrendCalculator.compare(records, now, currentResult);

    Test.assertEqualMessage(result["runningPaceTrendDeltaSecondsPerKm"], 11, "462 vs 473 s/km delta must be 11");
    Test.assertEqualMessage(result["runningPaceTrendPercentChangeTenths"], 23, "462 vs 473 s/km must match the issue's worked example of 2.3%");
    return true;
}

(:test)
function excludesRunsOlderThanSixtyDays(logger as Logger) as Boolean {
    var now = new Time.Moment(100000000);
    var records = [
        new RunningActivityRecord(5000, 1800, 100000000 - (100 * 86400), Activity.SPORT_RUNNING)
    ] as Array<RunningActivityRecord>;

    var currentResult = RunningPaceCalculator.calculate(records, now);
    var result = RunningPaceTrendCalculator.compare(records, now, currentResult);

    Test.assertEqualMessage(result["runningPaceTrendHasSufficientData"], false, "a run older than 60 days must contribute to neither period");
    Test.assertMessage(result["runningPaceTrendCurrentSecondsPerKm"] == null, "current pace must be null");
    Test.assertMessage(result["runningPaceTrendPreviousSecondsPerKm"] == null, "previous pace must be null");
    return true;
}

(:test)
function assignsBoundaryRunToCurrentPeriodNotPrevious(logger as Logger) as Boolean {
    var now = new Time.Moment(100000000);
    var todayStart = RunningPaceDayBoundary.startOfDay(now);
    var currentWindowStart = todayStart.subtract(new Time.Duration(30 * 86400));
    var records = [
        new RunningActivityRecord(5000, 1800, currentWindowStart.value(), Activity.SPORT_RUNNING)
    ] as Array<RunningActivityRecord>;

    var currentResult = RunningPaceCalculator.calculate(records, now);
    var result = RunningPaceTrendCalculator.compare(records, now, currentResult);

    Test.assertMessage(result["runningPaceTrendCurrentSecondsPerKm"] != null, "a run exactly at the current period's midnight-anchored start boundary must count toward the current period");
    Test.assertMessage(result["runningPaceTrendPreviousSecondsPerKm"] == null, "the same boundary run must not also be counted in the previous period");
    return true;
}

(:test)
function includesRunAtSixtyDayBoundaryInPreviousPeriod(logger as Logger) as Boolean {
    var now = new Time.Moment(100000000);
    var todayStart = RunningPaceDayBoundary.startOfDay(now);
    var previousWindowStart = todayStart.subtract(new Time.Duration(60 * 86400));
    var records = [
        new RunningActivityRecord(5000, 1800, previousWindowStart.value(), Activity.SPORT_RUNNING)
    ] as Array<RunningActivityRecord>;

    var currentResult = RunningPaceCalculator.calculate(records, now);
    var result = RunningPaceTrendCalculator.compare(records, now, currentResult);

    Test.assertMessage(result["runningPaceTrendPreviousSecondsPerKm"] != null, "a run exactly at the previous period's midnight-anchored start boundary must count toward the previous period");
    Test.assertMessage(result["runningPaceTrendCurrentSecondsPerKm"] == null, "the boundary run must not be counted in the current period");
    return true;
}

(:test)
function excludesRunJustOutsideSixtyDayBoundary(logger as Logger) as Boolean {
    var now = new Time.Moment(100000000);
    var todayStart = RunningPaceDayBoundary.startOfDay(now);
    var previousWindowStart = todayStart.subtract(new Time.Duration(60 * 86400));
    var records = [
        new RunningActivityRecord(5000, 1800, previousWindowStart.value() - 1, Activity.SPORT_RUNNING)
    ] as Array<RunningActivityRecord>;

    var currentResult = RunningPaceCalculator.calculate(records, now);
    var result = RunningPaceTrendCalculator.compare(records, now, currentResult);

    Test.assertEqualMessage(result["runningPaceTrendHasSufficientData"], false, "a run one second outside the midnight-anchored 60-day boundary must not count in either period");
    return true;
}

(:test)
function excludesNonRunningActivitiesFromBothPeriods(logger as Logger) as Boolean {
    var now = new Time.Moment(100000000);
    var records = [
        new RunningActivityRecord(5000, 1800, 100000000, Activity.SPORT_CYCLING),
        new RunningActivityRecord(5000, 1800, 100000000 - (40 * 86400), Activity.SPORT_CYCLING)
    ] as Array<RunningActivityRecord>;

    var currentResult = RunningPaceCalculator.calculate(records, now);
    var result = RunningPaceTrendCalculator.compare(records, now, currentResult);

    Test.assertEqualMessage(result["runningPaceTrendHasSufficientData"], false, "non-running activities must not contribute to either period");
    return true;
}

(:test)
function compareUsesProvidedCurrentResultInsteadOfRecomputingIt(logger as Logger) as Boolean {
    var now = new Time.Moment(100000000);
    var records = [
        new RunningActivityRecord(5000, 1500, 100000000, Activity.SPORT_RUNNING),
        new RunningActivityRecord(5000, 1800, 100000000 - (40 * 86400), Activity.SPORT_RUNNING)
    ] as Array<RunningActivityRecord>;

    // `records` would independently calculate to a 300 s/km, sufficient
    // current period. Deliberately pass a fabricated currentResult claiming
    // a different pace and insufficient data instead, proving compare()
    // trusts the caller-supplied result rather than reprocessing `records`
    // itself for the current window (US-11 / #16).
    var fabricatedCurrentResult = {
        "runningPaceHasSufficientData" => false,
        "runningPaceSecondsPerKm" => null,
        "runningPaceLastComputedAt" => now.value(),
        "runningPaceTotalDistanceMeters" => 0,
        "runningPaceQualifyingActivityCount" => 0
    };

    var result = RunningPaceTrendCalculator.compare(records, now, fabricatedCurrentResult);

    Test.assertEqualMessage(result["runningPaceTrendHasSufficientData"], false, "compare() must treat the current period as insufficient because the fabricated result said so, not because it recomputed 300 s/km itself");
    Test.assertMessage(result["runningPaceTrendCurrentSecondsPerKm"] == null, "the fabricated null current pace must be reflected, not recalculated from records");
    return true;
}
