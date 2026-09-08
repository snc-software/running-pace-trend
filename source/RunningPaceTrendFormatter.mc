import Toybox.Lang;

// Pure display formatting for the trend delta's percent-change wording,
// decoupled from the View so it can be unit tested without a device
// (coding-standards.md Testing section). Mirrors RunningPaceFormatter's
// split between raw display logic (here) and the Rez-loaded qualifier
// wording owned by the View.
class RunningPaceTrendFormatter {

    // Formats integer tenths-of-a-percent as "N.N%", e.g. 23 -> "2.3%". No
    // sign/direction — the delta line above it already conveys faster/slower.
    static function formatPercent(percentChangeTenths as Number) as String {
        var wholePercent = percentChangeTenths / 10;
        var remainderTenths = percentChangeTenths % 10;

        return wholePercent.toString() + "." + remainderTenths.toString() + "%";
    }

    // Combines the delta text (already suffixed by the caller with its
    // direction-appropriate wording) with the percent text in parentheses on
    // a single line (#37), e.g. ("16 sec/km faster", "3.4%") ->
    // "16 sec/km faster (3.4%)". Replaces the detail screen's previous
    // separate percent-only row.
    static function combineDeltaAndPercent(deltaText as String, percentText as String) as String {
        return deltaText + " (" + percentText + ")";
    }

}
