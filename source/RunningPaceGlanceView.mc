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
        var rowY = height * 0.62;

        var label = WatchUi.loadResource(Rez.Strings.RunningPaceLabel) as String;
        dc.drawText(centerX, height * 0.05, Graphics.FONT_XTINY, label, Graphics.TEXT_JUSTIFY_CENTER);

        var hasSufficientData = Application.Storage.getValue("runningPaceHasSufficientData") as Boolean?;
        var secondsPerKm = Application.Storage.getValue("runningPaceSecondsPerKm") as Number?;

        if (RunningPaceGlanceContent.resolveValueState(hasSufficientData, secondsPerKm) != RUNNING_PACE_GLANCE_VALUE_STATE_AVAILABLE) {
            var insufficientText = WatchUi.loadResource(Rez.Strings.RunningPaceInsufficientData) as String;
            dc.drawText(centerX, rowY, Graphics.FONT_TINY, insufficientText, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            return;
        }

        var unit = WatchUi.loadResource(Rez.Strings.RunningPaceUnit) as String;
        var valueText = RunningPaceFormatter.format(secondsPerKm) + " " + unit;

        var trendHasSufficientData = Application.Storage.getValue("runningPaceTrendHasSufficientData") as Boolean?;
        var trendDirection = Application.Storage.getValue("runningPaceTrendDirection") as Number?;
        var trendDeltaSecondsPerKm = Application.Storage.getValue("runningPaceTrendDeltaSecondsPerKm") as Number?;
        var showTrend = RunningPaceGlanceContent.shouldShowTrend(trendHasSufficientData, trendDirection, trendDeltaSecondsPerKm);

        if (!showTrend) {
            dc.drawText(centerX, rowY, Graphics.FONT_TINY, valueText, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            return;
        }

        var margin = width * 0.05;
        dc.drawText(margin, rowY, Graphics.FONT_TINY, valueText, Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);

        var suffix;
        if (trendDirection == RUNNING_PACE_TREND_DIRECTION_FASTER) {
            suffix = WatchUi.loadResource(Rez.Strings.RunningPaceTrendFasterSuffix) as String;
        } else if (trendDirection == RUNNING_PACE_TREND_DIRECTION_SLOWER) {
            suffix = WatchUi.loadResource(Rez.Strings.RunningPaceTrendSlowerSuffix) as String;
        } else {
            suffix = WatchUi.loadResource(Rez.Strings.RunningPaceTrendUnchangedSuffix) as String;
        }
        var trendText = RunningPaceTrendFormatter.format(trendDirection, trendDeltaSecondsPerKm) + " " + suffix;

        // Colored highlight bar behind the trend value (#27): green when
        // faster, red when slower, blue when unchanged, reusing the same
        // RunningPaceTrendColor mapping RunningPaceTrendGraphView already
        // uses for its trend badge - no new decision logic here. Black text
        // on the bar mirrors that same badge's black-on-color convention for
        // contrast against all three trend colors.
        var trendFont = Graphics.FONT_XTINY;
        var trendTextWidth = dc.getTextWidthInPixels(trendText, trendFont);
        var trendTextHeight = Graphics.getFontHeight(trendFont);
        var barPaddingX = 6;
        var barPaddingY = 4;
        var barWidth = trendTextWidth + (barPaddingX * 2);
        var barHeight = trendTextHeight + (barPaddingY * 2);
        var barRight = width - margin;
        var barLeft = barRight - barWidth;
        var barTop = rowY - (barHeight / 2);

        dc.setColor(RunningPaceTrendColor.forDirection(trendDirection), Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(barLeft, barTop, barWidth, barHeight, barHeight / 4);

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        dc.drawText(barRight - barPaddingX, rowY, trendFont, trendText, Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER);
    }

}
