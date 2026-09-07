import Toybox.Application;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

// The trend graph screen - screen 1, the app's initial view (#29), reachable
// from running_pace_trendView (screen 2) via RunningPaceTrendNavigationDelegate's
// up/down paging. Renders from Application.Storage only, mirroring the rest
// of this app's views - no pace calculation here, only
// RunningPaceTrendGraphContent's pure point-mapping.
class RunningPaceTrendGraphView extends WatchUi.View {

    function initialize() {
        View.initialize();
    }

    function onUpdate(dc as Dc) as Void {
        // clear() erases using the background color (Dc.html), so it must be
        // opaque here - COLOR_TRANSPARENT would leave running_pace_trendView's
        // last frame showing through underneath this screen.
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);

        var width = dc.getWidth();
        var height = dc.getHeight();
        var centerX = width / 2;

        // Page-indicator dots (#29) - Connect IQ has no built-in page
        // indicator, so this is hand-drawn on the left edge, mirroring the
        // native Training Status widget.
        var dotX = (width * 0.08).toNumber();
        var dotCenterY = height / 2;
        var dotOffsets = RunningPaceTrendPageIndicatorContent.buildDotCenterYOffsets();
        for (var i = 0; i < dotOffsets.size(); i++) {
            var dotY = dotCenterY + dotOffsets[i];
            if (i == RUNNING_PACE_TREND_PAGE_GRAPH) {
                dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
                dc.fillCircle(dotX, dotY, RunningPaceTrendPageIndicatorContent.ACTIVE_DOT_RADIUS);
            } else {
                dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
                dc.drawCircle(dotX, dotY, RunningPaceTrendPageIndicatorContent.INACTIVE_DOT_RADIUS);
            }
        }
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);

        var title = WatchUi.loadResource(Rez.Strings.RunningTrendGraphTitle) as String;
        dc.drawText(centerX, height * 0.08, Graphics.FONT_XTINY, title, Graphics.TEXT_JUSTIFY_CENTER);

        var snapshots = Application.Storage.getValue("runningPaceTrendSnapshots") as Array<Dictionary>?;
        var state = RunningPaceTrendGraphContent.resolveState(snapshots);

        if (state == RUNNING_PACE_TREND_GRAPH_STATE_NO_DATA) {
            var noDataMessage = WatchUi.loadResource(Rez.Strings.RunningTrendGraphInsufficientData) as String;
            dc.drawText(centerX, height * 0.5, Graphics.FONT_TINY, noDataMessage, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            return;
        }

        if (state == RUNNING_PACE_TREND_GRAPH_STATE_INSUFFICIENT_HISTORY) {
            var insufficientHistoryMessage = WatchUi.loadResource(Rez.Strings.RunningTrendGraphInsufficientHistory) as String;
            dc.drawText(centerX, height * 0.5, Graphics.FONT_TINY, insufficientHistoryMessage, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            return;
        }

        // Trend direction/color drive the delta arrow, line, and area fill
        // below (#29 VO2max-style redesign) so the whole screen reads as one
        // consistent signal. Reuses the same runningPaceTrendDirection
        // RunningPaceBackgroundService already computes and
        // running-pace-trendView already displays as text, so the two
        // screens always agree. Falls back to white/light-gray
        // (RunningPaceTrendColor's own defaults) when that comparison hasn't
        // got enough data yet, even though the graph itself has enough
        // snapshots to draw a line.
        var trendDirection = Application.Storage.getValue("runningPaceTrendDirection") as Number?;
        var trendColor = RunningPaceTrendColor.forDirection(trendDirection);

        var paceUnit = WatchUi.loadResource(Rez.Strings.RunningTrendDetailUnit) as String;

        // Current-pace row (#29 redesign, feedback round 2): the number
        // itself stays in the system's normal white text color (not trend
        // colored) and at a more modest FONT_NUMBER_MILD size - FONT_NUMBER_
        // MEDIUM measured too wide once the "/km" unit was appended,
        // overflowing past the visible circular area. Skipped (not blanked
        // with a fallback message) when there isn't yet a current pace to
        // show - a rare edge case in practice, since the graph itself
        // already requires RUNNING_PACE_TREND_GRAPH_STATE_READY (>= 2
        // snapshots) to reach this point, and the background service
        // populates both the current pace and the snapshot history together.
        var hasSufficientData = Application.Storage.getValue("runningPaceHasSufficientData") as Boolean?;
        var currentSecondsPerKm = Application.Storage.getValue("runningPaceSecondsPerKm") as Number?;
        var currentPaceY = height * 0.20;
        var deltaRowY = height * 0.32;
        if (hasSufficientData == true && currentSecondsPerKm != null) {
            var numberText = RunningPaceFormatter.format(currentSecondsPerKm);

            var numberWidth = dc.getTextWidthInPixels(numberText, Graphics.FONT_NUMBER_MILD);
            var unitWidth = dc.getTextWidthInPixels(paceUnit, Graphics.FONT_XTINY);
            var paceGroupGap = 2;
            var paceGroupLeft = centerX - ((numberWidth + paceGroupGap + unitWidth) / 2);

            dc.drawText(paceGroupLeft, currentPaceY, Graphics.FONT_NUMBER_MILD, numberText, Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
            dc.drawText(paceGroupLeft + numberWidth + paceGroupGap, currentPaceY, Graphics.FONT_XTINY, paceUnit, Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);

            // Arrow + delta row below the pace (#29 redesign, feedback round
            // 2), e.g. "→ 0s/km" / "↑ 11s/km" - only the arrow is trend
            // colored, matching the request that the number/delta text stay
            // in the system's normal text color and only the arrow itself
            // carry the green/red/blue signal. FONT_XTINY is used here
            // (rather than FONT_MEDIUM, tried in the previous pass) because
            // it's the font size already proven in this codebase to render
            // the arrow glyphs correctly (RunningPaceGlanceView) - a larger
            // font substituted a missing-glyph placeholder for the arrow.
            var deltaSecondsPerKm = Application.Storage.getValue("runningPaceTrendDeltaSecondsPerKm") as Number?;
            if (deltaSecondsPerKm != null) {
                var arrowText = RunningPaceTrendFormatter.arrowFor(trendDirection);
                var deltaUnit = WatchUi.loadResource(Rez.Strings.RunningTrendGraphDeltaUnit) as String;
                var deltaText = deltaSecondsPerKm.toString() + deltaUnit;

                var arrowWidth = dc.getTextWidthInPixels(arrowText, Graphics.FONT_XTINY);
                var deltaWidth = dc.getTextWidthInPixels(deltaText, Graphics.FONT_XTINY);
                var deltaGroupGap = 4;
                var deltaGroupLeft = centerX - ((arrowWidth + deltaGroupGap + deltaWidth) / 2);

                dc.setColor(trendColor, Graphics.COLOR_TRANSPARENT);
                dc.drawText(deltaGroupLeft, deltaRowY, Graphics.FONT_XTINY, arrowText, Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
                dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
                dc.drawText(deltaGroupLeft + arrowWidth + deltaGroupGap, deltaRowY, Graphics.FONT_XTINY, deltaText, Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
            }
        }

        // Plot area sits below the current-pace/delta rows, sized to leave
        // room for those above and the period caption below (#29 redesign).
        // plotWidth is narrower than the original single-purpose layout's
        // (feedback round 2, point 4): the Y-axis pace labels sit to the
        // right of the plot at paceLabelRightEdge below, and the previous
        // wider plot left too little horizontal gap before that edge, so an
        // 8-character label like "19:59/km" overlapped the plotted line/
        // fill instead of sitting clearly beside it.
        var plotLeft = (width * 0.14).toNumber();
        var plotTop = (height * 0.44).toNumber();
        var plotWidth = (width * 0.46).toNumber();
        var plotHeight = (height * 0.26).toNumber();
        var plotBaselineY = plotTop + plotHeight;

        var graphData = RunningPaceTrendGraphContent.buildGraphData(snapshots as Array<Dictionary>, plotLeft, plotTop, plotWidth, plotHeight);
        var points = graphData["points"] as Array<Dictionary>;

        // Gridlines at the plot's top (fastest) and bottom (slowest) edges,
        // VO2max-style, rather than just a bounding box - the axis itself
        // now doubles as the reference line each Y-axis label sits on.
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(plotLeft, plotTop, plotLeft + plotWidth, plotTop);
        dc.drawLine(plotLeft, plotBaselineY, plotLeft + plotWidth, plotBaselineY);

        // Area-under-the-line fill (#29 redesign, feedback round 2, point 3):
        // a lighter tint of the same trend color, closed down to the plot's
        // baseline. Drawn before the line stroke so the solid trend-colored
        // line renders crisply on top of its own shaded area.
        var areaPoints = [] as Array<Graphics.Point2D>;
        for (var p = 0; p < points.size(); p++) {
            var point = points[p] as Dictionary;
            areaPoints.add([point["x"] as Number, point["y"] as Number]);
        }
        areaPoints.add([(points[points.size() - 1] as Dictionary)["x"] as Number, plotBaselineY]);
        areaPoints.add([(points[0] as Dictionary)["x"] as Number, plotBaselineY]);

        var lightTrendColor = RunningPaceTrendColor.lightForDirection(trendDirection);
        dc.setColor(lightTrendColor, lightTrendColor);
        dc.fillPolygon(areaPoints);

        dc.setColor(trendColor, Graphics.COLOR_TRANSPARENT);
        for (var i = 0; i < points.size() - 1; i++) {
            var from = points[i] as Dictionary;
            var to = points[i + 1] as Dictionary;
            dc.drawLine(from["x"] as Number, from["y"] as Number, to["x"] as Number, to["y"] as Number);
        }
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);

        // Safe right edge for the Y-axis pace labels (#29 fix for the
        // round-bezel clipping seen in practice, same class of bug as #28):
        // TEXT_JUSTIFY_RIGHT anchors a label's right edge here and grows it
        // leftward, so its length can no longer push it past the visible
        // circular area regardless of how wide the formatted pace text is.
        // Combined with the narrower plotWidth above, this also keeps the
        // label clear of the plot itself rather than overlapping it.
        var paceLabelRightEdge = (width * 0.88).toNumber();

        var fastestText = RunningPaceFormatter.format(graphData["minSecondsPerKm"] as Number) + paceUnit;
        dc.drawText(paceLabelRightEdge, plotTop, Graphics.FONT_XTINY, fastestText, Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER);

        var slowestText = RunningPaceFormatter.format(graphData["maxSecondsPerKm"] as Number) + paceUnit;
        dc.drawText(paceLabelRightEdge, plotBaselineY, Graphics.FONT_XTINY, slowestText, Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER);

        // Single centered period caption (#29 redesign) replacing the
        // previous two corner labels, e.g. "Last 60 days" - built from
        // graphData's own daySpanDays so it always names the actual span
        // being plotted rather than a hardcoded lookback window.
        var periodCaptionTemplate = WatchUi.loadResource(Rez.Strings.RunningTrendGraphPeriodCaption) as String;
        var periodCaption = Lang.format(periodCaptionTemplate, [graphData["daySpanDays"] as Number]);
        dc.drawText(centerX, height * 0.80, Graphics.FONT_XTINY, periodCaption, Graphics.TEXT_JUSTIFY_CENTER);
    }

}
