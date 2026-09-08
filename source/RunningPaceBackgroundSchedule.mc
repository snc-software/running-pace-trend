import Toybox.Lang;
import Toybox.Time;

// Pure scheduling math for the fixed local-midnight background refresh (#40),
// replacing the pre-#40 rolling ~24h Duration interval that drifted with
// whatever time of day the app happened to be installed at.
//
// Deliberately reached only from running_pace_trendApp.onStart() - never from
// RunningPaceBackgroundService.onTemporalEvent(). This app compiles with "the
// 'Background' permission was enabled but no source code was annotated. The
// entire application will be loaded as a background process", which leaves the
// foreground and background scopes disagreeing about symbol layout; a class
// reached from both entry points trips "Illegal Access (Out of Bounds) /
// Failed invoking <symbol>" at runtime. The background service therefore
// computes its own next-midnight value from RunningPaceDayBoundary directly.
// See RESEARCH.md.
class RunningPaceBackgroundSchedule {

    private static const SECONDS_PER_DAY = 86400;

    static function nextMidnight(now as Time.Moment) as Time.Moment {
        return RunningPaceDayBoundary.startOfDay(now).add(new Time.Duration(SECONDS_PER_DAY)) as Time.Moment;
    }

}
