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

        // Run the compute-and-persist refresh synchronously exactly once, on
        // the first launch after install, so the trend graph has real data
        // immediately instead of waiting for the first ~24h background tick
        // (#36). Guarded by a dedicated one-time flag rather than by whether
        // data was actually found, so a first attempt with insufficient
        // on-device history is not retried on every subsequent app open —
        // the daily background job above remains responsible for eventually
        // populating it, exactly as it does today.
        //
        // Also re-runs (regardless of that flag) whenever the trend window
        // boundary keys are missing (#37): an install upgraded from a
        // version predating those keys already has
        // runningPaceInitialSyncAttempted = true from its original install,
        // so without this check they'd stay unset until the next ~24h
        // background tick - and running-pace-trendView.mc's unconditional
        // `as Number` reads of them crash on null in the meantime.
        var needsSync = Application.Storage.getValue("runningPaceInitialSyncAttempted") != true;
        var missingTrendWindowBoundaries = Application.Storage.getValue("runningPaceTrendCurrentWindowStartEpoch") == null;
        if (needsSync || missingTrendWindowBoundaries) {
            RunningPaceRefresh.run();
            Application.Storage.setValue("runningPaceInitialSyncAttempted", true);
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