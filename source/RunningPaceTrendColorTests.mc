import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Test;

(:test)
function returnsGreenForFasterTrend(logger as Logger) as Boolean {
    Test.assertEqualMessage(RunningPaceTrendColor.forDirection(RUNNING_PACE_TREND_DIRECTION_FASTER), Graphics.COLOR_GREEN, "an improving (faster) trend must render green");
    return true;
}

(:test)
function returnsRedForSlowerTrend(logger as Logger) as Boolean {
    Test.assertEqualMessage(RunningPaceTrendColor.forDirection(RUNNING_PACE_TREND_DIRECTION_SLOWER), Graphics.COLOR_RED, "a declining (slower) trend must render red");
    return true;
}

(:test)
function returnsBlueForUnchangedTrend(logger as Logger) as Boolean {
    Test.assertEqualMessage(RunningPaceTrendColor.forDirection(RUNNING_PACE_TREND_DIRECTION_UNCHANGED), Graphics.COLOR_BLUE, "a stable (unchanged) trend must render blue");
    return true;
}

(:test)
function returnsWhiteWhenDirectionIsNull(logger as Logger) as Boolean {
    Test.assertEqualMessage(RunningPaceTrendColor.forDirection(null), Graphics.COLOR_WHITE, "no available trend direction must fall back to the graph's original white line color");
    return true;
}

(:test)
function returnsLightGreenForFasterTrend(logger as Logger) as Boolean {
    Test.assertEqualMessage(RunningPaceTrendColor.lightForDirection(RUNNING_PACE_TREND_DIRECTION_FASTER), Graphics.createColor(255, 170, 255, 170), "an improving (faster) trend's area fill must be a light green tint");
    return true;
}

(:test)
function returnsLightRedForSlowerTrend(logger as Logger) as Boolean {
    Test.assertEqualMessage(RunningPaceTrendColor.lightForDirection(RUNNING_PACE_TREND_DIRECTION_SLOWER), Graphics.createColor(255, 255, 170, 170), "a declining (slower) trend's area fill must be a light red tint");
    return true;
}

(:test)
function returnsLightBlueForUnchangedTrend(logger as Logger) as Boolean {
    Test.assertEqualMessage(RunningPaceTrendColor.lightForDirection(RUNNING_PACE_TREND_DIRECTION_UNCHANGED), Graphics.createColor(255, 170, 170, 255), "a stable (unchanged) trend's area fill must be a light blue tint");
    return true;
}

(:test)
function returnsLightGrayWhenDirectionIsNullForLightVariant(logger as Logger) as Boolean {
    Test.assertEqualMessage(RunningPaceTrendColor.lightForDirection(null), Graphics.COLOR_LT_GRAY, "no available trend direction must fall back to a neutral light gray area fill");
    return true;
}
