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

        // Current-pace row (#29 redesign, feedback round 3): FONT_LARGE - a
        // regular system font, not a numeric font - both to read slightly
        // smaller (point 3) and to sit further from the title above it
        // (point 1); FONT_NUMBER_MILD (used in the previous pass) was tall
        // enough to crowd "PACE TREND" directly above it. Digits/colon
        // render fine in any system font, so there's no glyph-coverage risk
        // here the way there is with the arrow below. Skipped (not blanked
        // with a fallback message) when there isn't yet a current pace to
        // show - a rare edge case in practice, since the graph itself
        // already requires RUNNING_PACE_TREND_GRAPH_STATE_READY (>= 2
        // snapshots) to reach this point, and the background service
        // populates both the current pace and the snapshot history together.
        var hasSufficientData = Application.Storage.getValue("runningPaceHasSufficientData") as Boolean?;
        var currentSecondsPerKm = Application.Storage.getValue("runningPaceSecondsPerKm") as Number?;
        var currentPaceY = height * 0.24;
        var deltaRowY = height * 0.35;
        if (hasSufficientData == true && currentSecondsPerKm != null) {
            var numberText = RunningPaceFormatter.format(currentSecondsPerKm);
            var numberFont = Graphics.FONT_LARGE;

            var numberWidth = dc.getTextWidthInPixels(numberText, numberFont);
            var unitWidth = dc.getTextWidthInPixels(paceUnit, Graphics.FONT_XTINY);
            var paceGroupGap = 2;
            var paceGroupLeft = centerX - ((numberWidth + paceGroupGap + unitWidth) / 2);

            dc.drawText(paceGroupLeft, currentPaceY, numberFont, numberText, Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);

            // Unit's baseline aligned to the number's own baseline (feedback
            // round 4, point 1) - a unit should read like it's sitting on
            // the same line as the value it qualifies, e.g. "5:11/km" in
            // print. The previous pass aligned to the number's full
            // bounding-box bottom instead, which sat visibly lower than the
            // true baseline (the box reserves descender space digits never
            // use), making "/km" look detached/misaligned. Font metrics
            // (ascent/descent), not raw bounding-box height, are what let
            // this be computed correctly: with the number VCENTER'd at
            // currentPaceY, its box top is centerY - height/2, and its
            // baseline sits "ascent" pixels below that top; the unit is then
            // placed so its own baseline (ascent pixels below its top) lands
            // on that same y.
            var numberHeight = Graphics.getFontHeight(numberFont);
            var numberAscent = Graphics.getFontAscent(numberFont);
            var numberBaselineY = currentPaceY - (numberHeight / 2) + numberAscent;
            var unitAscent = Graphics.getFontAscent(Graphics.FONT_XTINY);
            dc.drawText(paceGroupLeft + numberWidth + paceGroupGap, numberBaselineY - unitAscent, Graphics.FONT_XTINY, paceUnit, Graphics.TEXT_JUSTIFY_LEFT);

            // Arrow + delta row below the pace (#29 redesign). The arrow is
            // now a solid triangle inside a trend-colored circular badge
            // (feedback round 4, point 2), matching the VO2max reference's
            // icon style, rather than a text glyph - a caret/ASCII character
            // read as a plain typographic mark, not a real "arrow in a
            // circle" indicator. Only the badge (and its icon) carry the
            // trend color; the delta text itself stays the system's normal
            // white.
            var deltaSecondsPerKm = Application.Storage.getValue("runningPaceTrendDeltaSecondsPerKm") as Number?;
            if (deltaSecondsPerKm != null) {
                var deltaUnit = WatchUi.loadResource(Rez.Strings.RunningTrendGraphDeltaUnit) as String;
                var deltaText = deltaSecondsPerKm.toString() + deltaUnit;

                var badgeRadius = (height * 0.035).toNumber();
                var badgeDiameter = badgeRadius * 2;
                var deltaWidth = dc.getTextWidthInPixels(deltaText, Graphics.FONT_XTINY);
                var deltaGroupGap = 4;
                var deltaGroupLeft = centerX - ((badgeDiameter + deltaGroupGap + deltaWidth) / 2);
                var badgeCenterX = deltaGroupLeft + badgeRadius;

                dc.setColor(trendColor, Graphics.COLOR_TRANSPARENT);
                dc.fillCircle(badgeCenterX, deltaRowY, badgeRadius);

                // The icon itself is drawn in black, which reads clearly
                // against all three trend colors (green/red/blue) without
                // needing a direction-specific icon color.
                dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
                var iconHalfWidth = badgeRadius * 0.5;
                var iconHalfHeight = badgeRadius * 0.5;
                if (trendDirection == RUNNING_PACE_TREND_DIRECTION_FASTER) {
                    dc.fillPolygon([
                        [badgeCenterX, deltaRowY - iconHalfHeight],
                        [badgeCenterX - iconHalfWidth, deltaRowY + iconHalfHeight],
                        [badgeCenterX + iconHalfWidth, deltaRowY + iconHalfHeight]
                    ] as Array<Graphics.Point2D>);
                } else if (trendDirection == RUNNING_PACE_TREND_DIRECTION_SLOWER) {
                    dc.fillPolygon([
                        [badgeCenterX, deltaRowY + iconHalfHeight],
                        [badgeCenterX - iconHalfWidth, deltaRowY - iconHalfHeight],
                        [badgeCenterX + iconHalfWidth, deltaRowY - iconHalfHeight]
                    ] as Array<Graphics.Point2D>);
                } else {
                    dc.fillRectangle(badgeCenterX - iconHalfWidth, deltaRowY - 1, iconHalfWidth * 2, 2);
                }

                dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
                dc.drawText(badgeCenterX + badgeRadius + deltaGroupGap, deltaRowY, Graphics.FONT_XTINY, deltaText, Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
            }
        }

        // Plot area sits below the current-pace/delta rows, sized to leave
        // room for those above and the period caption below (#29 redesign).
        // Full width (feedback round 3, point 8), now that the Y-axis pace
        // labels have moved above/below the plot instead of sitting to its
        // right - plotLeft clears the page-indicator dots on the left edge,
        // and the right edge stays inside the same round-bezel-safe margin
        // used elsewhere on this screen.
        var plotLeft = (width * 0.16).toNumber();
        var plotTop = (height * 0.50).toNumber();
        var plotWidth = (width * 0.70).toNumber();
        var plotHeight = (height * 0.22).toNumber();
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

        // Bolder trend line (feedback round 3, point 6) - a wider pen makes
        // it read clearly against the now-more-saturated area fill beneath
        // it. Reset to the default pen width immediately after so it
        // doesn't affect anything drawn later.
        dc.setColor(trendColor, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(3);
        for (var i = 0; i < points.size() - 1; i++) {
            var from = points[i] as Dictionary;
            var to = points[i + 1] as Dictionary;
            dc.drawLine(from["x"] as Number, from["y"] as Number, to["x"] as Number, to["y"] as Number);
        }
        dc.setPenWidth(1);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);

        // Y-axis pace labels now sit just above and below the plot itself
        // (feedback round 3, point 8), centered over its full width, rather
        // than off to its right - the plot no longer leaves a side margin
        // for them now that it spans the full width. Connect IQ has no
        // TEXT_JUSTIFY_TOP/BOTTOM: y defaults to the text's top with no
        // vertical flag, so the fastest label's y is pulled up by its own
        // height to land its bottom edge just above the top gridline.
        var plotCenterX = plotLeft + (plotWidth / 2);
        var labelGap = 2;

        var fastestText = RunningPaceFormatter.format(graphData["minSecondsPerKm"] as Number) + paceUnit;
        var fastestTextHeight = dc.getTextDimensions(fastestText, Graphics.FONT_XTINY)[1];
        dc.drawText(plotCenterX, plotTop - labelGap - fastestTextHeight, Graphics.FONT_XTINY, fastestText, Graphics.TEXT_JUSTIFY_CENTER);

        var slowestText = RunningPaceFormatter.format(graphData["maxSecondsPerKm"] as Number) + paceUnit;
        dc.drawText(plotCenterX, plotBaselineY + labelGap, Graphics.FONT_XTINY, slowestText, Graphics.TEXT_JUSTIFY_CENTER);

        // Single centered period caption (#29 redesign) replacing the
        // previous two corner labels, e.g. "Last 60 days" - built from
        // graphData's own daySpanDays so it always names the actual span
        // being plotted rather than a hardcoded lookback window.
        var periodCaptionTemplate = WatchUi.loadResource(Rez.Strings.RunningTrendGraphPeriodCaption) as String;
        var periodCaption = Lang.format(periodCaptionTemplate, [graphData["daySpanDays"] as Number]);
        dc.drawText(centerX, height * 0.80, Graphics.FONT_XTINY, periodCaption, Graphics.TEXT_JUSTIFY_CENTER);
    }

}
