import Toybox.Lang;

// Maintains the capped, deduplicated list of rolling-30-day weighted pace
// snapshots persisted to Application.Storage, decoupled from Storage itself so
// it can be unit tested without a device (coding-standards.md Testing
// section). Snapshots are graph-ready state for a future longer-term trend
// view (US-07 / #12) — this class does not draw anything itself.
class RunningPaceTrendHistory {

    // ~6 months of daily snapshots at the background service's existing ~24h
    // recompute cadence. At a couple of short keys plus two small integers per
    // entry this stays a few KB, well inside Application.Storage's 32 KB
    // per-value limit (coding-standards.md Persistence section: avoid storing
    // large objects).
    static const MAX_SNAPSHOTS = 180;

    private static const SECONDS_PER_DAY = 86400;

    // Returns an updated copy of `existingSnapshots` with a snapshot for
    // (dateEpoch, secondsPerKm) recorded. A new snapshot falling on the same
    // UTC day as the last stored snapshot overwrites it in place, rather than
    // appending a duplicate (AC: "existing snapshots are not unnecessarily
    // duplicated") — safe because snapshots are always appended in
    // chronological order, so only the last entry can ever collide with a new
    // one. Once the list exceeds MAX_SNAPSHOTS, the oldest entries are
    // dropped first.
    static function recordSnapshot(existingSnapshots as Array<Dictionary>, dateEpoch as Number, secondsPerKm as Number) as Array<Dictionary> {
        var newSnapshot = {
            "date" => dateEpoch,
            "secondsPerKm" => secondsPerKm
        };

        var updated = [] as Array<Dictionary>;
        var lastIndex = existingSnapshots.size() - 1;

        for (var i = 0; i < existingSnapshots.size(); i++) {
            if (i == lastIndex && isSameDay(existingSnapshots[i]["date"] as Number, dateEpoch)) {
                updated.add(newSnapshot);
            } else {
                updated.add(existingSnapshots[i]);
            }
        }

        if (lastIndex < 0 || !isSameDay(existingSnapshots[lastIndex]["date"] as Number, dateEpoch)) {
            updated.add(newSnapshot);
        }

        if (updated.size() <= MAX_SNAPSHOTS) {
            return updated;
        }

        var trimmed = [] as Array<Dictionary>;
        var startIndex = updated.size() - MAX_SNAPSHOTS;
        for (var j = startIndex; j < updated.size(); j++) {
            trimmed.add(updated[j]);
        }

        return trimmed;
    }

    private static function isSameDay(a as Number, b as Number) as Boolean {
        return (a / SECONDS_PER_DAY) == (b / SECONDS_PER_DAY);
    }

}
