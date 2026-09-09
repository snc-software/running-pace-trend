import Toybox.Lang;
import Toybox.WatchUi;

// Shared paging delegate for the app's four screens (#29, extended to a third
// by chore/debug-screen and a fourth by #49): the graph screen
// (RUNNING_PACE_TREND_PAGE_GRAPH, screen 1 / the app's initial view), the
// detail screen (RUNNING_PACE_TREND_PAGE_DETAIL, screen 2), the midnight-refresh
// debug screen (RUNNING_PACE_TREND_PAGE_DEBUG, screen 3), and the
// activity-completed event screen (RUNNING_PACE_TREND_PAGE_ACTIVITY, screen 4).
// Replaces the old Select-only navigation - a fresh instance is paired with each
// view via getInitialView()/switchToView(), constructed with which page it
// currently represents so onNextPage()/onPreviousPage() know which sibling
// screen to switch to. Pages cycle in enum order (Graph -> Detail -> Debug ->
// Activity -> Graph) via modulo arithmetic over
// RunningPaceTrendPageIndicatorContent.TOTAL_PAGES, so adding the fourth screen
// meant only appending to the enum, bumping TOTAL_PAGES and adding a branch to
// buildView() below. No onSelect() override - Select no longer navigates
// anywhere, per the issue's planned fix (also resolves #28, since the
// "SELECT: graph" hint has nothing left to explain).
class RunningPaceTrendNavigationDelegate extends WatchUi.BehaviorDelegate {

    private var _currentPage as Number;

    function initialize(currentPage as Number) {
        BehaviorDelegate.initialize();
        _currentPage = currentPage;
    }

    function onNextPage() as Boolean {
        switchPage(WatchUi.SLIDE_UP, 1);
        return true;
    }

    function onPreviousPage() as Boolean {
        switchPage(WatchUi.SLIDE_DOWN, -1);
        return true;
    }

    private function switchPage(transition as WatchUi.SlideType, step as Number) as Void {
        var totalPages = RunningPaceTrendPageIndicatorContent.TOTAL_PAGES;
        var targetPage = ((_currentPage + step) % totalPages + totalPages) % totalPages;
        WatchUi.switchToView(buildView(targetPage), new RunningPaceTrendNavigationDelegate(targetPage), transition);
    }

    private function buildView(page as Number) as WatchUi.View {
        if (page == RUNNING_PACE_TREND_PAGE_GRAPH) {
            return new RunningPaceTrendGraphView();
        } else if (page == RUNNING_PACE_TREND_PAGE_DETAIL) {
            return new running_pace_trendView();
        } else if (page == RUNNING_PACE_TREND_PAGE_DEBUG) {
            return new RunningPaceDebugView();
        } else {
            return new RunningPaceActivityEventView();
        }
    }

}
