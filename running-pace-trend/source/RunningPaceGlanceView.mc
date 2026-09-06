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

        dc.drawText(centerX, height / 2, Graphics.FONT_TINY, valueText, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

}
