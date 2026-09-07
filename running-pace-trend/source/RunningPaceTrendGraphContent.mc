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

    // Keeps plotted points visually distinct on the plot's actual pixel width
    // (US-10 / #15) rather than plotting one point per snapshot regardless of
    // how many pixels are available.
    private static const MIN_PIXEL_SPACING_PER_POINT = 4;

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
    // left (oldest) to right (newest) along x. Along y, the fastest snapshot
    // is placed nearest plotTop and the slowest nearest plotTop + plotHeight,
    // so an improving trend (pace getting lower over time) reads as an
    // upward-moving line on screen.
    //
    // Two readability passes happen before mapping (US-10 / #15):
    // - `snapshots` is downsampled to at most as many points as plotWidth can
    //   visually distinguish, so a long history doesn't overplot the screen.
    // - the y-scale is a percentile clamp of the (downsampled) pace values
    //   rather than their literal min/max, so a single extreme outlier can't
    //   flatten the rest of the line. The returned "minSecondsPerKm"/
    //   "maxSecondsPerKm" are that same clamped bound, so any label drawn
    //   from them always matches what the plot edges actually represent.
    static function buildGraphData(snapshots as Array<Dictionary>, plotLeft as Number, plotTop as Number, plotWidth as Number, plotHeight as Number) as Dictionary {
        var firstDate = snapshots[0]["date"] as Number;
        var lastDate = snapshots[snapshots.size() - 1]["date"] as Number;
        var daySpanDays = (lastDate - firstDate) / SECONDS_PER_DAY;

        var displaySnapshots = downsample(snapshots, plotWidth);
        var lastIndex = displaySnapshots.size() - 1;

        var paces = [] as Array<Number>;
        for (var i = 0; i <= lastIndex; i++) {
            paces.add(displaySnapshots[i]["secondsPerKm"] as Number);
        }

        var bounds = computeClampedBounds(paces);
        var lowerBound = bounds[0];
        var upperBound = bounds[1];
        var paceRange = upperBound - lowerBound;

        var points = [] as Array<Dictionary>;
        for (var i = 0; i <= lastIndex; i++) {
            var pace = paces[i];
            if (pace < lowerBound) {
                pace = lowerBound;
            } else if (pace > upperBound) {
                pace = upperBound;
            }

            var x = plotLeft + (plotWidth * i) / lastIndex;

            var y;
            if (paceRange == 0) {
                y = plotTop + (plotHeight / 2);
            } else {
                y = plotTop + (plotHeight * (pace - lowerBound)) / paceRange;
            }

            points.add({ "x" => x, "y" => y });
        }

        return {
            "points" => points,
            "minSecondsPerKm" => lowerBound,
            "maxSecondsPerKm" => upperBound,
            "daySpanDays" => daySpanDays
        };
    }

    // Reduces `snapshots` to at most one point per MIN_PIXEL_SPACING_PER_POINT
    // pixels of `plotWidth`, bucketing snapshots into that many contiguous,
    // roughly-equal-sized, chronologically-ordered groups and representing
    // each bucket by the integer average of its secondsPerKm values, dated at
    // the bucket's most recent snapshot. Returns `snapshots` unchanged when it
    // already fits within the available pixel width.
    private static function downsample(snapshots as Array<Dictionary>, plotWidth as Number) as Array<Dictionary> {
        var n = snapshots.size();
        var maxPoints = plotWidth / MIN_PIXEL_SPACING_PER_POINT;
        if (maxPoints < MIN_POINTS_FOR_GRAPH) {
            maxPoints = MIN_POINTS_FOR_GRAPH;
        }

        if (n <= maxPoints) {
            return snapshots;
        }

        var buckets = [] as Array<Dictionary>;
        for (var b = 0; b < maxPoints; b++) {
            var startIndex = (b * n) / maxPoints;
            var endIndex = ((b + 1) * n) / maxPoints - 1;
            if (b == maxPoints - 1) {
                endIndex = n - 1;
            }

            var paceTotal = 0;
            for (var i = startIndex; i <= endIndex; i++) {
                paceTotal += snapshots[i]["secondsPerKm"] as Number;
            }
            var bucketSize = endIndex - startIndex + 1;

            buckets.add({
                "date" => snapshots[endIndex]["date"] as Number,
                "secondsPerKm" => paceTotal / bucketSize
            });
        }

        return buckets;
    }

    // Returns [lowerBound, upperBound] for `paces`, clamping the extreme 10%
    // of values at each end once there are enough points for that to be
    // meaningful. `marginCount` evaluates to 0 for small n (today's existing
    // 2-3 point behaviour: exact literal min/max, unchanged), and only starts
    // excluding outliers once n is large enough (US-10 / #15) for percentile
    // clipping to be statistically meaningful rather than clipping genuine
    // variation away.
    private static function computeClampedBounds(paces as Array<Number>) as Array<Number> {
        var sorted = paces.slice(0, paces.size()) as Array<Number>;
        sorted.sort(null);

        var n = sorted.size();
        var marginCount = ((n - 1) * 10) / 100;

        return [sorted[marginCount], sorted[(n - 1) - marginCount]];
    }

}
