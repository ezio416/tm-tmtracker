/*
c 2023-05-16
m 2023-05-17
*/

namespace Zones {
    void Load() {
        auto now = Time::Now;

        Storage::zones = Json::FromFile('Resources/zones.json');

        if (Settings::printDurations)
            trace("loading zones took " + (Time::Now - now) + " ms");
    }
}