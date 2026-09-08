import Toybox.Application;
import Toybox.Background;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

// Temporary debug screen (chore/debug-screen) - screen 3, reachable from the
// other two Running Trend screens via RunningPaceTrendNavigationDelegate's
// up/down paging. Exists to build confidence that RunningPaceBackgroundService's
// fixed-midnight schedule and retry logic (#40) are actually firing correctly
// on-device: shows when the midnight refresh last ran, whether it succeeded,
// how many attempts it took, and when it's next scheduled. Renders from
// Application.Storage plus a live Background.getTemporalEventRegisteredTime()
// read - no computation here, mirroring the other two screens.
class RunningPaceDebugView extends WatchUi.View {

    // Bumped by hand on every release (#47) so an instant on-device check of
    // this screen shows which build is actually installed - useful because
    // Connect IQ / the watch can cache a stale app after a sideload.
    private const APP_VERSION = "v1.7.5";

    function initialize() {
        View.initialize();
    }

    function onUpdate(dc as Dc) as Void {
        // clear() erases using the background color (Dc.html), so it must be
        // opaque here - COLOR_TRANSPARENT would leave the previous screen's
        // last frame showing through underneath this one.
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);

        var width = dc.getWidth();
        var height = dc.getHeight();
        var centerX = width / 2;

        // Page-indicator dots (#29), matching the other two screens.
        var dotX = (width * 0.08).toNumber();
        var dotCenterY = height / 2;
        var dotOffsets = RunningPaceTrendPageIndicatorContent.buildDotCenterYOffsets();
        for (var i = 0; i < dotOffsets.size(); i++) {
            var dotY = dotCenterY + dotOffsets[i];
            if (i == RUNNING_PACE_TREND_PAGE_DEBUG) {
                dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
                dc.fillCircle(dotX, dotY, RunningPaceTrendPageIndicatorContent.ACTIVE_DOT_RADIUS);
            } else {
                dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
                dc.drawCircle(dotX, dotY, RunningPaceTrendPageIndicatorContent.INACTIVE_DOT_RADIUS);
            }
        }
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);

        var title = WatchUi.loadResource(Rez.Strings.RunningTrendDebugTitle) as String;
        dc.drawText(centerX, height * 0.08, Graphics.FONT_XTINY, title, Graphics.TEXT_JUSTIFY_CENTER);

        var lastMidnightRefreshAt = Application.Storage.getValue("runningPaceLastMidnightRefreshAt") as Number?;
        var succeeded = Application.Storage.getValue("runningPaceLastMidnightRefreshSucceeded") as Boolean?;
        var attempts = Application.Storage.getValue("runningPaceLastMidnightRefreshAttempts") as Number?;

        var lastUpdatedLabel = WatchUi.loadResource(Rez.Strings.RunningTrendDebugLastUpdatedLabel) as String;
        dc.drawText(centerX, height * 0.22, Graphics.FONT_XTINY, lastUpdatedLabel, Graphics.TEXT_JUSTIFY_CENTER);

        var lastUpdatedText;
        if (lastMidnightRefreshAt == null) {
            lastUpdatedText = WatchUi.loadResource(Rez.Strings.RunningTrendDebugNeverUpdated) as String;
        } else {
            lastUpdatedText = RunningPaceTrendDateFormatter.formatDateTime(lastMidnightRefreshAt);
        }
        dc.drawText(centerX, height * 0.30, Graphics.FONT_TINY, lastUpdatedText, Graphics.TEXT_JUSTIFY_CENTER);

        var status = RunningPaceDebugContent.resolveStatus(succeeded);
        var statusValue;
        if (status == RUNNING_PACE_DEBUG_STATUS_SUCCESS) {
            statusValue = WatchUi.loadResource(Rez.Strings.RunningTrendDebugStatusSuccess) as String;
        } else if (status == RUNNING_PACE_DEBUG_STATUS_FAILED) {
            statusValue = WatchUi.loadResource(Rez.Strings.RunningTrendDebugStatusFailed) as String;
        } else {
            statusValue = WatchUi.loadResource(Rez.Strings.RunningTrendDebugStatusNeverRun) as String;
        }
        var statusLabel = WatchUi.loadResource(Rez.Strings.RunningTrendDebugStatusLabel) as String;
        var statusText = statusLabel + " " + statusValue;
        dc.drawText(centerX, height * 0.44, Graphics.FONT_TINY, statusText, Graphics.TEXT_JUSTIFY_CENTER);

        if (attempts != null) {
            var attemptsLabel = WatchUi.loadResource(Rez.Strings.RunningTrendDebugAttemptsLabel) as String;
            var attemptsText = attemptsLabel + " " + attempts.toString();
            dc.drawText(centerX, height * 0.54, Graphics.FONT_TINY, attemptsText, Graphics.TEXT_JUSTIFY_CENTER);
        }

        var nextRefreshLabel = WatchUi.loadResource(Rez.Strings.RunningTrendDebugNextRefreshLabel) as String;
        dc.drawText(centerX, height * 0.66, Graphics.FONT_XTINY, nextRefreshLabel, Graphics.TEXT_JUSTIFY_CENTER);

        var nextRefreshMoment = Background.getTemporalEventRegisteredTime();
        var nextRefreshText;
        if (nextRefreshMoment == null) {
            nextRefreshText = WatchUi.loadResource(Rez.Strings.RunningTrendDebugNotScheduled) as String;
        } else {
            nextRefreshText = RunningPaceTrendDateFormatter.formatDateTime(nextRefreshMoment.value());
        }
        dc.drawText(centerX, height * 0.74, Graphics.FONT_TINY, nextRefreshText, Graphics.TEXT_JUSTIFY_CENTER);

        dc.drawText(centerX, height * 0.90, Graphics.FONT_XTINY, APP_VERSION, Graphics.TEXT_JUSTIFY_CENTER);
    }

}
