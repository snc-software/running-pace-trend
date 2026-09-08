import Toybox.Application;
import Toybox.Background;
import Toybox.Lang;
import Toybox.System;
import Toybox.Time;
import Toybox.WatchUi;

class running_pace_trendApp extends Application.AppBase {

    // Upper bound on how often a foreground open re-runs the refresh (#40).
    // Small enough that opening the app after finishing a run always picks
    // that run up, large enough that flicking in and out of the widget does
    // not recompute the whole trend window each time.
    private const FOREGROUND_REFRESH_THROTTLE_SECONDS = 60;

    function initialize() {
        AppBase.initialize();
    }

    // onStart() is called on application start up
    function onStart(state as Dictionary?) as Void {
        // Fixed local-midnight schedule (#40), replacing the pre-#40 rolling
        // ~24h Duration interval that drifted with whatever time of day the
        // app happened to be installed at. A Moment registration fires once,
        // so RunningPaceBackgroundService re-arms the following midnight on
        // every firing; this only needs to register on a fresh install.
        if (Background.getTemporalEventRegisteredTime() == null) {
            Background.registerForTemporalEvent(RunningPaceBackgroundSchedule.nextMidnight(Time.now()));
        }

        // Refresh on a foreground open (#40) so the trend graph and Glance
        // reflect a just-completed run promptly, rather than only after the
        // next midnight tick - there is no confirmed Connect IQ "activity
        // completed" event a separate widget can subscribe to. This replaces
        // #36's one-shot runningPaceInitialSyncAttempted flag: refreshing on
        // open already covers the first launch after install, so the trend
        // graph still has real data immediately.
        //
        // Still re-runs when the trend window boundary keys are missing
        // (#37): running-pace-trendView.mc reads them with an unconditional
        // `as Number` and crashes on null, so an install upgraded from a
        // version predating those keys must repopulate them on open rather
        // than waiting for the next background tick.
        var lastComputedAt = Application.Storage.getValue("runningPaceLastComputedAt") as Number?;
        var missingTrendWindowBoundaries = Application.Storage.getValue("runningPaceTrendCurrentWindowStartEpoch") == null;
        if (lastComputedAt == null || missingTrendWindowBoundaries || Time.now().value() - lastComputedAt >= FOREGROUND_REFRESH_THROTTLE_SECONDS) {
            RunningPaceRefresh.run();
        }
    }

    // onStop() is called when your application is exiting
    function onStop(state as Dictionary?) as Void {
    }

    // Return the initial view of your application here. The graph screen is
    // screen 1 (#29).
    function getInitialView() as [Views] or [Views, InputDelegates] {
        return [ new RunningPaceTrendGraphView(), new RunningPaceTrendNavigationDelegate(RUNNING_PACE_TREND_PAGE_GRAPH) ];
    }

    (:glance)
    function getGlanceView() as [WatchUi.GlanceView] or [WatchUi.GlanceView, WatchUi.GlanceViewDelegate] or Null {
        return [ new RunningPaceGlanceView() ];
    }

    function getServiceDelegate() as [System.ServiceDelegate] {
        return [ new RunningPaceBackgroundService() ];
    }

}

function getApp() as running_pace_trendApp {
    return Application.getApp() as running_pace_trendApp;
}
