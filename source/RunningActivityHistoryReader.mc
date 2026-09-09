import Toybox.Lang;
import Toybox.Time;
import Toybox.UserProfile;

// Wraps UserProfile.getUserActivityHistory(), which has a documented type of
// UserActivityHistoryIterator but is confirmed to sometimes return null instead
// (see RESEARCH.md). Maps each UserActivity into a plain RunningActivityRecord so
// downstream logic never touches the Garmin API types directly.
//
// The whole history was measured on a real device (fr970) at ~11ms per entry -
// 246 entries, ~2.7 seconds - and that cost is `iterator.next()` itself, not
// this class's per-entry work: reordering the loop so the window filter runs
// before any other property read moved the total by about 1%. Monkey C cannot
// yield mid-computation, so readAll() blocks its caller for that whole duration.
//
// That is fine now, and the scan is a single plain loop again (#49). It was
// previously resumable - beginScan()/scanChunk()/scannedRecords() walked it a
// few entries at a time - purely so RunningPaceForegroundRefresh could return to
// the UI loop between chunks and keep the widget responsive. #49 deleted that
// class: both remaining callers, the background service and the fresh-install
// path in getInitialView(), have no UI to block, and a few seconds at midnight
// or just after a run finishes is acceptable. The chunking bought nothing once
// its only UI-thread caller was gone, so it went with it.
//
// The iterator's ORDERING was also measured, and one consequence still governs
// this loop even though the measurement itself is no longer re-taken at runtime
// (#49 removed the per-scan order detection, since the answer is settled and
// nothing branched on it): on fr970 the iteration runs OLDEST-FIRST over 246
// entries. So the entries inside the trend window are at the END of the
// iteration, and there is no useful early exit - "stop once past the window",
// the obvious optimisation and the right one under newest-first, saves nothing
// here. See RESEARCH.md.
class RunningActivityHistoryReader {

    // How many entries the last scan visited, recorded so RunningPaceRefresh can
    // surface it on the debug screen - the number that turned this from
    // guesswork into measurement. Valid once readAll() has returned.
    var lastScannedCount as Number = 0;

    function initialize() {
    }

    // `windowStart` bounds how far back retained records go: an activity with
    // a known startTime older than windowStart is skipped entirely rather
    // than allocated into the returned array. This bounds the returned
    // *array's* size, but NOT the iteration cost - every entry in the device's
    // on-device history is visited either way, because the measured
    // oldest-first ordering puts the in-window entries last (see above).
    //
    // There is deliberately NO cap on how many entries this scans (#47
    // follow-up). A `MAX_ACTIVITIES_SCANNED = 2000` backstop was added earlier
    // on the assumption that the iteration might be unboundedly deep, then
    // removed once the device was actually measured: a real watch reported 246
    // total entries, so the cap never engaged and bounded nothing. Worse, the
    // same measurement showed the iterator runs OLDEST-FIRST, which makes a
    // leading-N cap actively harmful - it would keep the oldest entries and
    // discard the newest, i.e. throw away precisely the activities inside the
    // trend window, silently and with no error to show for it. A cap that
    // truncates the wrong end is worse than a slow scan.
    //
    // Blocks for the full ~2.7s measured on-device. Only call it where there is
    // no UI to freeze.
    function readAll(windowStart as Time.Moment) as Array<RunningActivityRecord> {
        var records = [] as Array<RunningActivityRecord>;
        var scanned = 0;
        lastScannedCount = 0;

        // Compared as a raw epoch rather than via Moment.lessThan() so the hot
        // filter below is an integer comparison against a value computed once,
        // not a method call on a freshly read Moment per entry.
        var windowStartEpoch = windowStart.value();

        // The compiler warns "Statement is not reachable" here, for the same
        // wrong reason it does on the next() check below: getUserActivityHistory()
        // is DECLARED as returning a non-null iterator, but is confirmed to
        // return null in practice (RESEARCH.md). Do not delete this branch to
        // silence the warning - it is the difference between an empty result and
        // a null-dereference crash.
        var iterator = UserProfile.getUserActivityHistory();
        if (iterator == null) {
            return records;
        }

        while (true) {
            // The compiler warns "Statement is not reachable" on this branch:
            // next() is DECLARED as returning non-null, but in practice returns
            // null at the end of the history (RESEARCH.md documents the same
            // mismatch on getUserActivityHistory() itself). The warning is
            // wrong and this null check is the loop's only terminator - do not
            // "fix" it by deleting the branch.
            var activity = iterator.next();
            if (activity == null) {
                break;
            }

            scanned++;

            // Start time is read FIRST and the window filter applied
            // immediately, before any other property on the native UserActivity
            // is touched (#47 follow-up). This turned out to be worth about 1%
            // of the total - the cost is `next()` itself - but it is still the
            // right shape, and anything added to this loop belongs below the
            // filter, not above it.
            var startTime = activity.startTime;
            var startTimeEpoch = null;
            if (startTime != null) {
                var epoch = startTime.value();
                startTimeEpoch = epoch;

                if (epoch < windowStartEpoch) {
                    continue;
                }
            }

            var duration = activity.duration;
            var durationSeconds = null;
            if (duration != null) {
                durationSeconds = duration.value();
            }

            records.add(new RunningActivityRecord(
                activity.distance,
                durationSeconds,
                startTimeEpoch,
                activity.type
            ));
        }

        lastScannedCount = scanned;
        return records;
    }

}
