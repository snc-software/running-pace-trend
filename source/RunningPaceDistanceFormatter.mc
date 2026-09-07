import Toybox.Lang;

// Pure display formatting, decoupled from the View so it can be unit tested
// without a device (coding-standards.md Testing section).
class RunningPaceDistanceFormatter {

    private static const METERS_PER_KM = 1000;

    // Formats whole meters as kilometres to one decimal place, e.g. 86400 -> "86.4".
    // Integer tenths-of-a-km math, avoiding Float per coding-standards.md's Memory
    // and Performance section.
    static function format(distanceMeters as Number) as String {
        var tenthsOfKm = (distanceMeters * 10 + METERS_PER_KM / 2) / METERS_PER_KM;
        var wholeKm = tenthsOfKm / 10;
        var remainderTenths = tenthsOfKm % 10;

        return wholeKm.toString() + "." + remainderTenths.toString();
    }

}
