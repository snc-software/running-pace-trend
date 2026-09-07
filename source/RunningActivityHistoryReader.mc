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
    // than allocated into the returned array, since no calculation in this
    // app ever reads further back than RunningPaceTrendCalculator's own
    // TOTAL_LOOKBACK_DAYS (US-11 / #16) - this keeps memory/processing cost
    // bounded by recent activity volume rather than the device's whole
    // lifetime history. The iterator's order is undocumented (RESEARCH.md),
    // so this cannot early-exit, only skip retaining what it already knows is
    // irrelevant. An activity with a null startTime is still recorded
    // unchanged - RunningPaceCalculator.calculateForWindow already skips it
    // downstream.
    function readAll(windowStart as Time.Moment) as Array<RunningActivityRecord> {
        var records = [] as Array<RunningActivityRecord>;

        var iterator = UserProfile.getUserActivityHistory();
        if (iterator == null) {
            return records;
        }

        var activity = iterator.next();
        while (activity != null) {
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
