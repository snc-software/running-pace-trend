import Toybox.Lang;
import Toybox.Test;

(:test)
function appendsFirstSnapshotToEmptyHistory(logger as Logger) as Boolean {
    var result = RunningPaceTrendHistory.recordSnapshot([] as Array<Dictionary>, 259200000, 400);

    Test.assertEqualMessage(result.size(), 1, "an empty history must gain exactly one snapshot");
    Test.assertEqualMessage(result[0]["date"], 259200000, "the snapshot must carry the given date");
    Test.assertEqualMessage(result[0]["secondsPerKm"], 400, "the snapshot must carry the given pace");
    return true;
}

(:test)
function appendsNewSnapshotWhenLastEntryIsADifferentDay(logger as Logger) as Boolean {
    var baseDate = 259200000;
    var existing = [
        { "date" => baseDate, "secondsPerKm" => 400 }
    ] as Array<Dictionary>;

    var result = RunningPaceTrendHistory.recordSnapshot(existing, baseDate + 86400, 390);

    Test.assertEqualMessage(result.size(), 2, "a new UTC day must append rather than overwrite");
    Test.assertEqualMessage(result[0]["date"], baseDate, "the original snapshot must be preserved");
    Test.assertEqualMessage(result[0]["secondsPerKm"], 400, "the original snapshot's pace must be preserved");
    Test.assertEqualMessage(result[1]["date"], baseDate + 86400, "the new snapshot must be appended after the original");
    Test.assertEqualMessage(result[1]["secondsPerKm"], 390, "the new snapshot must carry the given pace");
    return true;
}

(:test)
function overwritesLastEntryWhenSameUtcDay(logger as Logger) as Boolean {
    var baseDate = 259200000;
    var existing = [
        { "date" => baseDate, "secondsPerKm" => 400 }
    ] as Array<Dictionary>;

    var result = RunningPaceTrendHistory.recordSnapshot(existing, baseDate + 3600, 395);

    Test.assertEqualMessage(result.size(), 1, "a same-day recompute must overwrite, not duplicate");
    Test.assertEqualMessage(result[0]["date"], baseDate + 3600, "the overwritten snapshot must carry the latest date");
    Test.assertEqualMessage(result[0]["secondsPerKm"], 395, "the overwritten snapshot must carry the latest pace");
    return true;
}

(:test)
function treatsLastSecondOfDayAndNextDayStartAsDifferentDays(logger as Logger) as Boolean {
    var dayZeroLastSecond = 259200000 + 86399;
    var dayOneStart = 259200000 + 86400;
    var existing = [
        { "date" => dayZeroLastSecond, "secondsPerKm" => 400 }
    ] as Array<Dictionary>;

    var result = RunningPaceTrendHistory.recordSnapshot(existing, dayOneStart, 390);

    Test.assertEqualMessage(result.size(), 2, "23:59:59 and the next day's 00:00:00 must be treated as different days");
    Test.assertEqualMessage(result[1]["date"], dayOneStart, "the new day's snapshot must be appended");
    return true;
}

(:test)
function trimsOldestSnapshotsOnceMaxIsExceeded(logger as Logger) as Boolean {
    var baseDate = 259200000;
    var existing = [] as Array<Dictionary>;
    for (var i = 0; i < RunningPaceTrendHistory.MAX_SNAPSHOTS; i++) {
        existing.add({
            "date" => baseDate + (i * 86400),
            "secondsPerKm" => 400 + i
        });
    }

    var newDate = baseDate + (RunningPaceTrendHistory.MAX_SNAPSHOTS * 86400);
    var result = RunningPaceTrendHistory.recordSnapshot(existing, newDate, 999);

    Test.assertEqualMessage(result.size(), RunningPaceTrendHistory.MAX_SNAPSHOTS, "the list must stay capped at MAX_SNAPSHOTS once exceeded");
    Test.assertEqualMessage(result[0]["date"], baseDate + 86400, "the single oldest snapshot must be dropped first");
    Test.assertEqualMessage(result[result.size() - 1]["date"], newDate, "the newest snapshot must be the last entry");
    Test.assertEqualMessage(result[result.size() - 1]["secondsPerKm"], 999, "the newest snapshot's pace must be preserved");
    return true;
}

(:test)
function doesNotTrimWhenBelowMaxSnapshots(logger as Logger) as Boolean {
    var baseDate = 259200000;
    var existing = [
        { "date" => baseDate, "secondsPerKm" => 400 },
        { "date" => baseDate + 86400, "secondsPerKm" => 395 }
    ] as Array<Dictionary>;

    var result = RunningPaceTrendHistory.recordSnapshot(existing, baseDate + (2 * 86400), 390);

    Test.assertEqualMessage(result.size(), 3, "a list below the cap must simply grow by one for a new-day append");
    return true;
}
