/*
c 2023-05-16
m 2023-05-20
*/

namespace Settings {
    [Setting name="Load my maps from file on boot"]
    bool loadMyMapsOnBoot = true;

    [Setting name="Load zones from file on boot"]
    bool loadZonesOnBoot = true;

    [Setting name="Print task durations to the log"]
    bool printDurations = false;

    [Setting name="Sort my maps by newest first"]
    bool sortMapsNewest = true;
    bool sortMapsNewestTemp = sortMapsNewest;
    bool DetectSortMapsNewest() {
        if (sortMapsNewestTemp != sortMapsNewest) {
            sortMapsNewestTemp = sortMapsNewest;
            return true;
        }
        return false;
    }

    [Setting name="Switch to map tab when clicked"]
    bool myMapsSwitchOnClicked = true;

    [Setting name="Show map names in tabs with color"]
    bool myMapsTabsColor = true;

    [Setting name="Thumbnail width (map list)" min=10 max=1000]
    uint myMapsThumbnailWidthList = 200;

    [Setting name="Thumbnail width (map page)" min=10 max=1000]
    uint myMapsThumbnailWidthPage = 200;

    [Setting hidden]
    bool windowOpen = true;
}