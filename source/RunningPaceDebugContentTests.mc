import Toybox.Activity;
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
function formatsTheScanSummaryFromBothCounters(logger as Logger) as Boolean {
    Test.assertEqualMessage(RunningPaceDebugContent.formatScanSummary(246, 45), "246/45", "the scan summary must report scanned then retained");
    return true;
}

(:test)
function formatsAZeroScanSummary(logger as Logger) as Boolean {
    Test.assertEqualMessage(RunningPaceDebugContent.formatScanSummary(0, 0), "0/0", "an empty history must still format rather than being treated as unrecorded");
    return true;
}

// Every "must be null" assertion in this file uses assertMessage with an
// explicit == null rather than assertEqualMessage(..., null, ...). The latter
// does not work: Test.assertEqual dereferences its expected value, so passing
// null aborts the test with "Unexpected Type Error / Failed invoking <symbol>"
// instead of comparing anything. Two assertions in this file were written that
// way before #49 and had been erroring silently in the suite's summary line
// ever since; they are corrected here along with the new ones.
(:test)
function omitsTheScanSummaryWhenNothingHasBeenRecordedYet(logger as Logger) as Boolean {
    Test.assertMessage(RunningPaceDebugContent.formatScanSummary(null, null) == null, "an install predating the scan counters must omit the row");
    Test.assertMessage(RunningPaceDebugContent.formatScanSummary(246, null) == null, "a partially recorded scan must omit the row rather than draw a gap");
    Test.assertMessage(RunningPaceDebugContent.formatScanSummary(null, 45) == null, "a missing scanned count must omit the row too");
    return true;
}

(:test)
function resolvesNeverFiredWhenTheActivityEventHasNotRun(logger as Logger) as Boolean {
    Test.assertEqualMessage(RunningPaceDebugContent.resolveActivityEventOutcome(null), RUNNING_PACE_ACTIVITY_EVENT_NEVER_FIRED, "a null stored outcome must resolve to NEVER_FIRED");
    return true;
}

(:test)
function resolvesEachStoredActivityEventOutcome(logger as Logger) as Boolean {
    Test.assertEqualMessage(RunningPaceDebugContent.resolveActivityEventOutcome(RUNNING_PACE_ACTIVITY_EVENT_SKIPPED_NOT_RUNNING), RUNNING_PACE_ACTIVITY_EVENT_SKIPPED_NOT_RUNNING, "a skipped firing must round-trip");
    Test.assertEqualMessage(RunningPaceDebugContent.resolveActivityEventOutcome(RUNNING_PACE_ACTIVITY_EVENT_REFRESHED), RUNNING_PACE_ACTIVITY_EVENT_REFRESHED, "a refreshed firing must round-trip");
    Test.assertEqualMessage(RunningPaceDebugContent.resolveActivityEventOutcome(RUNNING_PACE_ACTIVITY_EVENT_REFRESH_FAILED), RUNNING_PACE_ACTIVITY_EVENT_REFRESH_FAILED, "a failed firing must round-trip");
    return true;
}

(:test)
function formatsRunningAsItsOwnSportLabel(logger as Logger) as Boolean {
    Test.assertEqualMessage(RunningPaceDebugContent.formatSport(Activity.SPORT_RUNNING, "Run"), "Run", "running must render as the supplied label, since it is the only sport that triggers a refresh");
    return true;
}

(:test)
function formatsAnyOtherSportByItsNumber(logger as Logger) as Boolean {
    Test.assertEqualMessage(RunningPaceDebugContent.formatSport(Activity.SPORT_CYCLING, "Run"), "#" + Activity.SPORT_CYCLING.toString(), "a non-running sport must render as its raw number, never as the running label");
    return true;
}

(:test)
function omitsTheSportWhenTheEventHasNeverFired(logger as Logger) as Boolean {
    Test.assertMessage(RunningPaceDebugContent.formatSport(null, "Run") == null, "no recorded sport must omit the row rather than claim one that was never seen");
    return true;
}

(:test)
function reportsTheEventCountsOnlyWhenThatFiringRefreshed(logger as Logger) as Boolean {
    Test.assertEqualMessage(RunningPaceDebugContent.formatEventCounts(RUNNING_PACE_ACTIVITY_EVENT_REFRESHED, 246, 47), "246/47", "a refreshed firing must report its own scanned/retained counts");
    return true;
}

(:test)
function omitsTheEventCountsUnlessTheEventRefreshed(logger as Logger) as Boolean {
    Test.assertMessage(RunningPaceDebugContent.formatEventCounts(RUNNING_PACE_ACTIVITY_EVENT_SKIPPED_NOT_RUNNING, 246, 47) == null, "a skipped firing ran no scan, so stale counts must not be shown under its timestamp");
    Test.assertMessage(RunningPaceDebugContent.formatEventCounts(RUNNING_PACE_ACTIVITY_EVENT_REFRESH_FAILED, 246, 47) == null, "a failed firing produced no counts of its own");
    Test.assertMessage(RunningPaceDebugContent.formatEventCounts(RUNNING_PACE_ACTIVITY_EVENT_NEVER_FIRED, null, null) == null, "an event that never fired must omit the row");
    return true;
}
