import Toybox.Activity;
import Toybox.Lang;

// Plain, test-constructible DTO mirroring the fields of UserProfile.UserActivity
// that this feature needs. UserActivity itself has no public constructor, so
// tests build RunningActivityRecord instances directly instead.
class RunningActivityRecord {

    public var distanceMeters as Number?;
    public var durationSeconds as Number?;
    public var startTimeEpoch as Number?;
    public var sport as Activity.Sport?;

    function initialize(
        setDistanceMeters as Number?,
        setDurationSeconds as Number?,
        setStartTimeEpoch as Number?,
        setSport as Activity.Sport?
    ) {
        distanceMeters = setDistanceMeters;
        durationSeconds = setDurationSeconds;
        startTimeEpoch = setStartTimeEpoch;
        sport = setSport;
    }

}
