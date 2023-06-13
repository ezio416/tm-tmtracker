/*
c 2023-05-16
m 2023-06-13
*/

// Functions for player regions
namespace Zones {
    void Load() {
        try {
            Globals::zones.Length;
            return;
        } catch { }

        string timerId = Util::LogTimerBegin("loading zones from file");

        try {
            Globals::zones = Json::FromFile("Assets/zones.json");
            Globals::zonesFileMissing = false;
        } catch {
            Util::Trace("missing zones file!");
            Util::LogTimerEnd(timerId, false);
            return;
        }

        Util::LogTimerEnd(timerId);
    }
}