/*
c 2023-05-16
m 2023-05-19
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

    [Setting name="Thumbnail width" min=10 max=1000]
    uint myMapsThumbnailWidth = 200;

    [Setting hidden]
    bool windowOpen = true;
}