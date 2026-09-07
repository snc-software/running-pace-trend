import Toybox.Lang;

// Pure display formatting for the trend arrow + delta pairing, decoupled from
// GlanceView so it can be unit tested without a device (coding-standards.md
// Testing section). Mirrors RunningPaceFormatter's split between raw display
// logic (here) and the Rez-loaded qualifier wording owned by the View.
class RunningPaceTrendFormatter {

    // Formats the arrow + number portion only, e.g. (FASTER, 11) -> "↑ 11".
    // The caller appends the direction-appropriate unit/qualifier suffix.
    static function format(direction as Number, deltaSecondsPerKm as Number) as String {
        var arrow;
        if (direction == RUNNING_PACE_TREND_DIRECTION_FASTER) {
            arrow = "↑";
        } else if (direction == RUNNING_PACE_TREND_DIRECTION_SLOWER) {
            arrow = "↓";
        } else {
            arrow = "→";
        }

        return arrow + " " + deltaSecondsPerKm.toString();
    }

    // Formats integer tenths-of-a-percent as "N.N%", e.g. 23 -> "2.3%". No
    // sign/direction — the delta line above it already conveys faster/slower.
    static function formatPercent(percentChangeTenths as Number) as String {
        var wholePercent = percentChangeTenths / 10;
        var remainderTenths = percentChangeTenths % 10;

        return wholePercent.toString() + "." + remainderTenths.toString() + "%";
    }

}
