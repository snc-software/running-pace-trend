import Toybox.Lang;
import Toybox.Test;

(:test)
function formatsWholeKilometresWithOneDecimalPlace(logger as Logger) as Boolean {
    Test.assertEqualMessage(RunningPaceDistanceFormatter.format(86400), "86.4", "86400m must format as 86.4");
    return true;
}

(:test)
function roundsToNearestTenthOfAKilometre(logger as Logger) as Boolean {
    Test.assertEqualMessage(RunningPaceDistanceFormatter.format(1250), "1.3", "1250m must round up to 1.3");
    return true;
}

(:test)
function formatsZeroDistance(logger as Logger) as Boolean {
    Test.assertEqualMessage(RunningPaceDistanceFormatter.format(0), "0.0", "zero distance must format as 0.0");
    return true;
}
