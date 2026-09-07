import Toybox.Lang;
import Toybox.Test;

(:test)
function returnsOneOffsetPerPage(logger as Logger) as Boolean {
    var offsets = RunningPaceTrendPageIndicatorContent.buildDotCenterYOffsets();
    Test.assertEqualMessage(offsets.size(), RunningPaceTrendPageIndicatorContent.TOTAL_PAGES, "one offset must be returned per page");
    return true;
}

(:test)
function centersTheDotStackOnZero(logger as Logger) as Boolean {
    var offsets = RunningPaceTrendPageIndicatorContent.buildDotCenterYOffsets();
    var sum = 0;
    for (var i = 0; i < offsets.size(); i++) {
        sum += offsets[i];
    }
    Test.assertEqualMessage(sum, 0, "the dot stack must be centered around the vertical midpoint (offsets sum to zero)");
    return true;
}

(:test)
function ordersOffsetsAscendingTopToBottom(logger as Logger) as Boolean {
    var offsets = RunningPaceTrendPageIndicatorContent.buildDotCenterYOffsets();
    for (var i = 1; i < offsets.size(); i++) {
        Test.assertMessage(offsets[i] > offsets[i - 1], "each page's dot must sit below the previous page's dot");
    }
    return true;
}
