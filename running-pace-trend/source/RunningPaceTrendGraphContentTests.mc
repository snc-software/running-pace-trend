import Toybox.Lang;
import Toybox.Test;

(:test)
function resolvesNoDataWhenSnapshotsIsNull(logger as Logger) as Boolean {
    Test.assertEqualMessage(RunningPaceTrendGraphContent.resolveState(null), RUNNING_PACE_TREND_GRAPH_STATE_NO_DATA, "null snapshots must resolve to no-data");
    return true;
}

(:test)
function resolvesNoDataWhenSnapshotsIsEmpty(logger as Logger) as Boolean {
    Test.assertEqualMessage(RunningPaceTrendGraphContent.resolveState([] as Array<Dictionary>), RUNNING_PACE_TREND_GRAPH_STATE_NO_DATA, "an empty history must resolve to no-data");
    return true;
}

(:test)
function resolvesInsufficientHistoryWithExactlyOneSnapshot(logger as Logger) as Boolean {
    var snapshots = [
        { "date" => 259200000, "secondsPerKm" => 400 }
    ] as Array<Dictionary>;

    Test.assertEqualMessage(RunningPaceTrendGraphContent.resolveState(snapshots), RUNNING_PACE_TREND_GRAPH_STATE_INSUFFICIENT_HISTORY, "a single snapshot cannot form a line and must resolve to insufficient history");
    return true;
}

(:test)
function resolvesReadyWithExactlyTwoSnapshots(logger as Logger) as Boolean {
    var snapshots = [
        { "date" => 259200000, "secondsPerKm" => 400 },
        { "date" => 259200000 + 86400, "secondsPerKm" => 390 }
    ] as Array<Dictionary>;

    Test.assertEqualMessage(RunningPaceTrendGraphContent.resolveState(snapshots), RUNNING_PACE_TREND_GRAPH_STATE_READY, "two snapshots is the minimum valid graph");
    return true;
}

(:test)
function resolvesReadyWithManySnapshots(logger as Logger) as Boolean {
    var snapshots = [] as Array<Dictionary>;
    var baseDate = 259200000;
    for (var i = 0; i < 180; i++) {
        snapshots.add({ "date" => baseDate + (i * 86400), "secondsPerKm" => 400 - i });
    }

    Test.assertEqualMessage(RunningPaceTrendGraphContent.resolveState(snapshots), RUNNING_PACE_TREND_GRAPH_STATE_READY, "a full history must resolve to ready");
    return true;
}

(:test)
function mapsFirstSnapshotToLeftEdgeAndLastToRightEdge(logger as Logger) as Boolean {
    var baseDate = 259200000;
    var snapshots = [
        { "date" => baseDate, "secondsPerKm" => 400 },
        { "date" => baseDate + 86400, "secondsPerKm" => 390 },
        { "date" => baseDate + (2 * 86400), "secondsPerKm" => 380 }
    ] as Array<Dictionary>;

    var graphData = RunningPaceTrendGraphContent.buildGraphData(snapshots, 10, 20, 100, 50);
    var points = graphData["points"] as Array<Dictionary>;

    Test.assertEqualMessage(points.size(), 3, "one point must be produced per snapshot");
    Test.assertEqualMessage(points[0]["x"], 10, "the oldest snapshot must map to the plot's left edge");
    Test.assertEqualMessage(points[2]["x"], 110, "the newest snapshot must map to the plot's right edge");
    return true;
}

(:test)
function mapsFasterPaceToSmallerYThanSlowerPace(logger as Logger) as Boolean {
    var baseDate = 259200000;
    var snapshots = [
        { "date" => baseDate, "secondsPerKm" => 420 },
        { "date" => baseDate + 86400, "secondsPerKm" => 390 },
        { "date" => baseDate + (2 * 86400), "secondsPerKm" => 360 }
    ] as Array<Dictionary>;

    var graphData = RunningPaceTrendGraphContent.buildGraphData(snapshots, 0, 0, 100, 100);
    var points = graphData["points"] as Array<Dictionary>;

    Test.assertMessage((points[2]["y"] as Number) < (points[1]["y"] as Number), "a faster later point must render above (smaller y than) an earlier, slower point");
    Test.assertMessage((points[1]["y"] as Number) < (points[0]["y"] as Number), "each successively faster point must render higher than the previous one");
    Test.assertEqualMessage(graphData["minSecondsPerKm"], 360, "the fastest pace in the series must be reported as the minimum");
    Test.assertEqualMessage(graphData["maxSecondsPerKm"], 420, "the slowest pace in the series must be reported as the maximum");
    return true;
}

(:test)
function mapsDeterioratingSeriesConsistently(logger as Logger) as Boolean {
    var baseDate = 259200000;
    var snapshots = [
        { "date" => baseDate, "secondsPerKm" => 360 },
        { "date" => baseDate + 86400, "secondsPerKm" => 390 },
        { "date" => baseDate + (2 * 86400), "secondsPerKm" => 420 }
    ] as Array<Dictionary>;

    var graphData = RunningPaceTrendGraphContent.buildGraphData(snapshots, 0, 0, 100, 100);
    var points = graphData["points"] as Array<Dictionary>;

    Test.assertMessage((points[2]["y"] as Number) > (points[0]["y"] as Number), "a slower later point must render below (larger y than) an earlier, faster point");
    return true;
}

(:test)
function handlesAllIdenticalPaceValuesWithoutDivideByZero(logger as Logger) as Boolean {
    var baseDate = 259200000;
    var snapshots = [
        { "date" => baseDate, "secondsPerKm" => 400 },
        { "date" => baseDate + 86400, "secondsPerKm" => 400 },
        { "date" => baseDate + (2 * 86400), "secondsPerKm" => 400 }
    ] as Array<Dictionary>;

    var graphData = RunningPaceTrendGraphContent.buildGraphData(snapshots, 0, 20, 100, 60);
    var points = graphData["points"] as Array<Dictionary>;

    for (var i = 0; i < points.size(); i++) {
        Test.assertEqualMessage(points[i]["y"], 50, "a flat-line series (identical pace values) must place every point at the plot's vertical midpoint");
    }
    return true;
}

(:test)
function reportsDaySpanAcrossTheFullSnapshotRange(logger as Logger) as Boolean {
    var baseDate = 259200000;
    var snapshots = [
        { "date" => baseDate, "secondsPerKm" => 400 },
        { "date" => baseDate + (10 * 86400), "secondsPerKm" => 390 }
    ] as Array<Dictionary>;

    var graphData = RunningPaceTrendGraphContent.buildGraphData(snapshots, 0, 0, 100, 100);

    Test.assertEqualMessage(graphData["daySpanDays"], 10, "the day span must cover the full range from the oldest to the newest snapshot");
    return true;
}
