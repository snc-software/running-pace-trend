import Toybox.Application;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

// The trend graph screen, reached from running_pace_trendView via
// RunningPaceTrendDetailDelegate (US-07 / #12). Renders from
// Application.Storage only, mirroring the rest of this app's views - no pace
// calculation here, only RunningPaceTrendGraphContent's pure point-mapping.
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

        var plotLeft = (width * 0.14).toNumber();
        var plotTop = (height * 0.22).toNumber();
        var plotWidth = (width * 0.62).toNumber();
        var plotHeight = (height * 0.50).toNumber();

        var graphData = RunningPaceTrendGraphContent.buildGraphData(snapshots as Array<Dictionary>, plotLeft, plotTop, plotWidth, plotHeight);
        var points = graphData["points"] as Array<Dictionary>;

        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(plotLeft, plotTop, plotLeft, plotTop + plotHeight);
        dc.drawLine(plotLeft, plotTop + plotHeight, plotLeft + plotWidth, plotTop + plotHeight);

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        for (var i = 0; i < points.size() - 1; i++) {
            var from = points[i] as Dictionary;
            var to = points[i + 1] as Dictionary;
            dc.drawLine(from["x"] as Number, from["y"] as Number, to["x"] as Number, to["y"] as Number);
        }

        var paceUnit = WatchUi.loadResource(Rez.Strings.RunningTrendDetailUnit) as String;

        var fastestText = RunningPaceFormatter.format(graphData["minSecondsPerKm"] as Number) + paceUnit;
        dc.drawText(plotLeft + plotWidth + 4, plotTop, Graphics.FONT_XTINY, fastestText, Graphics.TEXT_JUSTIFY_LEFT);

        var slowestText = RunningPaceFormatter.format(graphData["maxSecondsPerKm"] as Number) + paceUnit;
        dc.drawText(plotLeft + plotWidth + 4, plotTop + plotHeight, Graphics.FONT_XTINY, slowestText, Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);

        var daysAgoSuffix = WatchUi.loadResource(Rez.Strings.RunningTrendGraphDaysAgoSuffix) as String;
        var oldestLabel = (graphData["daySpanDays"] as Number).toString() + daysAgoSuffix;
        dc.drawText(plotLeft, height * 0.90, Graphics.FONT_XTINY, oldestLabel, Graphics.TEXT_JUSTIFY_LEFT);

        var newestLabel = WatchUi.loadResource(Rez.Strings.RunningTrendGraphNowLabel) as String;
        dc.drawText(plotLeft + plotWidth, height * 0.90, Graphics.FONT_XTINY, newestLabel, Graphics.TEXT_JUSTIFY_RIGHT);
    }

}
