import Toybox.Lang;
import Toybox.Test;

(:test)
function resolvesAvailableWhenSufficientDataAndPaceValuePresent(logger as Logger) as Boolean {
    Test.assertEqualMessage(RunningPaceGlanceContent.resolveValueState(true, 462), RUNNING_PACE_GLANCE_VALUE_STATE_AVAILABLE, "sufficient data with a pace value must be available");
    return true;
}

(:test)
function resolvesInsufficientWhenHasSufficientDataIsFalse(logger as Logger) as Boolean {
    Test.assertEqualMessage(RunningPaceGlanceContent.resolveValueState(false, null), RUNNING_PACE_GLANCE_VALUE_STATE_INSUFFICIENT, "insufficient data must be insufficient regardless of pace value");
    return true;
}

(:test)
function resolvesInsufficientWhenHasSufficientDataIsNull(logger as Logger) as Boolean {
    Test.assertEqualMessage(RunningPaceGlanceContent.resolveValueState(null, null), RUNNING_PACE_GLANCE_VALUE_STATE_INSUFFICIENT, "no stored flag yet (background service hasn't run) must be insufficient");
    return true;
}

(:test)
function resolvesInsufficientWhenSecondsPerKmIsNullDespiteFlag(logger as Logger) as Boolean {
    Test.assertEqualMessage(RunningPaceGlanceContent.resolveValueState(true, null), RUNNING_PACE_GLANCE_VALUE_STATE_INSUFFICIENT, "a missing pace value must be insufficient even if the flag says otherwise");
    return true;
}

(:test)
function showsTrendWhenAllTrendFieldsPresent(logger as Logger) as Boolean {
    Test.assertMessage(RunningPaceGlanceContent.shouldShowTrend(true, RUNNING_PACE_TREND_DIRECTION_FASTER, 11), "all trend fields present must show the trend line");
    return true;
}

(:test)
function hidesTrendWhenTrendHasSufficientDataIsFalse(logger as Logger) as Boolean {
    Test.assertMessage(!RunningPaceGlanceContent.shouldShowTrend(false, null, null), "insufficient trend data must hide the trend line");
    return true;
}

(:test)
function hidesTrendWhenTrendHasSufficientDataIsNull(logger as Logger) as Boolean {
    Test.assertMessage(!RunningPaceGlanceContent.shouldShowTrend(null, null, null), "no stored trend flag yet must hide the trend line");
    return true;
}

(:test)
function hidesTrendWhenDirectionIsNullDespiteFlag(logger as Logger) as Boolean {
    Test.assertMessage(!RunningPaceGlanceContent.shouldShowTrend(true, null, 11), "a missing direction must hide the trend line even if the flag says otherwise");
    return true;
}

(:test)
function hidesTrendWhenDeltaIsNullDespiteFlag(logger as Logger) as Boolean {
    Test.assertMessage(!RunningPaceGlanceContent.shouldShowTrend(true, RUNNING_PACE_TREND_DIRECTION_FASTER, null), "a missing delta must hide the trend line even if the flag says otherwise");
    return true;
}
