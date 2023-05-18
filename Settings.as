/*
c 2023-05-16
m 2023-05-17
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

    [Setting hidden]
    bool windowOpen = true;
}