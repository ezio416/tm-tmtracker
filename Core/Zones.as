/*
c 2023-05-16
m 2023-05-25
*/

namespace Zones {
    void Load() {
        auto now = Time::Now;

        try {
            Storage::zones.Length;
            return;
        } catch { }

        if (Settings::loggingEnabled)
            trace("loading zones from file...");

        try {
            Storage::zones = Json::FromFile("Resources/zones.json");
            Storage::zonesFileMissing = false;
        } catch {
            trace("missing zones file!");
            return;
        }

        if (Settings::loggingEnabled && Settings::logDurations)
            trace("loading zones took " + (Time::Now - now) + " ms");
    }
}