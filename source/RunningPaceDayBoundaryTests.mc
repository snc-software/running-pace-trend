import Toybox.Lang;
import Toybox.Test;
import Toybox.Time;

(:test)
function startOfDayZeroesTimeOfDay(logger as Logger) as Boolean {
    // 100000000 is 1973-03-03 09:46:40 UTC; this test, like the codebase's
    // other epoch-pinned tests, assumes the Monkey C test runner's local
    // timezone is UTC.
    var moment = new Time.Moment(100000000);

    var result = RunningPaceDayBoundary.startOfDay(moment);

    Test.assertEqualMessage(result.value(), 99964800, "start of day for 1973-03-03 09:46:40 UTC must be 1973-03-03 00:00:00 UTC");
    return true;
}

(:test)
function startOfDayIsIdempotentOnAMomentAlreadyAtMidnight(logger as Logger) as Boolean {
    var midnight = new Time.Moment(99964800);

    var result = RunningPaceDayBoundary.startOfDay(midnight);

    Test.assertEqualMessage(result.value(), 99964800, "flooring a moment already at midnight must return the same instant");
    return true;
}
