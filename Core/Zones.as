/*
c 2023-05-16
m 2023-05-26
*/

// Functions for player regions
namespace Zones {
    void Load() {
        try {
            Globals::zones.Length;
            return;
        } catch { }

        string timerId = Various::LogTimerBegin("loading zones from file");

        try {
            Globals::zones = Json::FromFile("Assets/zones.json");
            Globals::zonesFileMissing = false;
        } catch {
            if (Settings::logEnabled)
                trace("missing zones file!");
            Various::LogTimerEnd(timerId, false);
            return;
        }

        Various::LogTimerEnd(timerId);
    }
}