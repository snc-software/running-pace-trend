import Toybox.Activity;
import Toybox.Application;
import Toybox.Background;
import Toybox.Lang;
import Toybox.System;
import Toybox.Time;

// Thin ServiceDelegate wrapper around the two background events that keep the
// trend data fresh. Since #49 these are the only two things that refresh it,
// and both are in background scope:
//
//  - onActivityCompleted() fires when a run finishes, so the Glance shows the
//    new run's numbers without the widget being opened at all.
//  - onTemporalEvent() is the fixed local-midnight backstop (#40), which
//    catches anything the event missed - a run synced in from another device,
//    or an event the OS suppressed under battery saver.
//
// The event is an optimisation over the backstop, never a replacement for it.
//
// The actual compute-and-persist work lives in RunningPaceRefresh, which is
// also invoked from running_pace_trendApp.getInitialView() on a fresh or
// upgraded install (#36, #40; moved out of onStart() by #47) where there is
// nothing drawable in Storage yet. #49 deleted the on-open refresh that used to
// run on every stale open.
//
// running-pace-trendApp registers the temporal event with a Time.Moment (the
// next local midnight) rather than the pre-#40 rolling Duration, and a Moment
// fires only once, so this delegate re-arms the following midnight on every
// firing.
//
// Both handlers record their own outcome into Application.Storage - under
// separate key prefixes, runningPaceLastMidnightRefresh* and
// runningPaceLastActivityEvent* - so the two debug screens can show each
// schedule's health in isolation rather than from RunningPaceRefresh's shared
// runningPaceLastComputedAt, which either of them updates.
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
        // Re-assert the activity-completed registration (#49). getInitialView()
        // registers it too, but a registration lost to a reboot or a firmware
        // update would otherwise stay lost until the user next opened the
        // widget - and the whole point of the event is that they no longer have
        // to. Doing it here means it self-heals within a day. Guarded so an
        // already-live registration is left alone.
        _registerForActivityCompletedEvent();

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

    // Fires when any activity finishes (#49). `activity` is a Dictionary
    // carrying :sport as a Toybox.Activity.Sport and :subSport as a
    // Toybox.Activity.SubSport; only :sport matters here.
    //
    // This runs in the same scope as onTemporalEvent(), on the same delegate,
    // in the same binary, and reaches RunningPaceRefresh.run() by the same call
    // graph that has worked every midnight since #40. It is NOT a repeat of
    // #47's Glance-scope trap, which was about a separate 32kB binary that
    // simply does not contain this code.
    //
    // ONE THING IS UNVERIFIED, deliberately (#49): whether
    // UserProfile.getUserActivityHistory() already includes the just-finished
    // activity by the time this fires. The SDK does not say, and the simulator
    // is not a trusted oracle for this app - it failed to reproduce #47 across
    // five rounds. Rather than guessing at a guard, this handler records enough
    // for ONE recorded run to answer it: if the retained count below does not go
    // up after a run, the event raced the history write. The fix at that point
    // is either a short delay here or a one-shot temporal event a few minutes
    // out; neither is built speculatively. The cost of being wrong is stale data
    // until midnight - pre-#40 behaviour - not a crash.
    function onActivityCompleted(activity as Dictionary) as Void {
        var sport = activity[:sport];

        Application.Storage.setValue("runningPaceLastActivityEventAt", Time.now().value());
        Application.Storage.setValue("runningPaceLastActivityEventSport", sport);

        if (sport != Activity.SPORT_RUNNING) {
            // Nothing this app tracks changed, so don't spend ~2.7s of
            // background CPU scanning history that cannot have gained a run.
            // RunningPaceCalculator filters on the same Activity.SPORT_RUNNING
            // value, so a non-run would be discarded there anyway - this just
            // discards it before the scan rather than after.
            Application.Storage.setValue("runningPaceLastActivityEventOutcome", RUNNING_PACE_ACTIVITY_EVENT_SKIPPED_NOT_RUNNING);
            Application.Storage.setValue("runningPaceLastActivityEventScannedCount", null);
            Application.Storage.setValue("runningPaceLastActivityEventRetainedCount", null);
            Background.exit(null);
            return;
        }

        var succeeded = RunningPaceRefresh.run();

        if (succeeded) {
            // Copied out of the keys run() just wrote, so the activity page
            // reports THIS firing's scan rather than whichever refresh ran most
            // recently. Without the copy a midnight refresh landing afterwards
            // would silently restate its own counts under this event's
            // timestamp, which is exactly the reading that has to be trusted to
            // settle the history-write race above.
            Application.Storage.setValue("runningPaceLastActivityEventOutcome", RUNNING_PACE_ACTIVITY_EVENT_REFRESHED);
            Application.Storage.setValue("runningPaceLastActivityEventScannedCount", Application.Storage.getValue("runningPaceLastScanScannedCount") as Number?);
            Application.Storage.setValue("runningPaceLastActivityEventRetainedCount", Application.Storage.getValue("runningPaceLastScanRetainedCount") as Number?);
        } else {
            // No retry loop, unlike the midnight path. That retry exists because
            // a missed midnight tick means a whole day of stale data; a missed
            // activity event just means the run shows up at midnight instead.
            Application.Storage.setValue("runningPaceLastActivityEventOutcome", RUNNING_PACE_ACTIVITY_EVENT_REFRESH_FAILED);
            Application.Storage.setValue("runningPaceLastActivityEventScannedCount", null);
            Application.Storage.setValue("runningPaceLastActivityEventRetainedCount", null);
        }

        Background.exit(null);
    }

    // Registers for the activity-completed event unless it already is.
    // Duplicated in running_pace_trendApp.getInitialView() rather than shared:
    // #40 found that reaching a shared class from this background entry point
    // crashed at runtime, and while #47 later suggested that diagnosis may have
    // been a scope error misattributed, it has not been re-tested and two lines
    // of Background calls are not worth the risk of finding out. Same reasoning
    // as the two temporal-schedule call sites, which #49 likewise left split.
    private function _registerForActivityCompletedEvent() as Void {
        if (!Background.getActivityCompletedEventRegistered()) {
            Background.registerForActivityCompletedEvent();
        }
    }

}
