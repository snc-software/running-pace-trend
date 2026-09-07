import Toybox.Lang;
import Toybox.Test;

(:test)
function formatsSubTenMinutePaceWithZeroPaddedSeconds(logger as Logger) as Boolean {
    Test.assertEqualMessage(RunningPaceFormatter.format(462), "7:42", "462 seconds/km should format as 7:42");
    Test.assertEqualMessage(RunningPaceFormatter.format(305), "5:05", "a seconds remainder under 10 must be zero-padded");
    return true;
}

(:test)
function formatsPaceOverTenMinutes(logger as Logger) as Boolean {
    Test.assertEqualMessage(RunningPaceFormatter.format(725), "12:05", "725 seconds/km should format as 12:05");
    return true;
}

(:test)
function formatsZeroSecondsPerKmSafely(logger as Logger) as Boolean {
    Test.assertEqualMessage(RunningPaceFormatter.format(0), "0:00", "zero seconds/km must format safely, not crash");
    return true;
}
