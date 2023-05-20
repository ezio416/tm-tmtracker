/*
c 2023-05-16
m 2023-05-20
*/

namespace Zones {
    void Load() {
        auto now = Time::Now;

        try {
            Storage::zones.Length;
            return;
        } catch { }

        try {
            Storage::zones = Json::FromFile('Resources/zones.json');
            Storage::zonesFileMissing = false;
        } catch {
            trace("missing zones file!");
            return;
        }

        if (Settings::printDurations)
            trace("loading zones took " + (Time::Now - now) + " ms");
    }
}