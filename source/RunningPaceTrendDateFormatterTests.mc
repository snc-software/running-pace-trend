import Toybox.Lang;
import Toybox.Test;

(:test)
function formatsSingleDigitDayAndMonthWithZeroPadding(logger as Logger) as Boolean {
    // 94902400 is 1973-01-03 09:46:40 UTC; this test, like the codebase's
    // other epoch-pinned tests, assumes the Monkey C test runner's local
    // timezone is UTC.
    Test.assertEqualMessage(RunningPaceTrendDateFormatter.format(94902400), "03/01", "a single-digit day and month must both be zero-padded");
    return true;
}

(:test)
function formatsDoubleDigitDayAndMonth(logger as Logger) as Boolean {
    // 125660800 is 1973-12-25 09:46:40 UTC.
    Test.assertEqualMessage(RunningPaceTrendDateFormatter.format(125660800), "25/12", "a double-digit day and month must not be zero-padded");
    return true;
}

(:test)
function formatsRangeAsTwoDatesSeparatedByDash(logger as Logger) as Boolean {
    Test.assertEqualMessage(RunningPaceTrendDateFormatter.formatRange(94902400, 125660800), "03/01 - 25/12", "a range must format both dates separated by ' - '");
    return true;
}
