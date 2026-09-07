import Toybox.Lang;

enum {
    RUNNING_PACE_GLANCE_VALUE_STATE_AVAILABLE,
    RUNNING_PACE_GLANCE_VALUE_STATE_INSUFFICIENT
}

// Pure state-selection logic for the Glance, decoupled from Dc/Storage/Rez so
// it can be unit tested without a device (coding-standards.md Testing
// section). Mirrors the exact conditions RunningPaceGlanceView.onUpdate()
// evaluates inline today - no behaviour change.
class RunningPaceGlanceContent {

    static function resolveValueState(hasSufficientData as Boolean?, secondsPerKm as Number?) as Number {
        if (hasSufficientData == true && secondsPerKm != null) {
            return RUNNING_PACE_GLANCE_VALUE_STATE_AVAILABLE;
        }

        return RUNNING_PACE_GLANCE_VALUE_STATE_INSUFFICIENT;
    }

    static function shouldShowTrend(trendHasSufficientData as Boolean?, trendDirection as Number?, trendDeltaSecondsPerKm as Number?) as Boolean {
        return trendHasSufficientData == true && trendDirection != null && trendDeltaSecondsPerKm != null;
    }

}
