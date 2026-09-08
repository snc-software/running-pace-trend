import Toybox.Application;
import Toybox.Background;
import Toybox.System;
import Toybox.Time;

// Thin ServiceDelegate wrapper around the fixed local-midnight background
// temporal event (#40): the actual compute-and-persist work lives in
// RunningPaceRefresh, which is also invoked from
// running_pace_trendApp.onStart() on a foreground open (#36, #40) so the trend
// graph doesn't have to wait for this event's next tick.
// running-pace-trendApp registers this event with a Time.Moment (the next
// local midnight) rather than the pre-#40 rolling Duration, and a Moment fires
// only once, so this delegate re-arms the following midnight on every firing.
// Also records its own outcome (chore/debug-screen) into Application.Storage -
// when it last ran, whether it succeeded, and how many attempts it took -
// separately from RunningPaceRefresh's own runningPaceLastComputedAt (which
// the foreground onStart() refresh updates too), so the debug screen can show
// the midnight schedule's health in isolation.
//
// Annotated (:background) (#47), deliberately on this class alone. Without
// any (:background) tag anywhere, despite the Background permission, the app
// compiled with "the entire application will be loaded as a background
// process" and a real device crashed with "Illegal Access (Out of Bounds) /
// Failed invoking <symbol>" (confirmed via an on-device crash log) -
// RESEARCH.md's pre-existing, previously-unfixed crash class. (:background)
// is additive, not exclusive, so this class stays fully available to the
// foreground app too.
//
// This one tag is enough to silence that compiler warning on its own -
// RunningPaceRefresh and everything downstream of it (RunningActivityHistoryReader,
// RunningPaceCalculator, RunningPaceDayBoundary, etc.) deliberately stay
// untagged. Tagging that whole call graph was tried first and instead
// introduced a NEW, reproducible-in-the-simulator crash at onStart() (the
// same "Illegal Access" abort, hit via RunningPaceBackgroundSchedule ->
// RunningPaceDayBoundary) - two separate fresh simulator runs with only this
// class tagged stayed crash-free. Untagged code already gets compiled into
// every scope's binary by default, so tagging it too gains nothing and, per
// RESEARCH.md, changing a shared class's annotations can itself shift the
// compiled layout enough to trip this failure. Don't re-add tags downstream
// of this class without re-running that bisection.
(:background)
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
        // only from onStart(), and calling it from this background entry point
        // too crashes the app at runtime (see RunningPaceBackgroundSchedule
        // and RESEARCH.md). RunningPaceDayBoundary is already reached from
        // both scopes via RunningPaceRefresh.run(), so it is safe here.
        Background.registerForTemporalEvent(RunningPaceDayBoundary.startOfDay(Time.now()).add(new Time.Duration(SECONDS_PER_DAY)) as Time.Moment);

        // The Glance reads Application.Storage directly and never consumes
        // onBackgroundData (see RESEARCH.md), so there's nothing to hand back here.
        Background.exit(null);
    }

}
