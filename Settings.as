/*
c 2023-05-16
m 2023-05-20
*/

namespace Settings {
    ///////////////////////////////////////////////////////////////////////////
    // GENERAL
    ///////////////////////////////////////////////////////////////////////////
    [Setting name="Load my maps from file on boot" category="General"]
    bool loadMyMapsOnBoot = true;

    [Setting name="Load zones from file on boot" category="General"]
    bool loadZonesOnBoot = true;

    [Setting name="Print task durations to the log" category="General"]
    bool printDurations = false;

    ///////////////////////////////////////////////////////////////////////////
    // MAP LIST
    ///////////////////////////////////////////////////////////////////////////
    [Setting name="Sort maps by newest first" category="Map List"]
    bool sortMapsNewest = true;
    bool sortMapsNewestTemp = sortMapsNewest;
    bool DetectSortMapsNewest() {
        if (sortMapsNewestTemp != sortMapsNewest) {
            sortMapsNewestTemp = sortMapsNewest;
            return true;
        }
        return false;
    }

    [Setting name="Show map names with color" category="Map List"]
    bool myMapsListColor = true;

    [Setting name="Thumbnail width" category="Map List" min=10 max=1000]
    uint myMapsThumbnailWidthList = 200;

    ///////////////////////////////////////////////////////////////////////////
    // MAP TABS
    ///////////////////////////////////////////////////////////////////////////
    [Setting name="Show map names with color" category="Map Tabs"]
    bool myMapsTabsColor = true;

    [Setting name="Switch to map tab when clicked" category="Map Tabs"]
    bool myMapsSwitchOnClicked = true;

    [Setting name="Thumbnail width" category="Map Tabs" min=10 max=1000]
    uint myMapsThumbnailWidthTabs = 400;

    [Setting name="Max records to get per map" category="Map Tabs" min=100 max=1000 description="records are fetched in batches of 100 until this limit"]
    uint maxRecordsPerMap = 100;

    ///////////////////////////////////////////////////////////////////////////
    // HIDDEN
    ///////////////////////////////////////////////////////////////////////////
    [Setting hidden]
    string dateFormat = "%a \\$F98%Y-%m-%d \\$Z%H:%M:%S \\$F98";

    [Setting hidden]
    bool windowOpen = true;
}