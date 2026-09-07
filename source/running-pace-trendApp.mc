import Toybox.Application;
import Toybox.Background;
import Toybox.Lang;
import Toybox.System;
import Toybox.Time;
import Toybox.WatchUi;

class running_pace_trendApp extends Application.AppBase {

    // ~24h, matching a once-daily recompute cadence. Passing a Duration (rather
    // than a Moment) registers a periodic event, so this only needs registering
    // once — RunningPaceBackgroundService does not need to re-register itself.
    private const BACKGROUND_REFRESH_INTERVAL_SECONDS = 86400;

    function initialize() {
        AppBase.initialize();
    }

    // onStart() is called on application start up
    function onStart(state as Dictionary?) as Void {
        if (Background.getTemporalEventRegisteredTime() == null) {
            Background.registerForTemporalEvent(new Time.Duration(BACKGROUND_REFRESH_INTERVAL_SECONDS));
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