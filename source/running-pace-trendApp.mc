import Toybox.Application;
import Toybox.Background;
import Toybox.Lang;
import Toybox.System;
import Toybox.Time;
import Toybox.WatchUi;

class running_pace_trendApp extends Application.AppBase {

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

        // Subscribe to the OS's activity-completed event (#49), so a finished
        // run refreshes the trend data in background scope and the Glance shows
        // it without the widget being opened at all.
        //
        // This CORRECTS a claim that stood in this comment from #40 until #49:
        // that there is no confirmed Connect IQ "activity completed" event a
        // separate widget can subscribe to. There is.
        // Background.registerForActivityCompletedEvent() and
        // System.ServiceDelegate.onActivityCompleted() have existed since SDK
        // 3.0.10, well below this app's declared minApiLevel of 6.0.0, and both
        // appear in fr970's own device API table - not just the generic SDK
        // docs. The same false claim reached RESEARCH.md and #40's plan and is
        // corrected in both. It mattered: believing it is what put a 2.7-second
        // synchronous history scan on the foreground path in the first place,
        // and every regression from v1.7.5 to v1.7.9 was an attempt to find
        // somewhere on the UI thread to put it. There isn't one.
        //
        // Guarded so an existing registration is left alone. Also re-asserted
        // from RunningPaceBackgroundService.onTemporalEvent(), so a registration
        // lost to a reboot heals at the next midnight rather than waiting for
        // the user to open the widget.
        if (!Background.getActivityCompletedEventRegistered()) {
            Background.registerForActivityCompletedEvent();
        }

        // The fresh-install refresh, and since #49 the ONLY history scan on any
        // foreground path. The on-open refresh that used to sit alongside it -
        // #40's, deferred to a post-first-frame timer and then chunked across
        // ticks by #47's follow-up - is gone, replaced by the background event
        // registered above.
        //
        // What remains is CRASH SAFETY, not a staleness optimisation, which is
        // why it could not go with it: #37 found running-pace-trendView.mc reads
        // the trend window boundary keys with an unconditional `as Number` and
        // crashes on null, so an install that is fresh, or upgraded from a
        // version predating those keys, must be populated before any view is
        // handed back. It cannot be delegated to the activity-completed event
        // either - a fresh install has no completed activity to wait for, and
        // midnight could be 23 hours away.
        //
        // It refreshes SYNCHRONOUSLY, before this method returns a view, and
        // blocks for the whole ~2.7s. That is acceptable only because it runs
        // once per install rather than per open, and because there is nothing
        // valid in Storage to draw until it finishes.
        var lastComputedAt = Application.Storage.getValue("runningPaceLastComputedAt") as Number?;
        var missingTrendWindowBoundaries = Application.Storage.getValue("runningPaceTrendCurrentWindowStartEpoch") == null;

        if (lastComputedAt == null || missingTrendWindowBoundaries) {
            RunningPaceRefresh.run();
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
