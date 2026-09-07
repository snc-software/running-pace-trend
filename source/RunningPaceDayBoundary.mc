import Toybox.Lang;
import Toybox.Time;
import Toybox.Time.Gregorian;

// Pure calendar-day boundary helper, decoupled from Application.Storage/View
// so it can be unit tested without a device (coding-standards.md Testing
// section). Anchors rolling-window boundaries to local midnight instead of
// exact clock time (#32) - Gregorian.info() reports hour/min/sec in local
// time, so subtracting those elapsed seconds from `moment` yields the
// absolute instant that was local midnight on `moment`'s calendar day. This
// deliberately avoids Gregorian.moment(), whose {:year, :month, :day, ...}
// fields are interpreted as UTC even though Gregorian.info() reports them in
// local time - reusing it here would silently shift the boundary by the
// device's UTC offset.
class RunningPaceDayBoundary {

    static function startOfDay(moment as Time.Moment) as Time.Moment {
        var info = Gregorian.info(moment, Time.FORMAT_SHORT);
        var secondsSinceMidnight = info.hour * 3600 + info.min * 60 + info.sec;
        return moment.subtract(new Time.Duration(secondsSinceMidnight)) as Time.Moment;
    }

}
