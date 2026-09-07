import Toybox.Lang;

enum {
    RUNNING_PACE_TREND_PAGE_GRAPH,
    RUNNING_PACE_TREND_PAGE_DETAIL
}

// Pure geometry for the hand-drawn page-indicator dots shown on the left edge
// of both Running Trend screens, mirroring the native Training Status
// widget's own page dots - Connect IQ's WatchUi has no built-in page
// indicator component (#29), so each screen draws these itself. Decoupled
// from Dc so the dot layout is unit testable (coding-standards.md Testing
// section); the views remain responsible for the actual
// dc.fillCircle/drawCircle calls, matching this project's existing pattern
// of a *Content class supplying pure geometry/state to a thin View.
class RunningPaceTrendPageIndicatorContent {

    static const TOTAL_PAGES = 2;
    static const ACTIVE_DOT_RADIUS = 3;
    static const INACTIVE_DOT_RADIUS = 2;

    private static const DOT_SPACING = 12;

    // Returns TOTAL_PAGES vertical offsets from the screen's vertical center,
    // one per page in page-index order, evenly spaced by DOT_SPACING so the
    // dot stack is centered on the display regardless of TOTAL_PAGES.
    static function buildDotCenterYOffsets() as Array<Number> {
        var offsets = [] as Array<Number>;
        var totalSpan = (TOTAL_PAGES - 1) * DOT_SPACING;
        var start = -(totalSpan / 2);
        for (var i = 0; i < TOTAL_PAGES; i++) {
            offsets.add(start + (i * DOT_SPACING));
        }
        return offsets;
    }

}
