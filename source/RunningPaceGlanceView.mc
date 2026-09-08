import Toybox.Application;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

// Renders from Application.Storage only — no computation or I/O here beyond
// display formatting, per glance-standards.md's Execution Budget rule. The
// RunningPaceBackgroundService is the only writer of these Storage keys.
(:glance)
class RunningPaceGlanceView extends WatchUi.GlanceView {

    // Lazily loaded and cached on first onUpdate() rather than reloaded every
    // draw (#47) - onUpdate() is budgeted and can run many times per glance
    // instantiation, so repeated WatchUi.loadResource() calls are avoidable
    // per-draw cost per glance-standards.md's Execution Budget rule.
    //
    // Deliberately NOT loaded in initialize(): #47's first attempt did that,
    // and the on-device blank row reappeared with the title itself missing
    // too. An initialize()-time loadResource() failure would explain exactly
    // that - either the view fails to construct at all, or these fields stay
    // null and the (then-unconditional, unguarded) dc.drawText(..., null,
    // ...) for the title throws before anything else in onUpdate() runs.
    // Loading lazily from inside the guarded draw() below means a load
    // failure is caught like everything else instead of aborting the view.
    private var _label as String?;
    private var _unit as String?;
    private var _insufficientDataText as String?;
    private var _trendDeltaUnit as String?;

    function initialize() {
        GlanceView.initialize();
    }

    function onUpdate(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.clear();

        // #47: the row was reported to render fully blank - title included -
        // on a real device, permanently once it started, but this doesn't
        // reproduce in the simulator. dc.clear() above only touches pixels
        // so it can't itself be the failure; everything else - resource
        // loads, Storage reads, and all drawing, including the title - is
        // wrapped here so an unhandled exception anywhere in it can no
        // longer abort onUpdate() partway through and leave the row in an
        // undefined state.
        try {
            draw(dc);
        } catch (exception instanceof Lang.Exception) {
            // Deliberately ignored: dc.clear() above has already left the
            // row in a defined (cleared) state, and there's nothing further
            // to recover into if resource loading or drawing itself is what
            // failed.
        }
    }

    private function draw(dc as Dc) as Void {
        if (_label == null) {
            _label = WatchUi.loadResource(Rez.Strings.RunningPaceLabel) as String;
            _unit = WatchUi.loadResource(Rez.Strings.RunningPaceUnit) as String;
            _insufficientDataText = WatchUi.loadResource(Rez.Strings.RunningPaceInsufficientData) as String;
            _trendDeltaUnit = WatchUi.loadResource(Rez.Strings.RunningPaceTrendDeltaUnit) as String;
        }

        var width = dc.getWidth();
        var height = dc.getHeight();
        var rowY = height * 0.62;
        var leftMargin = width * 0.05;
        var rightMargin = width * 0.05;

        // Plain native white text on the system background - the OS-owned
        // icon area (left of our drawable canvas) means a left-edge bar or
        // full-row gradient wash can never reach the row's true left edge,
        // so it reads as a stray colored patch rather than the native
        // full-row wash it's meant to imitate (#38 feedback). Only the
        // trend badge below carries the direction color, same as the graph
        // screen.
        dc.drawText(leftMargin, height * 0.05, Graphics.FONT_GLANCE, _label, Graphics.TEXT_JUSTIFY_LEFT);

        var hasSufficientData = Application.Storage.getValue("runningPaceHasSufficientData") as Boolean?;
        var secondsPerKm = Application.Storage.getValue("runningPaceSecondsPerKm") as Number?;
        var trendHasSufficientData = Application.Storage.getValue("runningPaceTrendHasSufficientData") as Boolean?;
        var trendDirection = Application.Storage.getValue("runningPaceTrendDirection") as Number?;
        var trendDeltaSecondsPerKm = Application.Storage.getValue("runningPaceTrendDeltaSecondsPerKm") as Number?;

        var valueState = RunningPaceGlanceContent.resolveValueState(hasSufficientData, secondsPerKm);
        var showTrend = RunningPaceGlanceContent.shouldShowTrend(trendHasSufficientData, trendDirection, trendDeltaSecondsPerKm);

        if (valueState != RUNNING_PACE_GLANCE_VALUE_STATE_AVAILABLE) {
            dc.drawText(width / 2, rowY, Graphics.FONT_TINY, _insufficientDataText, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            return;
        }

        var valueText = RunningPaceFormatter.format(secondsPerKm) + " " + _unit;
        dc.drawText(leftMargin, rowY, Graphics.FONT_TINY, valueText, Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);

        if (!showTrend) {
            return;
        }

        // Trend-colored circular badge with a black arrow/level icon inside,
        // matching RunningPaceTrendGraphView's own delta badge (#38 feedback
        // round 2) rather than a bare colored triangle - the delta text
        // itself stays white, only the badge carries the direction color.
        var deltaText = trendDeltaSecondsPerKm.toString() + _trendDeltaUnit;
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
            // Faster means the time decreased, so the arrow points down (#46).
            dc.fillPolygon([
                [badgeCenterX, rowY + iconHalfHeight],
                [badgeCenterX - iconHalfWidth, rowY - iconHalfHeight],
                [badgeCenterX + iconHalfWidth, rowY - iconHalfHeight]
            ] as Array<Graphics.Point2D>);
        } else if (trendDirection == RUNNING_PACE_TREND_DIRECTION_SLOWER) {
            dc.fillPolygon([
                [badgeCenterX, rowY - iconHalfHeight],
                [badgeCenterX - iconHalfWidth, rowY + iconHalfHeight],
                [badgeCenterX + iconHalfWidth, rowY + iconHalfHeight]
            ] as Array<Graphics.Point2D>);
        } else {
            dc.fillRectangle(badgeCenterX - iconHalfWidth, rowY - 1, iconHalfWidth * 2, 2);
        }

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(badgeCenterX + badgeRadius + groupGap, rowY, deltaFont, deltaText, Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
    }

}
