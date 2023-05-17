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

    [Setting hidden]
    bool sortMapsNewest = true;

    [Setting hidden]
    bool windowOpen = true;
}