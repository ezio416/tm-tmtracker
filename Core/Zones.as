/*
c 2023-05-16
m 2023-07-07
*/

namespace Zones {
    string Get(const string &in zoneId) {
        try   { return string(Globals::zones.Get(zoneId)); }
        catch { return "unknown-zone"; }
    }

    void Load() {
        try {
            Globals::zones.Length;
            return;
        } catch { }

        string timerId = Util::LogTimerBegin("loading zones from file");

        try {
            Globals::zones = Json::FromFile(Globals::zonesFile);
            Globals::zonesFileMissing = false;
        } catch {
            Util::Trace("missing zones file!");
            Util::LogTimerEnd(timerId, false);
            return;
        }

        Util::LogTimerEnd(timerId);
    }
}