import Toybox.Lang;
import Toybox.UserProfile;

// Wraps UserProfile.getUserActivityHistory(), which has a documented type of
// UserActivityHistoryIterator but is confirmed to sometimes return null instead
// (see RESEARCH.md). Maps each UserActivity into a plain RunningActivityRecord so
// downstream logic never touches the Garmin API types directly.
class RunningActivityHistoryReader {

    function initialize() {
    }

    function readAll() as Array<RunningActivityRecord> {
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
