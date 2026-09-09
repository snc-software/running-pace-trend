import Toybox.Activity;
import Toybox.Lang;

enum {
    RUNNING_PACE_DEBUG_STATUS_NEVER_RUN,  // no midnight refresh has fired yet (e.g. first day after install)
    RUNNING_PACE_DEBUG_STATUS_SUCCESS,
    RUNNING_PACE_DEBUG_STATUS_FAILED      // exhausted all retry attempts without succeeding
}

// What the activity-completed background event (#49) did the last time it
// fired. Persisted to Application.Storage and read back by
// RunningPaceActivityEventView, so an install upgraded across a reordering
// would report the wrong outcome. Append, never reorder.
enum {
    RUNNING_PACE_ACTIVITY_EVENT_NEVER_FIRED,        // no activity has completed since install (or the event never registered)
    RUNNING_PACE_ACTIVITY_EVENT_SKIPPED_NOT_RUNNING, // fired for some other sport; no scan was started
    RUNNING_PACE_ACTIVITY_EVENT_REFRESHED,           // a run finished and the refresh succeeded
    RUNNING_PACE_ACTIVITY_EVENT_REFRESH_FAILED       // a run finished but the refresh threw or read nothing
}

// Pure state-selection logic for the two debug screens, decoupled from
// Dc/Storage/Rez so it can be unit tested without a device (coding-standards.md
// Testing section). Mirrors RunningPaceTrendDetailContent's pattern for a
// different view.
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

    // One-line summary of the last activity-history scan, in the form
    // "<seen>/<kept>", e.g. "246/45": how many entries the iterator visited, and
    // how many fell inside the trend window and were retained.
    //
    // Deliberately terse. The first attempt spelled this out as
    // "318 seen / 42 kept / 210ms" and the device clipped both ends of it - the
    // debug screen's rows sit on a round display whose usable chord narrows
    // sharply toward the bottom, and a clipped diagnostic is worse than a
    // cryptic one because the digits that get eaten are exactly the ones being
    // measured.
    //
    // #49 dropped the two other figures this used to carry - the refresh's
    // wall-clock duration in ms, and a letter for the iterator's observed
    // ordering. Both were scaffolding for questions that are now answered
    // (~11ms an entry, oldest-first over 246 entries, both recorded in
    // RESEARCH.md), nothing branched on either, and the chunked scan they were
    // used to tune no longer exists. The counts stay because a retained count
    // that moves is how you tell a refresh actually picked up a new run - which
    // is precisely what #49's activity-completed event has to be verified on.
    //
    // Returns null when no refresh has recorded these yet (an install upgraded
    // from a version predating these keys), so the caller can omit the row
    // rather than draw a half-empty one.
    static function formatScanSummary(scanned as Number?, retained as Number?) as String? {
        if (scanned == null || retained == null) {
            return null;
        }

        return scanned.toString() + "/" + retained.toString();
    }

    // The stored activity-completed outcome, or NEVER_FIRED when nothing has
    // been recorded - either because no activity has completed since install, or
    // because this install predates #49's keys.
    static function resolveActivityEventOutcome(outcome as Number?) as Number {
        if (outcome == null) {
            return RUNNING_PACE_ACTIVITY_EVENT_NEVER_FIRED;
        }

        return outcome;
    }

    // The sport the event reported, as a label. Running gets a word because it
    // is the only one that triggers a refresh and so the only one worth reading
    // at a glance; anything else renders as its raw Activity.Sport number, which
    // is enough to tell two non-running sports apart without a lookup table for
    // the dozens of values that would never change what the handler does.
    //
    // Returns null when the event has never fired, so the caller can omit the
    // row rather than claim a sport that was never seen.
    static function formatSport(sport as Number?, runningLabel as String) as String? {
        if (sport == null) {
            return null;
        }

        if (sport == Activity.SPORT_RUNNING) {
            return runningLabel;
        }

        return "#" + sport.toString();
    }

    // The scanned/retained counts for a specific activity-completed firing,
    // shown only when that firing actually ran a refresh. A skipped (non-running)
    // or failed firing has no counts to report, and drawing a stale pair from an
    // earlier firing next to this one's timestamp would read as though this
    // firing produced them.
    static function formatEventCounts(outcome as Number, scanned as Number?, retained as Number?) as String? {
        if (outcome != RUNNING_PACE_ACTIVITY_EVENT_REFRESHED) {
            return null;
        }

        return formatScanSummary(scanned, retained);
    }

}
