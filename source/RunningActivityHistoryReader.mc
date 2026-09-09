import Toybox.Lang;
import Toybox.Time;
import Toybox.UserProfile;

// Observed ordering of getUserActivityHistory()'s iterator (#47 follow-up).
// The API does not document its order (RESEARCH.md), so the scan measures it
// and surfaces it on the debug screen rather than assuming.
//
// MEASURED ON A REAL DEVICE (fr970): OLDEST_FIRST, over 246 entries. Two
// consequences, both counter-intuitive enough to be worth stating plainly:
//
//  - There is no useful early exit. The entries inside the trend window are at
//    the END of the iteration, so "stop once past the window" - the obvious
//    optimisation, and the right one under NEWEST_FIRST - saves nothing here.
//  - A leading-N cap discards the newest entries, not the oldest. See the note
//    on the removed MAX_ACTIVITIES_SCANNED below.
//
// This is measured, not guaranteed, and other devices or firmware may differ,
// which is why the letter stays on the debug screen. Re-check it before
// building anything on top of the ordering.
//
// Order matters here: these values are persisted to Application.Storage and
// read back by the debug screen, so an install upgraded across a reordering
// would report the wrong letter. Append, never reorder.
enum {
    RUNNING_PACE_SCAN_ORDER_UNKNOWN,      // fewer than two dated activities seen - nothing to infer from
    RUNNING_PACE_SCAN_ORDER_NEWEST_FIRST, // start times strictly descending throughout
    RUNNING_PACE_SCAN_ORDER_OLDEST_FIRST, // start times strictly ascending throughout
    RUNNING_PACE_SCAN_ORDER_MIXED         // neither - an early exit would be unsafe
}

// Wraps UserProfile.getUserActivityHistory(), which has a documented type of
// UserActivityHistoryIterator but is confirmed to sometimes return null instead
// (see RESEARCH.md). Maps each UserActivity into a plain RunningActivityRecord so
// downstream logic never touches the Garmin API types directly.
//
// Scanning is RESUMABLE (#47 follow-up). The whole history was measured at
// ~11ms per entry - 246 entries, ~2.7 seconds - and that cost is
// `iterator.next()` itself, not this class's per-entry work: reordering the
// loop so the window filter runs before any other property read moved the total
// by about 1%. Monkey C cannot yield mid-computation, so a scan run in one go
// blocks the UI thread for its entire duration wherever it is called from.
//
// So callers get a choice:
//  - readAll() runs the whole scan synchronously, for callers with no UI to
//    block: the background service, and the fresh-install path that has nothing
//    drawable to show until it finishes.
//  - beginScan()/scanChunk()/scannedRecords() walk the same scan a few entries
//    at a time, letting the caller return to the UI loop in between. See
//    RunningPaceForegroundRefresh.
class RunningActivityHistoryReader {

    // How many entries the last scan visited, and the order it observed,
    // recorded so RunningPaceRefresh can surface both on the debug screen
    // (#47 follow-up) - the numbers that turned this from guesswork into
    // measurement. Valid once the scan reports itself complete.
    var lastScannedCount as Number = 0;
    var lastScanOrder as Number = RUNNING_PACE_SCAN_ORDER_UNKNOWN;

    // Scan state, retained across scanChunk() calls so a chunked scan can pick
    // up exactly where the previous chunk stopped. The iterator itself is the
    // thing being suspended: it holds the read position, and there is no way to
    // seek back to one, so it must survive between chunks.
    private var iterator as UserProfile.UserActivityHistoryIterator?;
    private var records as Array<RunningActivityRecord> = [] as Array<RunningActivityRecord>;
    private var windowStartEpoch as Number = 0;
    private var scanned as Number = 0;
    private var complete as Boolean = true;

    // Order detection: remember the previous dated activity's start time and
    // note which way each step moved. Only activities with a non-null startTime
    // take part - an undated one says nothing about ordering either way. A
    // separate flag stands in for "no previous activity yet" rather than a
    // nullable epoch, to keep the comparison a plain integer one.
    private var previousStartTimeEpoch as Number = 0;
    private var hasPreviousStartTime as Boolean = false;
    private var sawNewerThanPrevious as Boolean = false;
    private var sawOlderThanPrevious as Boolean = false;

    function initialize() {
    }

    // `windowStart` bounds how far back retained records go: an activity with
    // a known startTime older than windowStart is skipped entirely rather
    // than allocated into the returned array. This bounds the returned
    // *array's* size, but NOT the iteration cost - every entry in the device's
    // on-device history is visited either way, because the measured
    // oldest-first ordering puts the in-window entries last (see the enum
    // above).
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
    // no UI to freeze; otherwise drive the chunked API below.
    function readAll(windowStart as Time.Moment) as Array<RunningActivityRecord> {
        beginScan(windowStart);
        while (!scanChunk(0)) {
        }
        return scannedRecords();
    }

    // Opens a fresh scan, discarding any previous one. Cheap - the cost is all
    // in the iteration itself, not in getting the iterator.
    function beginScan(windowStart as Time.Moment) as Void {
        records = [] as Array<RunningActivityRecord>;
        scanned = 0;
        lastScannedCount = 0;
        lastScanOrder = RUNNING_PACE_SCAN_ORDER_UNKNOWN;

        previousStartTimeEpoch = 0;
        hasPreviousStartTime = false;
        sawNewerThanPrevious = false;
        sawOlderThanPrevious = false;

        // Compared as a raw epoch rather than via Moment.lessThan() so the hot
        // filter below is an integer comparison against a value computed once,
        // not a method call on a freshly read Moment per entry.
        windowStartEpoch = windowStart.value();

        iterator = UserProfile.getUserActivityHistory();
        complete = (iterator == null);
        if (complete) {
            finishScan();
        }
    }

    // Advances the scan by at most `maxEntries` activities, or to the end when
    // `maxEntries` is 0. Returns true once the scan is complete, at which point
    // scannedRecords(), lastScannedCount and lastScanOrder are final and
    // further calls are no-ops.
    //
    // Keep the per-chunk count small when driving this from the UI: at ~11ms an
    // entry, the chunk size is directly the length of the hitch the user feels.
    function scanChunk(maxEntries as Number) as Boolean {
        if (complete) {
            return true;
        }

        var currentIterator = iterator;
        if (currentIterator == null) {
            complete = true;
            finishScan();
            return true;
        }

        var processedThisChunk = 0;
        while (maxEntries == 0 || processedThisChunk < maxEntries) {
            // The compiler warns "Statement is not reachable" on this branch:
            // next() is DECLARED as returning non-null, but in practice returns
            // null at the end of the history (RESEARCH.md documents the same
            // mismatch on getUserActivityHistory() itself). The warning is
            // wrong and this null check is the loop's only terminator - do not
            // "fix" it by deleting the branch.
            var activity = currentIterator.next();
            if (activity == null) {
                complete = true;
                finishScan();
                return true;
            }

            scanned++;
            processedThisChunk++;

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

                if (hasPreviousStartTime) {
                    if (epoch < previousStartTimeEpoch) {
                        sawOlderThanPrevious = true;
                    } else if (epoch > previousStartTimeEpoch) {
                        sawNewerThanPrevious = true;
                    }
                }
                previousStartTimeEpoch = epoch;
                hasPreviousStartTime = true;

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

        return false;
    }

    // The records retained so far. Meaningful once scanChunk() has reported
    // completion; before that it is a partial result and must not be fed to the
    // calculators, which would read it as "these are all the runs there were".
    function scannedRecords() as Array<RunningActivityRecord> {
        return records;
    }

    function isComplete() as Boolean {
        return complete;
    }

    private function finishScan() as Void {
        iterator = null;
        lastScannedCount = scanned;

        if (sawOlderThanPrevious && !sawNewerThanPrevious) {
            lastScanOrder = RUNNING_PACE_SCAN_ORDER_NEWEST_FIRST;
        } else if (sawNewerThanPrevious && !sawOlderThanPrevious) {
            lastScanOrder = RUNNING_PACE_SCAN_ORDER_OLDEST_FIRST;
        } else if (sawNewerThanPrevious && sawOlderThanPrevious) {
            lastScanOrder = RUNNING_PACE_SCAN_ORDER_MIXED;
        }
    }

}
