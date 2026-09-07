import Toybox.Lang;
import Toybox.Test;

(:test)
function resolvesNoDataWhenCurrentHasNoPace(logger as Logger) as Boolean {
    Test.assertEqualMessage(RunningPaceTrendDetailContent.resolveState(false, false), RUNNING_PACE_TREND_DETAIL_STATE_NO_DATA, "no current pace must resolve to no-data");
    return true;
}

(:test)
function resolvesNoDataWhenCurrentFlagIsNull(logger as Logger) as Boolean {
    Test.assertEqualMessage(RunningPaceTrendDetailContent.resolveState(null, null), RUNNING_PACE_TREND_DETAIL_STATE_NO_DATA, "no stored flag yet (background service hasn't run) must resolve to no-data");
    return true;
}

(:test)
function resolvesCurrentOnlyWhenCurrentHasPaceButTrendDoesNot(logger as Logger) as Boolean {
    Test.assertEqualMessage(RunningPaceTrendDetailContent.resolveState(true, false), RUNNING_PACE_TREND_DETAIL_STATE_CURRENT_ONLY, "current pace without trend data must resolve to current-only");
    return true;
}

(:test)
function resolvesCurrentOnlyWhenTrendFlagIsNull(logger as Logger) as Boolean {
    Test.assertEqualMessage(RunningPaceTrendDetailContent.resolveState(true, null), RUNNING_PACE_TREND_DETAIL_STATE_CURRENT_ONLY, "a missing trend flag must resolve to current-only");
    return true;
}

(:test)
function resolvesFullWhenBothCurrentAndTrendHaveData(logger as Logger) as Boolean {
    Test.assertEqualMessage(RunningPaceTrendDetailContent.resolveState(true, true), RUNNING_PACE_TREND_DETAIL_STATE_FULL, "both current and trend data present must resolve to full");
    return true;
}
