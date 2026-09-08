import Toybox.Lang;
import Toybox.Time;
import Toybox.UserProfile;

// Wraps UserProfile.getUserActivityHistory(), which has a documented type of
// UserActivityHistoryIterator but is confirmed to sometimes return null instead
// (see RESEARCH.md). Maps each UserActivity into a plain RunningActivityRecord so
// downstream logic never touches the Garmin API types directly.
class RunningActivityHistoryReader {

    function initialize() {
    }

    // `windowStart` bounds how far back retained records go: an activity with
    // a known startTime older than windowStart is skipped entirely rather
    // than allocated into the returned array. This bounds the returned
    // *array's* size, but NOT the iteration cost - the iterator's order is
    // undocumented (RESEARCH.md), so a `startTime` older than windowStart
    // cannot be trusted to mean "everything after this is also too old,"
    // and every entry in the device's entire on-device history still has to
    // be visited to find out.
    //
    // MAX_ACTIVITIES_SCANNED (#47) is a hard backstop on that iteration cost.
    // getUserActivityHistory()'s total depth is undocumented and this reader
    // was found scanning the watch's whole lifetime activity log every call
    // with no upper bound - fine on a fresh device, but on one with months of
    // real history this grows slower over time and was suspected (via an
    // on-device crash log correlating with "the app taking a while to open")
    // of eventually exhausting memory or a time budget and aborting the
    // process outright, a failure mode that never reproduces in the
    // simulator since it never has real device history to hit. Because order
    // is undocumented, stopping at this cap cannot guarantee every activity
    // inside the window was found if a device's total history is genuinely
    // larger than this - but that only risks slightly under-counting a
    // rolling 30/60-day window, versus this method's prior behaviour of
    // scanning without limit at all. TOTAL_LOOKBACK_DAYS is 60 days; even a
    // generous 10 tracked activities of any sport per day over that window is
    // 600, so this stays well clear of any realistic in-window count while
    // still bounding worst-case lifetime-history cost.
    private const MAX_ACTIVITIES_SCANNED = 2000;

    function readAll(windowStart as Time.Moment) as Array<RunningActivityRecord> {
        var records = [] as Array<RunningActivityRecord>;

        var iterator = UserProfile.getUserActivityHistory();
        if (iterator == null) {
            return records;
        }

        var scanned = 0;
        var activity = iterator.next();
        while (activity != null && scanned < MAX_ACTIVITIES_SCANNED) {
            scanned++;

            var duration = activity.duration;
            var durationSeconds = null;
            if (duration != null) {
                durationSeconds = duration.value();
            }

            var startTime = activity.startTime;
            var startTimeEpoch = null;
            if (startTime != null) {
                startTimeEpoch = startTime.value();
                if (startTime.lessThan(windowStart)) {
                    activity = iterator.next();
                    continue;
                }
            }

            records.add(new RunningActivityRecord(
                activity.distance,
                durationSeconds,
                startTimeEpoch,
                activity.type
            ));
            activity = iterator.next();
        }

        return records;
    }

}
