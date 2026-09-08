import Toybox.Lang;
import Toybox.Time;

// Pure scheduling math for the fixed local-midnight background refresh (#40),
// replacing the pre-#40 rolling ~24h Duration interval that drifted with
// whatever time of day the app happened to be installed at.
//
// Deliberately reached only from running_pace_trendApp.getInitialView() -
// never from RunningPaceBackgroundService.onTemporalEvent(), which computes
// its own next-midnight value from RunningPaceDayBoundary directly. That
// split dates from #40, when a class reached from both entry points was
// believed to trip "Illegal Access (Out of Bounds) / Failed invoking
// <symbol>" at runtime.
//
// #47 later found the real mechanism behind that error class in this app: it
// is a SCOPE error, not a layout one. Invoking a symbol that is not compiled
// into the currently-running scope's binary - most easily hit from the
// Glance's separate 32kB scope - aborts the process natively. This class is
// not (:glance), which is exactly why its caller had to move out of
// onStart() (called in every scope, Glance included) and into
// getInitialView() (widget-only). See running-pace-trendApp.mc and
// RESEARCH.md. The single-entry-point split here is kept as-is: it costs
// nothing and keeps this class's reachability trivially easy to reason about.
class RunningPaceBackgroundSchedule {

    private static const SECONDS_PER_DAY = 86400;

    static function nextMidnight(now as Time.Moment) as Time.Moment {
        return RunningPaceDayBoundary.startOfDay(now).add(new Time.Duration(SECONDS_PER_DAY)) as Time.Moment;
    }

}
