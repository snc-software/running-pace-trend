import Toybox.Lang;

enum {
    RUNNING_PACE_DEBUG_STATUS_NEVER_RUN,  // no midnight refresh has fired yet (e.g. first day after install)
    RUNNING_PACE_DEBUG_STATUS_SUCCESS,
    RUNNING_PACE_DEBUG_STATUS_FAILED      // exhausted all retry attempts without succeeding
}

// Pure state-selection logic for the debug screen, decoupled from Dc/Storage/Rez
// so it can be unit tested without a device (coding-standards.md Testing
// section). Mirrors RunningPaceTrendDetailContent's pattern for a different
// view.
class RunningPaceDebugContent {

    static function resolveStatus(succeeded as Boolean?) as Number {
        if (succeeded == null) {
            return RUNNING_PACE_DEBUG_STATUS_NEVER_RUN;
        }

        if (succeeded) {
            return RUNNING_PACE_DEBUG_STATUS_SUCCESS;
        }

        return RUNNING_PACE_DEBUG_STATUS_FAILED;
    }

}
