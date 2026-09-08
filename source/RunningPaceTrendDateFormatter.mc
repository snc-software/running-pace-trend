import Toybox.Lang;
import Toybox.Time;
import Toybox.Time.Gregorian;

// Pure date/time formatting shared by the app's screens, decoupled from
// Application.Storage/View so it can be unit tested without a device
// (coding-standards.md Testing section). Originally built for the detail
// screen's period rows to replace the meaningless "Current"/"Previous"
// labels with each period's actual DD/MM date range (#37); formatDateTime()
// extends it with a DD/MM HH:MM timestamp for the debug screen's refresh
// times.
class RunningPaceTrendDateFormatter {

    // Formats a single epoch-seconds moment as zero-padded "DD/MM".
    static function format(epochSeconds as Number) as String {
        var info = Gregorian.info(new Time.Moment(epochSeconds), Time.FORMAT_SHORT);
        return padTwoDigits(info.day) + "/" + padTwoDigits(info.month);
    }

    // Formats a period as "DD/MM - DD/MM", e.g. "07/07 - 06/08" (#37).
    static function formatRange(startEpochSeconds as Number, endEpochSeconds as Number) as String {
        return format(startEpochSeconds) + " - " + format(endEpochSeconds);
    }

    // Formats a single epoch-seconds moment as zero-padded "DD/MM HH:MM".
    static function formatDateTime(epochSeconds as Number) as String {
        var info = Gregorian.info(new Time.Moment(epochSeconds), Time.FORMAT_SHORT);
        return padTwoDigits(info.day) + "/" + padTwoDigits(info.month) + " " + padTwoDigits(info.hour) + ":" + padTwoDigits(info.min);
    }

    private static function padTwoDigits(value as Number) as String {
        if (value < 10) {
            return "0" + value.toString();
        }
        return value.toString();
    }

}
