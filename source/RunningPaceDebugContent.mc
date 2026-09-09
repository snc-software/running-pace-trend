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

    // One-line summary of the last activity-history scan (#47 follow-up), in
    // the form "<seen>/<kept> <ms>ms <order>", e.g. "1236/45 2741ms D":
    // how many entries the iterator visited, how many fell inside the trend
    // window and were retained, how long the whole refresh took, and which way
    // the iterator was ordered.
    //
    // Deliberately terse. The first attempt spelled this out as
    // "318 seen / 42 kept / 210ms" and the device clipped both ends of it - the
    // debug screen's bottom rows sit where a round display's chord is at its
    // narrowest, and a clipped diagnostic is worse than a cryptic one because
    // the digits that get eaten are exactly the ones being measured.
    //
    // Order is a single letter, from the RUNNING_PACE_SCAN_ORDER_* values:
    // D = newest first, A = oldest first, M = mixed, ? = too few dated
    // activities to tell. D is the one that makes an exact early exit safe in
    // RunningActivityHistoryReader.readAll().
    //
    // Returns null when no refresh has recorded these yet (an install upgraded
    // from a version predating these keys), so the caller can omit the row
    // rather than draw a half-empty one.
    static function formatScanSummary(scanned as Number?, retained as Number?, durationMs as Number?, order as Number?) as String? {
        if (scanned == null || retained == null || durationMs == null) {
            return null;
        }

        var orderLetter;
        if (order == RUNNING_PACE_SCAN_ORDER_NEWEST_FIRST) {
            orderLetter = "D";
        } else if (order == RUNNING_PACE_SCAN_ORDER_OLDEST_FIRST) {
            orderLetter = "A";
        } else if (order == RUNNING_PACE_SCAN_ORDER_MIXED) {
            orderLetter = "M";
        } else {
            orderLetter = "?";
        }

        return scanned.toString() + "/" + retained.toString() + " " + durationMs.toString() + "ms " + orderLetter;
    }

}
