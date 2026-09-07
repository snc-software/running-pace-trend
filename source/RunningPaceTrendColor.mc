import Toybox.Graphics;
import Toybox.Lang;

// Maps a RUNNING_PACE_TREND_DIRECTION_* value (already computed by
// RunningPaceTrendCalculator and cached in Application.Storage) to the color
// used to render it on the graph screen's trend line (#29 follow-up): green
// for an improving (faster) trend, red for a declining (slower) trend, blue
// for an unchanged/stable trend. Falls back to white when no trend direction
// is available yet, matching the graph line's original default color.
class RunningPaceTrendColor {

    static function forDirection(direction as Number?) as Graphics.ColorType {
        if (direction == RUNNING_PACE_TREND_DIRECTION_FASTER) {
            return Graphics.COLOR_GREEN;
        } else if (direction == RUNNING_PACE_TREND_DIRECTION_SLOWER) {
            return Graphics.COLOR_RED;
        } else if (direction == RUNNING_PACE_TREND_DIRECTION_UNCHANGED) {
            return Graphics.COLOR_BLUE;
        }
        return Graphics.COLOR_WHITE;
    }

    // A lighter tint of forDirection()'s color, for the graph screen's
    // area-under-the-line fill (#29 redesign) - full alpha, not a
    // transparency blend, so it renders consistently regardless of whether
    // a device supports alpha compositing. Falls back to light gray,
    // matching forDirection()'s own white (not green/red/blue) fallback for
    // "no trend data yet".
    static function lightForDirection(direction as Number?) as Graphics.ColorType {
        if (direction == RUNNING_PACE_TREND_DIRECTION_FASTER) {
            return Graphics.createColor(255, 170, 255, 170);
        } else if (direction == RUNNING_PACE_TREND_DIRECTION_SLOWER) {
            return Graphics.createColor(255, 255, 170, 170);
        } else if (direction == RUNNING_PACE_TREND_DIRECTION_UNCHANGED) {
            return Graphics.createColor(255, 170, 170, 255);
        }
        return Graphics.COLOR_LT_GRAY;
    }

}
