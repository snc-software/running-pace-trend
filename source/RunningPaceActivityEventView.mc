import Toybox.Application;
import Toybox.Background;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

// Temporary debug screen for the activity-completed background event (#49) -
// screen 4, reachable from the other three Running Trend screens via
// RunningPaceTrendNavigationDelegate's up/down paging. Its own page rather than
// extra rows on RunningPaceDebugView because that screen is already nine rows
// deep and its comments record that this round display clips wide text; both
// screens are temporary anyway, so readability beats page economy.
//
// This screen exists to answer ONE question that documentation and the simulator
// cannot: does UserProfile.getUserActivityHistory() already contain the
// just-finished activity when onActivityCompleted fires? #49 deliberately did
// not guard against that race - it made it visible here instead. Record a run,
// then read this screen. A recent timestamp with Sport: Run, Status: Refreshed
// and a retained count that includes the new run means the event won. A retained
// count that did not move means it raced the history write, and the fix is
// either a short delay in the handler or a one-shot temporal event a few minutes
// out.
//
// Renders from Application.Storage plus a live
// Background.getActivityCompletedEventRegistered() read - no computation here,
// mirroring the other three screens. The "Armed" row is the counterpart of
// RunningPaceDebugView's live "Next Refresh" read: it distinguishes "the event
// has never fired" from "the event was never subscribed to", which otherwise
// look identical.
class RunningPaceActivityEventView extends WatchUi.View {

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

        // Page-indicator dots (#29), matching the other three screens.
        var dotX = (width * 0.08).toNumber();
        var dotCenterY = height / 2;
        var dotOffsets = RunningPaceTrendPageIndicatorContent.buildDotCenterYOffsets();
        for (var i = 0; i < dotOffsets.size(); i++) {
            var dotY = dotCenterY + dotOffsets[i];
            if (i == RUNNING_PACE_TREND_PAGE_ACTIVITY) {
                dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
                dc.fillCircle(dotX, dotY, RunningPaceTrendPageIndicatorContent.ACTIVE_DOT_RADIUS);
            } else {
                dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
                dc.drawCircle(dotX, dotY, RunningPaceTrendPageIndicatorContent.INACTIVE_DOT_RADIUS);
            }
        }
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);

        var title = WatchUi.loadResource(Rez.Strings.RunningTrendActivityTitle) as String;
        dc.drawText(centerX, height * 0.08, Graphics.FONT_XTINY, title, Graphics.TEXT_JUSTIFY_CENTER);

        var lastFiredAt = Application.Storage.getValue("runningPaceLastActivityEventAt") as Number?;
        var outcome = RunningPaceDebugContent.resolveActivityEventOutcome(
            Application.Storage.getValue("runningPaceLastActivityEventOutcome") as Number?
        );

        var lastFiredLabel = WatchUi.loadResource(Rez.Strings.RunningTrendActivityLastFiredLabel) as String;
        dc.drawText(centerX, height * 0.22, Graphics.FONT_XTINY, lastFiredLabel, Graphics.TEXT_JUSTIFY_CENTER);

        var lastFiredText;
        if (lastFiredAt == null) {
            lastFiredText = WatchUi.loadResource(Rez.Strings.RunningTrendDebugNeverUpdated) as String;
        } else {
            lastFiredText = RunningPaceTrendDateFormatter.formatDateTime(lastFiredAt);
        }
        dc.drawText(centerX, height * 0.30, Graphics.FONT_TINY, lastFiredText, Graphics.TEXT_JUSTIFY_CENTER);

        // Omitted rather than drawn as a placeholder when the event has never
        // fired - there is no sport to report, and a dash would read as one.
        var sportText = RunningPaceDebugContent.formatSport(
            Application.Storage.getValue("runningPaceLastActivityEventSport") as Number?,
            WatchUi.loadResource(Rez.Strings.RunningTrendActivitySportRunning) as String
        );
        if (sportText != null) {
            var sportLabel = WatchUi.loadResource(Rez.Strings.RunningTrendActivitySportLabel) as String;
            dc.drawText(centerX, height * 0.44, Graphics.FONT_TINY, sportLabel + " " + sportText, Graphics.TEXT_JUSTIFY_CENTER);
        }

        // FONT_XTINY, not the FONT_TINY RunningPaceDebugView uses for its own
        // status row: "Not a run" and "Refreshed" are both longer than that
        // screen's "Success", and this display has already clipped a wide row
        // once (see RunningPaceDebugContent.formatScanSummary).
        var outcomeValue;
        if (outcome == RUNNING_PACE_ACTIVITY_EVENT_REFRESHED) {
            outcomeValue = WatchUi.loadResource(Rez.Strings.RunningTrendActivityOutcomeRefreshed) as String;
        } else if (outcome == RUNNING_PACE_ACTIVITY_EVENT_SKIPPED_NOT_RUNNING) {
            outcomeValue = WatchUi.loadResource(Rez.Strings.RunningTrendActivityOutcomeNotRunning) as String;
        } else if (outcome == RUNNING_PACE_ACTIVITY_EVENT_REFRESH_FAILED) {
            outcomeValue = WatchUi.loadResource(Rez.Strings.RunningTrendDebugStatusFailed) as String;
        } else {
            outcomeValue = WatchUi.loadResource(Rez.Strings.RunningTrendDebugStatusNeverRun) as String;
        }
        var statusLabel = WatchUi.loadResource(Rez.Strings.RunningTrendDebugStatusLabel) as String;
        dc.drawText(centerX, height * 0.56, Graphics.FONT_XTINY, statusLabel + " " + outcomeValue, Graphics.TEXT_JUSTIFY_CENTER);

        // THE ROW THIS SCREEN EXISTS FOR. Scanned/retained for this firing
        // specifically, copied by the handler out of the shared scan keys so a
        // later midnight refresh cannot restate its own counts here. Shown only
        // when this firing actually refreshed - a skipped or failed firing has
        // no counts, and borrowing an earlier firing's pair would read as though
        // this one produced them.
        var counts = RunningPaceDebugContent.formatEventCounts(
            outcome,
            Application.Storage.getValue("runningPaceLastActivityEventScannedCount") as Number?,
            Application.Storage.getValue("runningPaceLastActivityEventRetainedCount") as Number?
        );
        if (counts != null) {
            dc.drawText(centerX, height * 0.66, Graphics.FONT_TINY, counts, Graphics.TEXT_JUSTIFY_CENTER);
        }

        // Live read, like RunningPaceDebugView's "Next Refresh" - tells you the
        // subscription is actually in place, so "Never" above can be read as
        // "no run has finished yet" rather than "this never worked".
        var armedLabel = WatchUi.loadResource(Rez.Strings.RunningTrendActivityArmedLabel) as String;
        var armedValue;
        if (Background.getActivityCompletedEventRegistered()) {
            armedValue = WatchUi.loadResource(Rez.Strings.RunningTrendActivityArmedYes) as String;
        } else {
            armedValue = WatchUi.loadResource(Rez.Strings.RunningTrendActivityArmedNo) as String;
        }
        dc.drawText(centerX, height * 0.78, Graphics.FONT_XTINY, armedLabel + " " + armedValue, Graphics.TEXT_JUSTIFY_CENTER);

        dc.drawText(centerX, height * 0.90, Graphics.FONT_XTINY, RunningPaceDebugView.APP_VERSION, Graphics.TEXT_JUSTIFY_CENTER);
    }

}
