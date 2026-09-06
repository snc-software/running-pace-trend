import Toybox.Lang;
import Toybox.Test;

(:test)
function formatsFasterDirectionWithUpArrow(logger as Logger) as Boolean {
    Test.assertEqualMessage(RunningPaceTrendFormatter.format(RUNNING_PACE_TREND_DIRECTION_FASTER, 11), "↑ 11", "a positive (faster) delta must use an up arrow");
    return true;
}

(:test)
function formatsSlowerDirectionWithDownArrow(logger as Logger) as Boolean {
    Test.assertEqualMessage(RunningPaceTrendFormatter.format(RUNNING_PACE_TREND_DIRECTION_SLOWER, 11), "↓ 11", "a negative (slower) delta must use a down arrow");
    return true;
}

(:test)
function formatsUnchangedDirectionWithNeutralArrowAndZero(logger as Logger) as Boolean {
    Test.assertEqualMessage(RunningPaceTrendFormatter.format(RUNNING_PACE_TREND_DIRECTION_UNCHANGED, 0), "→ 0", "a zero delta must use a neutral arrow");
    return true;
}
