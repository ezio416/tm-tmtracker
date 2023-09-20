/*
c 2023-05-16
m 2023-09-19
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

        string timerId = Log::TimerBegin("loading zones.json");

        try {
            Globals::zones = Json::FromFile(Globals::zonesFile);
            Globals::zonesFileMissing = false;
        } catch {
            trace("zones.json not found! ");
            Log::TimerEnd(timerId, false);
            return;
        }

        Log::TimerEnd(timerId);
    }
}