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
