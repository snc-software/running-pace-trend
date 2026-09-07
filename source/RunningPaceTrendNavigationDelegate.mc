import Toybox.Lang;
import Toybox.WatchUi;

// Shared paging delegate for the app's two screens (#29): the graph screen
// (RUNNING_PACE_TREND_PAGE_GRAPH, screen 1 / the app's initial view) and the
// detail screen (RUNNING_PACE_TREND_PAGE_DETAIL, screen 2). Replaces the old
// Select-only navigation - a fresh instance is paired with each view via
// getInitialView()/switchToView(), constructed with which page it currently
// represents so onNextPage()/onPreviousPage() know which sibling screen to
// switch to. Only two screens exist today, so both directions toggle to the
// other one; this is not meant to generalise past two pages without
// revisiting the toggle logic below. No onSelect() override - Select no
// longer navigates anywhere, per the issue's planned fix (also resolves #28,
// since the "SELECT: graph" hint has nothing left to explain).
class RunningPaceTrendNavigationDelegate extends WatchUi.BehaviorDelegate {

    private var _currentPage as Number;

    function initialize(currentPage as Number) {
        BehaviorDelegate.initialize();
        _currentPage = currentPage;
    }

    function onNextPage() as Boolean {
        switchPage(WatchUi.SLIDE_UP);
        return true;
    }

    function onPreviousPage() as Boolean {
        switchPage(WatchUi.SLIDE_DOWN);
        return true;
    }

    private function switchPage(transition as WatchUi.SlideType) as Void {
        if (_currentPage == RUNNING_PACE_TREND_PAGE_GRAPH) {
            WatchUi.switchToView(new running_pace_trendView(), new RunningPaceTrendNavigationDelegate(RUNNING_PACE_TREND_PAGE_DETAIL), transition);
        } else {
            WatchUi.switchToView(new RunningPaceTrendGraphView(), new RunningPaceTrendNavigationDelegate(RUNNING_PACE_TREND_PAGE_GRAPH), transition);
        }
    }

}
