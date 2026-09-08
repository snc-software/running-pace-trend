import Toybox.Lang;
import Toybox.Test;
import Toybox.Time;

(:test)
function nextMidnightReturnsFollowingDayForAMidDayMoment(logger as Logger) as Boolean {
    // 100000000 is 1973-03-03 09:46:40 UTC; this test, like this codebase's
    // other epoch-pinned tests, assumes the Monkey C test runner's local
    // timezone is UTC.
    var moment = new Time.Moment(100000000);

    var result = RunningPaceBackgroundSchedule.nextMidnight(moment);

    Test.assertEqualMessage(result.value(), 100051200, "next midnight after 1973-03-03 09:46:40 UTC must be 1973-03-04 00:00:00 UTC");
    return true;
}

(:test)
function nextMidnightSkipsForwardWhenMomentIsAlreadyAtMidnight(logger as Logger) as Boolean {
    var midnight = new Time.Moment(99964800);

    var result = RunningPaceBackgroundSchedule.nextMidnight(midnight);

    Test.assertEqualMessage(result.value(), 100051200, "next midnight for a moment already at 1973-03-03 00:00:00 UTC must be the following day, not the same instant");
    return true;
}
