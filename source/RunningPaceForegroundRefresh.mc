import Toybox.Lang;
import Toybox.System;
import Toybox.Time;
import Toybox.Timer;
import Toybox.WatchUi;

// Runs #40's foreground-open refresh without freezing the UI (#47 follow-up),
// by walking the activity-history scan a few entries at a time instead of all
// at once.
//
// The history scan was measured on-device at ~11ms per entry - 246 entries,
// ~2.7 seconds - and that cost is `iterator.next()` itself, so it cannot be
// optimised away: reordering the loop to filter before reading any other
// property moved the total by about 1%, and the measured oldest-first ordering
// rules out stopping early (see RunningActivityHistoryReader). Monkey C has no
// way to yield mid-computation, so those 2.7 seconds block the UI thread solid
// wherever they run. Two earlier attempts confirmed that the hard way:
//
//  - running inline in onStart() aborted the Glance outright (the original #47
//    bug, a scope error rather than a timing one);
//  - running inline in getInitialView() made the app slow to OPEN, since that
//    is called before the first frame is drawn;
//  - running it whole on a post-first-frame timer fixed the open and simply
//    moved the freeze - the app appeared instantly, then would not page
//    between screens for several seconds.
//
// Chunking is what actually fixes it. Each timer tick advances the scan by
// CHUNK_SIZE entries and returns, so the UI loop gets to run - and process
// input - in between. The refresh takes slightly longer in wall-clock terms;
// it just stops holding the watch hostage while it happens. Only once the scan
// completes are the calculators run and Storage written, in one final tick.
//
// WIDGET SCOPE ONLY, like RunningPaceRefresh itself: this class is not
// (:glance) and must never be reached from Glance scope, which is a separate
// 32kB binary that does not contain it (see RunningPaceRefresh.mc and
// RESEARCH.md). Its only caller is running_pace_trendApp.getInitialView().
class RunningPaceForegroundRefresh {

    // Entries per tick. At the measured ~11ms an entry this is directly the
    // length of the hitch the user can feel, so it is deliberately small:
    // ~90ms is short enough to read as normal UI latency rather than a stall.
    // Raising it makes the refresh finish sooner and the watch feel worse.
    private static const CHUNK_SIZE = 8;

    // Gap between chunks. Long enough for the UI loop to actually service
    // input rather than being re-entered immediately, short enough that the
    // whole refresh still finishes in a few seconds.
    private static const CHUNK_DELAY_MS = 50;

    // Delay before the FIRST chunk, which also lets the initial layout and
    // draw pass complete before any scanning starts.
    private static const INITIAL_DELAY_MS = 50;

    // Timer.Timer is not retained by the system while it is pending, so the
    // instance holding it has to be kept alive somewhere that outlives the
    // getInitialView() stack frame or the callback never fires.
    private static var instance as RunningPaceForegroundRefresh?;

    private var timer as Timer.Timer?;
    private var reader as RunningActivityHistoryReader?;
    private var startedAtMs as Number = 0;
    private var now as Time.Moment?;

    static function schedule() as Void {
        var existing = instance;
        if (existing == null) {
            existing = new RunningPaceForegroundRefresh();
            instance = existing;
        }
        existing.start();
    }

    function initialize() {
    }

    function start() as Void {
        // A scan is already in flight - don't start a second one over the top
        // of it, which would double the work and discard the progress made.
        if (timer != null) {
            return;
        }

        // Captured once, up front: `now` anchors the trend window and must not
        // drift between chunks, and startedAtMs makes the recorded duration
        // cover the whole refresh rather than just its final tick.
        startedAtMs = System.getTimer();
        var capturedNow = Time.now();
        now = capturedNow;

        var newReader = new RunningActivityHistoryReader();
        reader = newReader;
        try {
            newReader.beginScan(RunningPaceRefresh.windowStartFor(capturedNow));
        } catch (exception instanceof Lang.Exception) {
            reader = null;
            now = null;
            return;
        }

        scheduleTick(INITIAL_DELAY_MS);
    }

    function onFire() as Void {
        timer = null;

        var currentReader = reader;
        var capturedNow = now;
        if (currentReader == null || capturedNow == null) {
            return;
        }

        var finished;
        try {
            finished = currentReader.scanChunk(CHUNK_SIZE);
        } catch (exception instanceof Lang.Exception) {
            // Abandon this refresh and leave the previously computed Storage
            // values in place, matching RunningPaceRefresh.run()'s behaviour on
            // a transient read failure - the next open tries again.
            reader = null;
            now = null;
            return;
        }

        if (!finished) {
            scheduleTick(CHUNK_DELAY_MS);
            return;
        }

        reader = null;
        now = null;

        RunningPaceRefresh.computeAndStore(currentReader, capturedNow, startedAtMs);
        WatchUi.requestUpdate();
    }

    private function scheduleTick(delayMs as Number) as Void {
        var pending = new Timer.Timer();
        timer = pending;
        pending.start(method(:onFire), delayMs, false);
    }

}
