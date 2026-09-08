import Toybox.Graphics;
import Toybox.Lang;

// Maps a RUNNING_PACE_TREND_DIRECTION_* value (already computed by
// RunningPaceTrendCalculator and cached in Application.Storage) to the color
// used to render it on the graph screen's trend line (#29 follow-up): green
// for an improving (faster) trend, red for a declining (slower) trend, blue
// for an unchanged/stable trend. Falls back to white when no trend direction
// is available yet, matching the graph line's original default color.
//
// Annotated (:glance) (#27) since RunningPaceGlanceView now also calls
// forDirection() for its trend badge - without this annotation the
// glance's isolated compilation unit doesn't include this class, and the
// call fails at runtime with "Illegal Access (Out of Bounds)".
(:glance)
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

    // A subtle, translucent-looking tint of forDirection()'s color, for the
    // graph screen's area-under-the-line fill (#29 redesign). Dc.setColor
    // only accepts an opaque 24-bit RGB value for direct drawing (per the
    // Connect IQ API docs) - createColor()'s alpha channel isn't honored
    // there the way it is for BufferedBitmap compositing, so real alpha
    // blending against the plot's black background isn't available here.
    // Transparency is instead simulated by manually blending each vivid
    // base hue toward black at a fixed ~35% opacity (channel * 0.35,
    // rounded) - low enough to read as a subtle glow rather than the solid
    // block the previous, brighter tint produced (#29 feedback round 4,
    // point 3). Falls back to light gray, matching forDirection()'s own
    // white (not green/red/blue) fallback for "no trend data yet".
    static function lightForDirection(direction as Number?) as Graphics.ColorType {
        if (direction == RUNNING_PACE_TREND_DIRECTION_FASTER) {
            return Graphics.createColor(255, 14, 81, 32);
        } else if (direction == RUNNING_PACE_TREND_DIRECTION_SLOWER) {
            return Graphics.createColor(255, 81, 16, 21);
        } else if (direction == RUNNING_PACE_TREND_DIRECTION_UNCHANGED) {
            return Graphics.createColor(255, 21, 56, 81);
        }
        return Graphics.COLOR_LT_GRAY;
    }

}
