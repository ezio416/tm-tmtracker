/*
c 2023-05-16
m 2023-05-26
*/

namespace Zones {
    void Load() {
        try {
            Storage::zones.Length;
            return;
        } catch { }

        string timerId = Various::LogTimerStart("loading zones from file");

        try {
            Storage::zones = Json::FromFile("Assets/zones.json");
            Storage::zonesFileMissing = false;
        } catch {
            if (Settings::logEnabled)
                trace("missing zones file!");
            Various::LogTimerEnd(timerId, false);
            return;
        }

        Various::LogTimerEnd(timerId);
    }
}