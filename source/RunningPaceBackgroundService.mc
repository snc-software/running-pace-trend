import Toybox.Background;
import Toybox.System;

// Thin ServiceDelegate wrapper around the recurring background temporal
// event: the actual compute-and-persist work lives in RunningPaceRefresh,
// which is also invoked synchronously on first launch from
// running_pace_trendApp.onStart() (#36) so the trend graph doesn't have to
// wait for this event's first tick.
// running-pace-trendApp registers the recurring temporal event with a
// Duration, which the platform repeats automatically, so this delegate does
// not need to re-register itself on every firing.
class RunningPaceBackgroundService extends System.ServiceDelegate {

    function initialize() {
        System.ServiceDelegate.initialize();
    }

    function onTemporalEvent() as Void {
        RunningPaceRefresh.run();

        // The Glance reads Application.Storage directly and never consumes
        // onBackgroundData (see RESEARCH.md), so there's nothing to hand back here.
        Background.exit(null);
    }

}
