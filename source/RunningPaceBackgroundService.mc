import Toybox.Application;
import Toybox.Background;
import Toybox.System;
import Toybox.Time;

// Thin ServiceDelegate wrapper around the fixed local-midnight background
// temporal event (#40): the actual compute-and-persist work lives in
// RunningPaceRefresh, which is also invoked from
// running_pace_trendApp.getInitialView() on a foreground open (#36, #40;
// moved there from onStart() by #47) so the trend graph doesn't have to wait
// for this event's next tick.
// running-pace-trendApp registers this event with a Time.Moment (the next
// local midnight) rather than the pre-#40 rolling Duration, and a Moment fires
// only once, so this delegate re-arms the following midnight on every firing.
// Also records its own outcome (chore/debug-screen) into Application.Storage -
// when it last ran, whether it succeeded, and how many attempts it took -
// separately from RunningPaceRefresh's own runningPaceLastComputedAt (which
// the foreground open refresh updates too), so the debug screen can show
// the midnight schedule's health in isolation.
//
// Deliberately NOT annotated (:background), despite the build warning that
// "the entire application will be loaded as a background process" (#47).
// That warning was chased hard as the suspected cause of a real-device
// "Illegal Access (Out of Bounds) / Failed invoking <symbol>" crash, and
// annotating - both this class alone and its whole call graph - was tried
// and did not fix it: successive crash logs kept landing at the same place
// with and without the tags. The actual cause was a Glance-scope symbol
// error in running_pace_trendApp.onStart(); see that file's comment and
// RESEARCH.md. Leaving this untagged keeps the app in the state it has
// always shipped in, where every scope's binary contains everything, and
// avoids re-shuffling compiled layout for no proven benefit. The warning is
// cosmetic here - treat it as a separate cleanup, not a bug.
class RunningPaceBackgroundService extends System.ServiceDelegate {

    // "retry 3 times" (#40) taken as up to 4 total attempts - the first
    // attempt plus 3 retries - stopping as soon as one succeeds.
    private static const MAX_REFRESH_ATTEMPTS = 4;

    private static const SECONDS_PER_DAY = 86400;

    function initialize() {
        System.ServiceDelegate.initialize();
    }

    function onTemporalEvent() as Void {
        var attempt = 0;
        var succeeded = false;
        while (!succeeded && attempt < MAX_REFRESH_ATTEMPTS) {
            succeeded = RunningPaceRefresh.run();
            attempt++;
        }

        Application.Storage.setValue("runningPaceLastMidnightRefreshAt", Time.now().value());
        Application.Storage.setValue("runningPaceLastMidnightRefreshSucceeded", succeeded);
        Application.Storage.setValue("runningPaceLastMidnightRefreshAttempts", attempt);

        // Computed here from RunningPaceDayBoundary rather than via
        // RunningPaceBackgroundSchedule.nextMidnight(): that class is reached
        // only from getInitialView(), and #40 found that calling it from this
        // background entry point too crashed the app at runtime (see
        // RunningPaceBackgroundSchedule and RESEARCH.md). RunningPaceDayBoundary
        // is already reached from both scopes via RunningPaceRefresh.run(), so
        // it is safe here.
        Background.registerForTemporalEvent(RunningPaceDayBoundary.startOfDay(Time.now()).add(new Time.Duration(SECONDS_PER_DAY)) as Time.Moment);

        // The Glance reads Application.Storage directly and never consumes
        // onBackgroundData (see RESEARCH.md), so there's nothing to hand back here.
        Background.exit(null);
    }

}
