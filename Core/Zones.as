/*
c 2023-05-16
m 2023-10-12
*/

namespace Zones {
    Json::Value@ zones;

    string Get(const string &in zoneId) {
        try {
            return string(zones.Get(zoneId));
        } catch {
            return "unknown-zone";
        }
    }

    void Load() {
        try {
            zones.Length;
            return;
        } catch { }

        string timerId = Log::TimerBegin("loading zones.json");

        try {
            @zones = Json::FromFile(Files::zones);
        } catch {
            Log::Write(Log::Level::Warnings, "zones.json not found!");
            Log::TimerDelete(timerId);
            return;
        }

        Log::TimerEnd(timerId);
    }
}