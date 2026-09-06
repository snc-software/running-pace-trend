import Toybox.Lang;

// Pure display formatting, decoupled from GlanceView so it can be unit tested
// without a device (coding-standards.md Testing section).
class RunningPaceFormatter {

    private static const SECONDS_PER_MINUTE = 60;

    // Formats whole seconds/km as "M:SS", e.g. 462 -> "7:42".
    static function format(secondsPerKm as Number) as String {
        if (secondsPerKm < 0) {
            secondsPerKm = 0;
        }

        var minutes = secondsPerKm / SECONDS_PER_MINUTE;
        var seconds = secondsPerKm % SECONDS_PER_MINUTE;
        var secondsText = seconds < 10 ? "0" + seconds.toString() : seconds.toString();

        return minutes.toString() + ":" + secondsText;
    }

}
