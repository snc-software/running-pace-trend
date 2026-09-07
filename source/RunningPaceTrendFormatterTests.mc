import Toybox.Lang;
import Toybox.Test;

(:test)
function formatsFasterDirectionWithUpArrow(logger as Logger) as Boolean {
    Test.assertEqualMessage(RunningPaceTrendFormatter.format(RUNNING_PACE_TREND_DIRECTION_FASTER, 11), "^ 11", "a positive (faster) delta must use an up arrow");
    return true;
}

(:test)
function formatsSlowerDirectionWithDownArrow(logger as Logger) as Boolean {
    Test.assertEqualMessage(RunningPaceTrendFormatter.format(RUNNING_PACE_TREND_DIRECTION_SLOWER, 11), "v 11", "a negative (slower) delta must use a down arrow");
    return true;
}

(:test)
function formatsUnchangedDirectionWithNeutralArrowAndZero(logger as Logger) as Boolean {
    Test.assertEqualMessage(RunningPaceTrendFormatter.format(RUNNING_PACE_TREND_DIRECTION_UNCHANGED, 0), "-> 0", "a zero delta must use a neutral arrow");
    return true;
}

(:test)
function arrowForFasterDirectionIsUp(logger as Logger) as Boolean {
    Test.assertEqualMessage(RunningPaceTrendFormatter.arrowFor(RUNNING_PACE_TREND_DIRECTION_FASTER), "^", "a faster direction must return the up arrow alone");
    return true;
}

(:test)
function arrowForSlowerDirectionIsDown(logger as Logger) as Boolean {
    Test.assertEqualMessage(RunningPaceTrendFormatter.arrowFor(RUNNING_PACE_TREND_DIRECTION_SLOWER), "v", "a slower direction must return the down arrow alone");
    return true;
}

(:test)
function arrowForUnchangedDirectionIsNeutral(logger as Logger) as Boolean {
    Test.assertEqualMessage(RunningPaceTrendFormatter.arrowFor(RUNNING_PACE_TREND_DIRECTION_UNCHANGED), "->", "an unchanged direction must return the neutral arrow alone");
    return true;
}

(:test)
function arrowForNullDirectionIsNeutral(logger as Logger) as Boolean {
    Test.assertEqualMessage(RunningPaceTrendFormatter.arrowFor(null), "->", "a missing direction must fall back to the neutral arrow");
    return true;
}

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
