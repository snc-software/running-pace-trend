import Toybox.Lang;

enum {
    RUNNING_PACE_TREND_GRAPH_STATE_NO_DATA,
    RUNNING_PACE_TREND_GRAPH_STATE_INSUFFICIENT_HISTORY,
    RUNNING_PACE_TREND_GRAPH_STATE_READY
}

// Pure state-selection and point-mapping logic for the trend graph screen,
// decoupled from Dc/Storage/Rez so it can be unit tested without a device
// (coding-standards.md Testing section). Operates on the same
// runningPaceTrendSnapshots history RunningPaceTrendHistory maintains (#22) -
// this class performs no pace calculation of its own, only mapping for
// display (US-07 / #12).
class RunningPaceTrendGraphContent {

    // A single snapshot cannot form a line, so at least two are required
    // before the graph is considered ready to draw.
    static const MIN_POINTS_FOR_GRAPH = 2;

    private static const SECONDS_PER_DAY = 86400;

    static function resolveState(snapshots as Array<Dictionary>?) as Number {
        if (snapshots == null || snapshots.size() == 0) {
            return RUNNING_PACE_TREND_GRAPH_STATE_NO_DATA;
        }

        if (snapshots.size() < MIN_POINTS_FOR_GRAPH) {
            return RUNNING_PACE_TREND_GRAPH_STATE_INSUFFICIENT_HISTORY;
        }

        return RUNNING_PACE_TREND_GRAPH_STATE_READY;
    }

    // Maps `snapshots` (assumed to already satisfy
    // RUNNING_PACE_TREND_GRAPH_STATE_READY, i.e. at least MIN_POINTS_FOR_GRAPH
    // entries) onto integer pixel points within the rectangle described by
    // (plotLeft, plotTop, plotWidth, plotHeight). Snapshots are spread evenly
    // left (oldest) to right (newest) along x. Along y, the fastest (lowest
    // secondsPerKm) snapshot is placed nearest plotTop and the slowest
    // nearest plotTop + plotHeight, so an improving trend (pace getting lower
    // over time) reads as an upward-moving line on screen.
    static function buildGraphData(snapshots as Array<Dictionary>, plotLeft as Number, plotTop as Number, plotWidth as Number, plotHeight as Number) as Dictionary {
        var minSecondsPerKm = snapshots[0]["secondsPerKm"] as Number;
        var maxSecondsPerKm = minSecondsPerKm;

        for (var i = 1; i < snapshots.size(); i++) {
            var pace = snapshots[i]["secondsPerKm"] as Number;
            if (pace < minSecondsPerKm) {
                minSecondsPerKm = pace;
            }
            if (pace > maxSecondsPerKm) {
                maxSecondsPerKm = pace;
            }
        }

        var paceRange = maxSecondsPerKm - minSecondsPerKm;
        var lastIndex = snapshots.size() - 1;

        var points = [] as Array<Dictionary>;
        for (var i = 0; i <= lastIndex; i++) {
            var pace = snapshots[i]["secondsPerKm"] as Number;
            var x = plotLeft + (plotWidth * i) / lastIndex;

            var y;
            if (paceRange == 0) {
                y = plotTop + (plotHeight / 2);
            } else {
                y = plotTop + (plotHeight * (pace - minSecondsPerKm)) / paceRange;
            }

            points.add({ "x" => x, "y" => y });
        }

        var firstDate = snapshots[0]["date"] as Number;
        var lastDate = snapshots[lastIndex]["date"] as Number;
        var daySpanDays = (lastDate - firstDate) / SECONDS_PER_DAY;

        return {
            "points" => points,
            "minSecondsPerKm" => minSecondsPerKm,
            "maxSecondsPerKm" => maxSecondsPerKm,
            "daySpanDays" => daySpanDays
        };
    }

}
