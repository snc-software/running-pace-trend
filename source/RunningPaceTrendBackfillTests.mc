import Toybox.Activity;
import Toybox.Lang;
import Toybox.Test;
import Toybox.Time;

(:test)
function buildsNoSnapshotsWhenRecordsIsEmpty(logger as Logger) as Boolean {
    var now = new Time.Moment(100000000);
    var snapshots = RunningPaceTrendBackfill.buildSnapshots([] as Array<RunningActivityRecord>, now);

    Test.assertEqualMessage(snapshots.size(), 0, "no records must yield no backfilled snapshots, not an exception");
    return true;
}

(:test)
function omitsDaysWithoutQualifyingRuns(logger as Logger) as Boolean {
    var now = new Time.Moment(100000000);
    var todayStart = RunningPaceDayBoundary.startOfDay(now);
    var runTime = todayStart.subtract(new Time.Duration(3 * 86400)) as Time.Moment;
    var records = [
        new RunningActivityRecord(5000, 1500, runTime.value(), Activity.SPORT_RUNNING)
    ] as Array<RunningActivityRecord>;

    var snapshots = RunningPaceTrendBackfill.buildSnapshots(records, now);

    Test.assertEqualMessage(snapshots.size(), 2, "only the days whose trailing 30-day window actually reaches the single run must produce a snapshot, not all 30 backfillable days");
    Test.assertEqualMessage(snapshots[0]["date"], todayStart.subtract(new Time.Duration(2 * 86400)).value(), "the oldest produced snapshot must be the earliest day whose window reaches the run");
    Test.assertEqualMessage(snapshots[1]["date"], todayStart.subtract(new Time.Duration(1 * 86400)).value(), "the newest produced snapshot must be the day immediately before today");
    return true;
}

(:test)
function buildsSnapshotsInChronologicalOrderCoveringAllThirtyBackfillDays(logger as Logger) as Boolean {
    var now = new Time.Moment(100000000);
    var todayStart = RunningPaceDayBoundary.startOfDay(now);
    var records = [] as Array<RunningActivityRecord>;
    for (var i = 1; i <= 59; i++) {
        var runTime = todayStart.subtract(new Time.Duration(i * 86400)) as Time.Moment;
        records.add(new RunningActivityRecord(5000, 1800, runTime.value(), Activity.SPORT_RUNNING));
    }

    var snapshots = RunningPaceTrendBackfill.buildSnapshots(records, now);

    Test.assertEqualMessage(snapshots.size(), 30, "every one of the 30 backfillable days must produce a snapshot when runs cover the full lookback");
    Test.assertEqualMessage(snapshots[0]["date"], todayStart.subtract(new Time.Duration(30 * 86400)).value(), "the oldest backfilled day must be exactly 30 days before today");
    Test.assertEqualMessage(snapshots[snapshots.size() - 1]["date"], todayStart.subtract(new Time.Duration(1 * 86400)).value(), "the newest backfilled day must be exactly 1 day before today, not today itself");

    for (var j = 1; j < snapshots.size(); j++) {
        Test.assertMessage((snapshots[j]["date"] as Number) > (snapshots[j - 1]["date"] as Number), "each snapshot's date must be strictly later than the previous one (oldest first)");
    }
    return true;
}

(:test)
function excludesTodaysOwnCalendarDay(logger as Logger) as Boolean {
    var now = new Time.Moment(100000000);
    var todayStart = RunningPaceDayBoundary.startOfDay(now);
    var records = [] as Array<RunningActivityRecord>;
    for (var i = 0; i <= 59; i++) {
        var runTime = todayStart.subtract(new Time.Duration(i * 86400)) as Time.Moment;
        records.add(new RunningActivityRecord(5000, 1800, runTime.value(), Activity.SPORT_RUNNING));
    }
    records.add(new RunningActivityRecord(5000, 1800, now.value(), Activity.SPORT_RUNNING));

    var snapshots = RunningPaceTrendBackfill.buildSnapshots(records, now);

    for (var i = 0; i < snapshots.size(); i++) {
        Test.assertMessage((snapshots[i]["date"] as Number) != todayStart.value(), "today's own calendar day must never be produced by the backfill - it is recorded separately by the existing forward-recording code");
    }
    return true;
}

(:test)
function respectsSixtyDayLookbackBoundary(logger as Logger) as Boolean {
    var now = new Time.Moment(100000000);
    var todayStart = RunningPaceDayBoundary.startOfDay(now);
    var boundaryTime = todayStart.subtract(new Time.Duration(60 * 86400)) as Time.Moment;
    var records = [
        new RunningActivityRecord(5000, 1800, boundaryTime.value(), Activity.SPORT_RUNNING)
    ] as Array<RunningActivityRecord>;

    var snapshots = RunningPaceTrendBackfill.buildSnapshots(records, now);

    Test.assertEqualMessage(snapshots.size(), 1, "a run exactly at the 60-day lookback boundary must contribute to exactly the earliest backfillable day's window");
    Test.assertEqualMessage(snapshots[0]["date"], todayStart.subtract(new Time.Duration(30 * 86400)).value(), "the produced snapshot must be the earliest backfilled day (window spans today-60 to today-30)");
    return true;
}

(:test)
function excludesRunJustOutsideSixtyDayLookbackBoundary(logger as Logger) as Boolean {
    var now = new Time.Moment(100000000);
    var todayStart = RunningPaceDayBoundary.startOfDay(now);
    var justOutsideTime = todayStart.subtract(new Time.Duration(60 * 86400)).value() - 1;
    var records = [
        new RunningActivityRecord(5000, 1800, justOutsideTime, Activity.SPORT_RUNNING)
    ] as Array<RunningActivityRecord>;

    var snapshots = RunningPaceTrendBackfill.buildSnapshots(records, now);

    Test.assertEqualMessage(snapshots.size(), 0, "a run one second outside the 60-day lookback boundary must not contribute to any backfilled day");
    return true;
}

(:test)
function computesEachDaysPaceAsADistanceWeightedAverageMatchingRunningPaceCalculator(logger as Logger) as Boolean {
    var now = new Time.Moment(100000000);
    var todayStart = RunningPaceDayBoundary.startOfDay(now);
    var runOne = todayStart.subtract(new Time.Duration(35 * 86400)) as Time.Moment;
    var runTwo = todayStart.subtract(new Time.Duration(20 * 86400)) as Time.Moment;
    var records = [
        new RunningActivityRecord(1000, 462, runOne.value(), Activity.SPORT_RUNNING),
        new RunningActivityRecord(1000, 473, runTwo.value(), Activity.SPORT_RUNNING)
    ] as Array<RunningActivityRecord>;

    var snapshots = RunningPaceTrendBackfill.buildSnapshots(records, now);

    var targetDate = todayStart.subtract(new Time.Duration(10 * 86400)).value();
    var found = false;
    for (var i = 0; i < snapshots.size(); i++) {
        if (snapshots[i]["date"] == targetDate) {
            found = true;
            Test.assertEqualMessage(snapshots[i]["secondsPerKm"], 468, "the backfilled day's pace must be the same distance-weighted average RunningPaceCalculator itself would compute for the identical window: (462+473)*1000 rounded over 2000m = 468");
        }
    }
    Test.assertMessage(found, "a snapshot must be produced for the day whose window contains both runs");
    return true;
}
