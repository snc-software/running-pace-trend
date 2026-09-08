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
        var rowY = height * 0.62;
        var leftMargin = width * 0.05;
        var rightMargin = width * 0.05;

        var hasSufficientData = Application.Storage.getValue("runningPaceHasSufficientData") as Boolean?;
        var secondsPerKm = Application.Storage.getValue("runningPaceSecondsPerKm") as Number?;
        var trendHasSufficientData = Application.Storage.getValue("runningPaceTrendHasSufficientData") as Boolean?;
        var trendDirection = Application.Storage.getValue("runningPaceTrendDirection") as Number?;
        var trendDeltaSecondsPerKm = Application.Storage.getValue("runningPaceTrendDeltaSecondsPerKm") as Number?;

        var valueState = RunningPaceGlanceContent.resolveValueState(hasSufficientData, secondsPerKm);
        var showTrend = RunningPaceGlanceContent.shouldShowTrend(trendHasSufficientData, trendDirection, trendDeltaSecondsPerKm);

        // Plain native white text on the system background - the OS-owned
        // icon area (left of our drawable canvas) means a left-edge bar or
        // full-row gradient wash can never reach the row's true left edge,
        // so it reads as a stray colored patch rather than the native
        // full-row wash it's meant to imitate (#38 feedback). Only the
        // trend badge below carries the direction color, same as the graph
        // screen.
        var label = WatchUi.loadResource(Rez.Strings.RunningPaceLabel) as String;
        dc.drawText(leftMargin, height * 0.05, Graphics.FONT_XTINY, label, Graphics.TEXT_JUSTIFY_LEFT);

        if (valueState != RUNNING_PACE_GLANCE_VALUE_STATE_AVAILABLE) {
            var insufficientText = WatchUi.loadResource(Rez.Strings.RunningPaceInsufficientData) as String;
            dc.drawText(width / 2, rowY, Graphics.FONT_TINY, insufficientText, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            return;
        }

        var unit = WatchUi.loadResource(Rez.Strings.RunningPaceUnit) as String;
        var valueText = RunningPaceFormatter.format(secondsPerKm) + " " + unit;
        dc.drawText(leftMargin, rowY, Graphics.FONT_TINY, valueText, Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);

        if (!showTrend) {
            return;
        }

        // Trend-colored circular badge with a black arrow/level icon inside,
        // matching RunningPaceTrendGraphView's own delta badge (#38 feedback
        // round 2) rather than a bare colored triangle - the delta text
        // itself stays white, only the badge carries the direction color.
        var deltaUnit = WatchUi.loadResource(Rez.Strings.RunningPaceTrendDeltaUnit) as String;
        var deltaText = trendDeltaSecondsPerKm.toString() + deltaUnit;
        var deltaFont = Graphics.FONT_XTINY;
        var deltaWidth = dc.getTextWidthInPixels(deltaText, deltaFont);

        var badgeRadius = (height * 0.14).toNumber();
        var badgeDiameter = badgeRadius * 2;
        var groupGap = 8;
        var groupRight = width - rightMargin;
        var groupLeft = groupRight - deltaWidth - groupGap - badgeDiameter;
        var badgeCenterX = groupLeft + badgeRadius;

        dc.setColor(RunningPaceTrendColor.forDirection(trendDirection), Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(badgeCenterX, rowY, badgeRadius);

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        var iconHalfWidth = badgeRadius * 0.5;
        var iconHalfHeight = badgeRadius * 0.5;
        if (trendDirection == RUNNING_PACE_TREND_DIRECTION_FASTER) {
            dc.fillPolygon([
                [badgeCenterX, rowY - iconHalfHeight],
                [badgeCenterX - iconHalfWidth, rowY + iconHalfHeight],
                [badgeCenterX + iconHalfWidth, rowY + iconHalfHeight]
            ] as Array<Graphics.Point2D>);
        } else if (trendDirection == RUNNING_PACE_TREND_DIRECTION_SLOWER) {
            dc.fillPolygon([
                [badgeCenterX, rowY + iconHalfHeight],
                [badgeCenterX - iconHalfWidth, rowY - iconHalfHeight],
                [badgeCenterX + iconHalfWidth, rowY - iconHalfHeight]
            ] as Array<Graphics.Point2D>);
        } else {
            dc.fillRectangle(badgeCenterX - iconHalfWidth, rowY - 1, iconHalfWidth * 2, 2);
        }

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(badgeCenterX + badgeRadius + groupGap, rowY, deltaFont, deltaText, Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
    }

}
