import Toybox.Lang;
import Toybox.Test;

(:test)
function resolvesNeverRunWhenNoMidnightRefreshHasFired(logger as Logger) as Boolean {
    Test.assertEqualMessage(RunningPaceDebugContent.resolveStatus(null), RUNNING_PACE_DEBUG_STATUS_NEVER_RUN, "a null succeeded value must resolve to NEVER_RUN");
    return true;
}

(:test)
function resolvesSuccessWhenTheRefreshSucceeded(logger as Logger) as Boolean {
    Test.assertEqualMessage(RunningPaceDebugContent.resolveStatus(true), RUNNING_PACE_DEBUG_STATUS_SUCCESS, "true must resolve to SUCCESS");
    return true;
}

(:test)
function resolvesFailedWhenTheRefreshDidNotSucceed(logger as Logger) as Boolean {
    Test.assertEqualMessage(RunningPaceDebugContent.resolveStatus(false), RUNNING_PACE_DEBUG_STATUS_FAILED, "false must resolve to FAILED");
    return true;
}

(:test)
function formatsTheScanSummaryFromAllFourCounters(logger as Logger) as Boolean {
    Test.assertEqualMessage(RunningPaceDebugContent.formatScanSummary(1236, 45, 2741, RUNNING_PACE_SCAN_ORDER_NEWEST_FIRST), "1236/45 2741ms D", "the scan summary must report scanned, retained, duration and order in that order");
    return true;
}

(:test)
function formatsEachScanOrderAsItsOwnLetter(logger as Logger) as Boolean {
    Test.assertEqualMessage(RunningPaceDebugContent.formatScanSummary(1, 1, 1, RUNNING_PACE_SCAN_ORDER_OLDEST_FIRST), "1/1 1ms A", "oldest-first must render as A");
    Test.assertEqualMessage(RunningPaceDebugContent.formatScanSummary(1, 1, 1, RUNNING_PACE_SCAN_ORDER_MIXED), "1/1 1ms M", "mixed must render as M");
    Test.assertEqualMessage(RunningPaceDebugContent.formatScanSummary(1, 1, 1, RUNNING_PACE_SCAN_ORDER_UNKNOWN), "1/1 1ms ?", "an undetermined order must render as ?");
    Test.assertEqualMessage(RunningPaceDebugContent.formatScanSummary(1, 1, 1, null), "1/1 1ms ?", "a missing order must render as ? rather than omitting the whole row");
    return true;
}

(:test)
function formatsAZeroScanSummary(logger as Logger) as Boolean {
    Test.assertEqualMessage(RunningPaceDebugContent.formatScanSummary(0, 0, 0, RUNNING_PACE_SCAN_ORDER_UNKNOWN), "0/0 0ms ?", "an empty history must still format rather than being treated as unrecorded");
    return true;
}

(:test)
function omitsTheScanSummaryWhenNothingHasBeenRecordedYet(logger as Logger) as Boolean {
    Test.assertEqualMessage(RunningPaceDebugContent.formatScanSummary(null, null, null, null), null, "an install predating the scan counters must omit the row");
    Test.assertEqualMessage(RunningPaceDebugContent.formatScanSummary(318, null, 210, RUNNING_PACE_SCAN_ORDER_NEWEST_FIRST), null, "a partially recorded scan must omit the row rather than draw a gap");
    return true;
}
