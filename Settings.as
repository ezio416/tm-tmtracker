/*
c 2023-05-16
m 2023-05-20
*/

namespace Settings {
    [Setting name="Load my maps from file on boot" category="General"]
    bool loadMyMapsOnBoot = true;

    [Setting name="Load zones from file on boot" category="General"]
    bool loadZonesOnBoot = true;

    [Setting name="Print task durations to the log" category="General"]
    bool printDurations = false;

    [Setting name="Sort my maps by newest first" category="General"]
    bool sortMapsNewest = true;
    bool sortMapsNewestTemp = sortMapsNewest;
    bool DetectSortMapsNewest() {
        if (sortMapsNewestTemp != sortMapsNewest) {
            sortMapsNewestTemp = sortMapsNewest;
            return true;
        }
        return false;
    }

    [Setting name="Switch to map tab when clicked" category="General"]
    bool myMapsSwitchOnClicked = true;

    [Setting name="Show map names with color in map list" category="General"]
    bool myMapsListColor = true;

    [Setting name="Show map names with color in tabs" category="General"]
    bool myMapsTabsColor = true;

    [Setting name="Max records to get per map" category="General" min=100 max=1000 description="records are fetched in batches of 100 until this limit"]
    uint maxRecordsPerMap = 100;

    [Setting name="Thumbnail width in main 'Map List' tab" category="Thumbnails" min=10 max=1000]
    uint myMapsThumbnailWidthList = 200;

    [Setting name="Thumbnail width in map-specific tab" category="Thumbnails" min=10 max=1000]
    uint myMapsThumbnailWidthTabs = 200;

    [Setting hidden]
    bool windowOpen = true;
}