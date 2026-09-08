import Toybox.Lang;
import Toybox.Test;

(:test)
function formatsPercentChangeMatchingIssueExample(logger as Logger) as Boolean {
    Test.assertEqualMessage(RunningPaceTrendFormatter.formatPercent(23), "2.3%", "23 tenths of a percent must format as 2.3%, matching the issue's example");
    return true;
}

(:test)
function formatsZeroPercentChange(logger as Logger) as Boolean {
    Test.assertEqualMessage(RunningPaceTrendFormatter.formatPercent(0), "0.0%", "zero tenths of a percent must format as 0.0%");
    return true;
}

(:test)
function formatsDoubleDigitWholePercent(logger as Logger) as Boolean {
    Test.assertEqualMessage(RunningPaceTrendFormatter.formatPercent(200), "20.0%", "200 tenths of a percent must format as 20.0%");
    return true;
}

(:test)
function combinesDeltaAndPercentOntoOneLine(logger as Logger) as Boolean {
    Test.assertEqualMessage(RunningPaceTrendFormatter.combineDeltaAndPercent("16 sec/km faster", "3.4%"), "16 sec/km faster (3.4%)", "the percent must be wrapped in parentheses onto the same line as the delta text (#37)");
    return true;
}
