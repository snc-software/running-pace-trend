import Toybox.Lang;

enum {
    RUNNING_PACE_TREND_DETAIL_STATE_NO_DATA,       // current period itself has no pace
    RUNNING_PACE_TREND_DETAIL_STATE_CURRENT_ONLY,  // current pace available, trend comparison isn't
    RUNNING_PACE_TREND_DETAIL_STATE_FULL           // both available
}

// Pure state-selection logic for the detail view, decoupled from Dc/Storage/Rez
// so it can be unit tested without a device (coding-standards.md Testing
// section). Mirrors RunningPaceGlanceContent's pattern for a different view.
class RunningPaceTrendDetailContent {

    static function resolveState(hasSufficientData as Boolean?, trendHasSufficientData as Boolean?) as Number {
        if (hasSufficientData != true) {
            return RUNNING_PACE_TREND_DETAIL_STATE_NO_DATA;
        }

        if (trendHasSufficientData != true) {
            return RUNNING_PACE_TREND_DETAIL_STATE_CURRENT_ONLY;
        }

        return RUNNING_PACE_TREND_DETAIL_STATE_FULL;
    }

}
