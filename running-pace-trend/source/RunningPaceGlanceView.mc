import Toybox.Application;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

// Renders from Application.Storage only — no computation or I/O here beyond
// display formatting, per glance-standards.md's Execution Budget rule. The
// RunningPaceBackgroundService is the only writer of these Storage keys.
(:glance)
class RunningPaceGlanceView extends WatchUi.GlanceView {

    function initialize() {
        GlanceView.initialize();
    }

    function onUpdate(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.clear();

        var width = dc.getWidth();
        var height = dc.getHeight();
        var centerX = width / 2;

        var label = WatchUi.loadResource(Rez.Strings.RunningPaceLabel) as String;
        dc.drawText(centerX, 0, Graphics.FONT_XTINY, label, Graphics.TEXT_JUSTIFY_CENTER);

        var hasSufficientData = Application.Storage.getValue("runningPaceHasSufficientData") as Boolean?;
        var secondsPerKm = Application.Storage.getValue("runningPaceSecondsPerKm") as Number?;

        var valueText;
        if (hasSufficientData == true && secondsPerKm != null) {
            var unit = WatchUi.loadResource(Rez.Strings.RunningPaceUnit) as String;
            valueText = RunningPaceFormatter.format(secondsPerKm) + " " + unit;
        } else {
            valueText = WatchUi.loadResource(Rez.Strings.RunningPaceInsufficientData) as String;
        }

        dc.drawText(centerX, height * 0.35, Graphics.FONT_TINY, valueText, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        var trendHasSufficientData = Application.Storage.getValue("runningPaceTrendHasSufficientData") as Boolean?;
        var trendDirection = Application.Storage.getValue("runningPaceTrendDirection") as Number?;
        var trendDeltaSecondsPerKm = Application.Storage.getValue("runningPaceTrendDeltaSecondsPerKm") as Number?;

        if (trendHasSufficientData == true && trendDirection != null && trendDeltaSecondsPerKm != null) {
            var suffix;
            if (trendDirection == RUNNING_PACE_TREND_DIRECTION_FASTER) {
                suffix = WatchUi.loadResource(Rez.Strings.RunningPaceTrendFasterSuffix) as String;
            } else if (trendDirection == RUNNING_PACE_TREND_DIRECTION_SLOWER) {
                suffix = WatchUi.loadResource(Rez.Strings.RunningPaceTrendSlowerSuffix) as String;
            } else {
                suffix = WatchUi.loadResource(Rez.Strings.RunningPaceTrendUnchangedSuffix) as String;
            }

            var trendText = RunningPaceTrendFormatter.format(trendDirection, trendDeltaSecondsPerKm) + " " + suffix;
            dc.drawText(centerX, height * 0.75, Graphics.FONT_XTINY, trendText, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        }
    }

}
