import Toybox.Application;
import Toybox.Background;
import Toybox.Lang;
import Toybox.System;
import Toybox.Time;

// Runs outside the Glance's execution budget (glance-standards.md Data Refresh),
// computing the weighted pace and caching it to Application.Storage for
// RunningPaceGlanceView to read. running-pace-trendApp registers the recurring
// temporal event with a Duration, which the platform repeats automatically, so
// this delegate does not need to re-register itself on every firing.
class RunningPaceBackgroundService extends System.ServiceDelegate {

    function initialize() {
        System.ServiceDelegate.initialize();
    }

    function onTemporalEvent() as Void {
        try {
            var reader = new RunningActivityHistoryReader();
            var records = reader.readAll();
            var now = Time.now();
            var result = RunningPaceCalculator.calculate(records, now);
            var trendResult = RunningPaceTrendCalculator.compare(records, now);

            Application.Storage.setValue("runningPaceHasSufficientData", result["runningPaceHasSufficientData"] as Boolean);
            Application.Storage.setValue("runningPaceSecondsPerKm", result["runningPaceSecondsPerKm"] as Number?);
            Application.Storage.setValue("runningPaceLastComputedAt", result["runningPaceLastComputedAt"] as Number);
            Application.Storage.setValue("runningPaceTotalDistanceMeters", result["runningPaceTotalDistanceMeters"] as Number?);
            Application.Storage.setValue("runningPaceQualifyingActivityCount", result["runningPaceQualifyingActivityCount"] as Number?);

            Application.Storage.setValue("runningPaceTrendHasSufficientData", trendResult["runningPaceTrendHasSufficientData"] as Boolean);
            Application.Storage.setValue("runningPaceTrendDirection", trendResult["runningPaceTrendDirection"] as Number?);
            Application.Storage.setValue("runningPaceTrendDeltaSecondsPerKm", trendResult["runningPaceTrendDeltaSecondsPerKm"] as Number?);
            Application.Storage.setValue("runningPaceTrendCurrentSecondsPerKm", trendResult["runningPaceTrendCurrentSecondsPerKm"] as Number?);
            Application.Storage.setValue("runningPaceTrendPreviousSecondsPerKm", trendResult["runningPaceTrendPreviousSecondsPerKm"] as Number?);
            Application.Storage.setValue("runningPaceTrendPercentChangeTenths", trendResult["runningPaceTrendPercentChangeTenths"] as Number?);
        } catch (exception instanceof Lang.Exception) {
            // Leave any previously computed Storage values in place rather than
            // overwrite good data with a transient read failure; the Glance keeps
            // showing the last successful result until the next scheduled refresh.
        }

        // The Glance reads Application.Storage directly and never consumes
        // onBackgroundData (see RESEARCH.md), so there's nothing to hand back here.
        Background.exit(null);
    }

}
