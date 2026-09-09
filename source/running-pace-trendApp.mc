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
    //
    // Briefly raised to 15 minutes while a full refresh still froze the UI for
    // its whole ~2.7s duration; back to 60s now that RunningPaceForegroundRefresh
    // chunks the scan across timer ticks and the refresh no longer blocks
    // interaction (#47 follow-up). The throttle is back to meaning what it
    // originally meant - how stale the data may get - rather than papering over
    // a stall.
    private const FOREGROUND_REFRESH_THROTTLE_SECONDS = 60;

    function initialize() {
        AppBase.initialize();
    }

    // Deliberately does NOTHING (#47). onStart() is called in EVERY scope the
    // app can start in - widget, background service, and Glance ("The AppBase
    // functions onStart() and getGlanceView() will be called to start the app
    // and retrieve the view during a background update in glance mode",
    // Toybox.Application.AppBase docs) - but the Glance is compiled as its own
    // separate, 32kB-limited binary containing only (:glance)-annotated code.
    //
    // Anything onStart() touches that is not (:glance) therefore does not
    // exist in the Glance's binary, and invoking it aborts the Glance process
    // natively with "Illegal Access (Out of Bounds) / Failed invoking
    // <symbol>" - not a catchable Lang.Exception. That was the real cause of
    // #47's permanently-blank Glance row: onStart() used to call
    // RunningPaceRefresh.run() (#40's foreground refresh) behind a 60s
    // throttle, so the Glance rendered fine for the first minute after an
    // open, then aborted on every render forever after, exactly as reported.
    //
    // Keep this method empty. Widget-only startup work belongs in
    // getInitialView() below, which is the one entry point the Glance and the
    // background service never call. See RESEARCH.md.
    function onStart(state as Dictionary?) as Void {
    }

    // onStop() is called when your application is exiting
    function onStop(state as Dictionary?) as Void {
    }

    // Return the initial view of your application here. The graph screen is
    // screen 1 (#29).
    //
    // This is also where all startup work lives (#47), moved here out of
    // onStart(). The Glance calls getGlanceView() and the background service
    // calls getServiceDelegate(); only a real widget open calls this, so
    // non-(:glance) code invoked here can never abort the 32kB Glance
    // process the way it did from onStart(). See onStart()'s comment.
    function getInitialView() as [Views] or [Views, InputDelegates] {
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
        var lastComputedAt = Application.Storage.getValue("runningPaceLastComputedAt") as Number?;
        var missingTrendWindowBoundaries = Application.Storage.getValue("runningPaceTrendCurrentWindowStartEpoch") == null;

        if (lastComputedAt == null || missingTrendWindowBoundaries) {
            // The only case that still refreshes SYNCHRONOUSLY, i.e. before
            // this method returns a view. There is nothing valid in Storage to
            // draw yet, and #37 found running-pace-trendView.mc reads the trend
            // window boundary keys with an unconditional `as Number` and
            // crashes on null - so an install that is fresh, or upgraded from a
            // version predating those keys, must be populated before any view
            // is handed back. This path runs once per install, not per open.
            RunningPaceRefresh.run();
        } else if (Time.now().value() - lastComputedAt >= FOREGROUND_REFRESH_THROTTLE_SECONDS) {
            // The ordinary "data is stale" case: Storage already holds a
            // complete, drawable result, so hand back the view immediately and
            // let RunningPaceForegroundRefresh re-run the scan on a one-shot
            // timer once the first frame is up (#47 follow-up). Running it
            // inline here instead is what made opening the app visibly slow
            // whenever more than FOREGROUND_REFRESH_THROTTLE_SECONDS had
            // passed since the last open - the activity-history scan sat
            // between the button press and the first pixel. See that class.
            RunningPaceForegroundRefresh.schedule();
        }

        return [ new RunningPaceTrendGraphView(), new RunningPaceTrendNavigationDelegate(RUNNING_PACE_TREND_PAGE_GRAPH) ];
    }

    (:glance)
    function getGlanceView() as [WatchUi.GlanceView] or [WatchUi.GlanceView, WatchUi.GlanceViewDelegate] or Null {
        return [ new RunningPaceGlanceView() ];
    }

    // Deliberately not annotated (:background) - see
    // RunningPaceBackgroundService.mc's comment.
    function getServiceDelegate() as [System.ServiceDelegate] {
        return [ new RunningPaceBackgroundService() ];
    }

}

function getApp() as running_pace_trendApp {
    return Application.getApp() as running_pace_trendApp;
}
