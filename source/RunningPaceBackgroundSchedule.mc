import Toybox.Lang;
import Toybox.Time;

// Pure scheduling math for the fixed local-midnight background refresh (#40),
// replacing the pre-#40 rolling ~24h Duration interval that drifted with
// whatever time of day the app happened to be installed at.
//
// Deliberately reached only from running_pace_trendApp.onStart() - never from
// RunningPaceBackgroundService.onTemporalEvent(). This app used to compile
// with "the 'Background' permission was enabled but no source code was
// annotated. The entire application will be loaded as a background process",
// which leaves the foreground and background scopes disagreeing about symbol
// layout; a class reached from both entry points trips "Illegal Access (Out
// of Bounds) / Failed invoking <symbol>" at runtime - confirmed on a real
// device (#47). The background service therefore computes its own
// next-midnight value from RunningPaceDayBoundary directly.
//
// #47 added a single (:background) tag on RunningPaceBackgroundService (see
// its own comment) to silence that compiler warning, but deliberately did NOT
// touch RunningPaceDayBoundary, RunningPaceRefresh, or anything else this
// class or that one call into - tagging that whole call graph was tried first
// and newly introduced a reproducible onStart() crash in the simulator hitting
// this exact class. RESEARCH.md's own conclusion is that this failure tracks
// compiled layout, not semantics, and isn't predictable from source, so this
// split stays in place as a cheap, proven-safe precaution rather than
// something to unwind now that one tag exists elsewhere. See RESEARCH.md.
class RunningPaceBackgroundSchedule {

    private static const SECONDS_PER_DAY = 86400;

    static function nextMidnight(now as Time.Moment) as Time.Moment {
        return RunningPaceDayBoundary.startOfDay(now).add(new Time.Duration(SECONDS_PER_DAY)) as Time.Moment;
    }

}
