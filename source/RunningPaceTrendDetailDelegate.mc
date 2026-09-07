import Toybox.Lang;
import Toybox.WatchUi;

// Pairs with running_pace_trendView (the expanded Glance detail screen).
// Select pushes the trend graph screen (US-07 / #12) - the first interactive
// navigation in this app; the Glance itself stays non-interactive per
// glance-standards.md.
class RunningPaceTrendDetailDelegate extends WatchUi.BehaviorDelegate {

    function initialize() {
        BehaviorDelegate.initialize();
    }

    function onSelect() as Boolean {
        WatchUi.pushView(new RunningPaceTrendGraphView(), null, WatchUi.SLIDE_LEFT);
        return true;
    }

}
