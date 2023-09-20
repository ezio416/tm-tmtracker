/*
c 2023-05-16
m 2023-09-19
*/

namespace Zones {
    string      file = "Assets/zones.json";
    Json::Value zones;

    string Get(const string &in zoneId) {
        try   { return string(zones.Get(zoneId)); }
        catch { return "unknown-zone"; }
    }

    void Load() {
        try {
            zones.Length;
            return;
        } catch { }

        string timerId = Log::TimerBegin("loading zones.json");

        try {
            zones = Json::FromFile(file);
        } catch {
            trace("zones.json not found! ");
            Log::TimerEnd(timerId, false);
            return;
        }

        Log::TimerEnd(timerId);
    }
}