import Toybox.Application;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

// The detail view the OS opens when the user taps the Running Pace Glance
// (glance-standards.md: a GlanceView itself must not be interactive) - screen
// 2, reachable from RunningPaceTrendGraphView (screen 1) via
// RunningPaceTrendNavigationDelegate's up/down paging (#29). Renders from
// Application.Storage only, mirroring RunningPaceGlanceView — no computation
// here beyond display formatting.
class running_pace_trendView extends WatchUi.View {

    function initialize() {
        View.initialize();
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() as Void {
    }

    function onUpdate(dc as Dc) as Void {
        // clear() erases using the background color (Dc.html), so it must be
        // opaque here - COLOR_TRANSPARENT would leave the previous frame's
        // pixels in place, which becomes visible once this view is reachable
        // via paging navigation (#29) rather than being the only screen in
        // the app.
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
            if (i == RUNNING_PACE_TREND_PAGE_DETAIL) {
                dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
                dc.fillCircle(dotX, dotY, RunningPaceTrendPageIndicatorContent.ACTIVE_DOT_RADIUS);
            } else {
                dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
                dc.drawCircle(dotX, dotY, RunningPaceTrendPageIndicatorContent.INACTIVE_DOT_RADIUS);
            }
        }
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);

        var title = WatchUi.loadResource(Rez.Strings.RunningTrendDetailTitle) as String;
        dc.drawText(centerX, height * 0.10, Graphics.FONT_XTINY, title, Graphics.TEXT_JUSTIFY_CENTER);

        var hasSufficientData = Application.Storage.getValue("runningPaceHasSufficientData") as Boolean?;
        var trendHasSufficientData = Application.Storage.getValue("runningPaceTrendHasSufficientData") as Boolean?;
        var state = RunningPaceTrendDetailContent.resolveState(hasSufficientData, trendHasSufficientData);

        if (state == RUNNING_PACE_TREND_DETAIL_STATE_NO_DATA) {
            var insufficientDataMessage = WatchUi.loadResource(Rez.Strings.RunningTrendDetailInsufficientData) as String;
            dc.drawText(centerX, height * 0.5, Graphics.FONT_TINY, insufficientDataMessage, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            return;
        }

        var paceUnit = WatchUi.loadResource(Rez.Strings.RunningTrendDetailUnit) as String;
        var currentSecondsPerKm = Application.Storage.getValue("runningPaceSecondsPerKm") as Number;
        var currentLabel = WatchUi.loadResource(Rez.Strings.RunningTrendDetailCurrentLabel) as String;
        var currentText = currentLabel + " " + RunningPaceFormatter.format(currentSecondsPerKm) + paceUnit;
        dc.drawText(centerX, height * 0.26, Graphics.FONT_TINY, currentText, Graphics.TEXT_JUSTIFY_CENTER);

        if (state == RUNNING_PACE_TREND_DETAIL_STATE_FULL) {
            var previousSecondsPerKm = Application.Storage.getValue("runningPaceTrendPreviousSecondsPerKm") as Number;
            var previousLabel = WatchUi.loadResource(Rez.Strings.RunningTrendDetailPreviousLabel) as String;
            var previousText = previousLabel + " " + RunningPaceFormatter.format(previousSecondsPerKm) + paceUnit;
            dc.drawText(centerX, height * 0.38, Graphics.FONT_TINY, previousText, Graphics.TEXT_JUSTIFY_CENTER);

            var direction = Application.Storage.getValue("runningPaceTrendDirection") as Number;
            var deltaSecondsPerKm = Application.Storage.getValue("runningPaceTrendDeltaSecondsPerKm") as Number;

            var deltaSuffix;
            if (direction == RUNNING_PACE_TREND_DIRECTION_FASTER) {
                deltaSuffix = WatchUi.loadResource(Rez.Strings.RunningTrendDetailFasterSuffix) as String;
            } else if (direction == RUNNING_PACE_TREND_DIRECTION_SLOWER) {
                deltaSuffix = WatchUi.loadResource(Rez.Strings.RunningTrendDetailSlowerSuffix) as String;
            } else {
                deltaSuffix = WatchUi.loadResource(Rez.Strings.RunningTrendDetailUnchangedSuffix) as String;
            }

            var deltaText = deltaSecondsPerKm.toString() + " " + deltaSuffix;
            dc.drawText(centerX, height * 0.52, Graphics.FONT_XTINY, deltaText, Graphics.TEXT_JUSTIFY_CENTER);

            var percentChangeTenths = Application.Storage.getValue("runningPaceTrendPercentChangeTenths") as Number;
            var percentText = RunningPaceTrendFormatter.formatPercent(percentChangeTenths);
            dc.drawText(centerX, height * 0.62, Graphics.FONT_XTINY, percentText, Graphics.TEXT_JUSTIFY_CENTER);
        } else {
            var insufficientHistoryMessage = WatchUi.loadResource(Rez.Strings.RunningTrendDetailInsufficientHistory) as String;
            dc.drawText(centerX, height * 0.45, Graphics.FONT_XTINY, insufficientHistoryMessage, Graphics.TEXT_JUSTIFY_CENTER);
        }

        var totalDistanceMeters = Application.Storage.getValue("runningPaceTotalDistanceMeters") as Number;
        var distanceLabel = WatchUi.loadResource(Rez.Strings.RunningTrendDetailDistanceLabel) as String;
        var distanceUnit = WatchUi.loadResource(Rez.Strings.RunningTrendDetailDistanceUnit) as String;
        var distanceText = distanceLabel + " " + RunningPaceDistanceFormatter.format(totalDistanceMeters) + " " + distanceUnit;
        dc.drawText(centerX, height * 0.76, Graphics.FONT_TINY, distanceText, Graphics.TEXT_JUSTIFY_CENTER);

        var qualifyingActivityCount = Application.Storage.getValue("runningPaceQualifyingActivityCount") as Number;
        var runsLabel = WatchUi.loadResource(Rez.Strings.RunningTrendDetailRunsLabel) as String;
        var runsText = runsLabel + " " + qualifyingActivityCount.toString();
        dc.drawText(centerX, height * 0.86, Graphics.FONT_TINY, runsText, Graphics.TEXT_JUSTIFY_CENTER);
    }

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() as Void {
    }

}
