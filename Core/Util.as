/*
c 2023-05-20
m 2023-08-13
*/

namespace Util {
    void CheckFileVersion() {
        string timerId = LogTimerBegin("checking version.json");
        int3 version = GetFileVersion();

        // TO CHANGE WHEN TMTRACKER IS UPDATED
        // only if files are considered incompatible with new versions
        if (
            version.x < Globals::version.x ||
            version.y < Globals::version.y ||
            version.z < Globals::version.z
        ) {
            warn("old version detected");
            DeleteFiles();
        }

        LogTimerEnd(timerId);
        SetFileVersion();
    }

    void DeleteFiles() {
        warn("deleting TMTracker files for safety...");
        try { IO::Delete(Globals::hiddenMapsFile); } catch { }
        try { IO::Delete(Globals::mapRecordsTimestampsFile); } catch { }
        try { IO::Delete(Database::dbFile); } catch { }
        try { IO::Delete(Globals::versionFile); } catch { }
    }

    string FormatSeconds(int seconds, bool day = false, bool hour = false, bool minute = false) {
        int minutes = seconds / 60;
        seconds %= 60;
        int hours = minutes / 60;
        minutes %= 60;
        int days = hours / 24;
        hours %= 24;

        if (days > 0)
            return days + "d " + hours + "h " + minutes + "m " + seconds + "s";
        if (hours > 0)
            return (day ? "0d " : "") + hours + "h " + minutes + "m " + seconds + "s";
        if (minutes > 0)
            return (day ? "0d " : "") + (hour ? "0h " : "") + minutes + "m " + seconds + "s";
        return (day ? "0d " : "") + (hour ? "0h " : "") + (minute ? "0m " : "") + seconds + "s";
    }

    int3 GetFileVersion() {
        bool bad = false;
        if (IO::FileExists(Globals::versionFile)) {
            try {
                Json::Value read = Json::FromFile(Globals::versionFile);
                return int3(int(read["major"]), int(read["minor"]), int(read["patch"]));
            } catch {
                warn("error reading version.json!");
                bad = true;
            }
        } else {
            warn("version.json not found!");
            bad = true;
        }
        if (bad) {
            DeleteFiles();
            return Globals::version;
        }
        return int3(0, 0, 0);
    }

    void HoverTooltip(const string &in msg) {
        if (!UI::IsItemHovered()) return;
        UI::BeginTooltip();
            UI::Text(msg);
        UI::EndTooltip();
    }

    // courtesy of MisfitMaid
    int64 IsoToUnix(const string &in inTime) {
        auto s = Globals::timeDB.Prepare("SELECT unixepoch(?) as x");
        s.Bind(1, inTime);
        s.Execute();
        s.NextRow();
        s.NextRow();
        return s.GetColumnInt64("x");
    }

    string LogTimerBegin(const string &in text, bool logNow = true) {
        if (logNow) trace(text + "...");
        string timerId = Globals::logTimerIndex + "_LogTimer_" + text;
        Globals::logTimerIndex++;
        Globals::logTimers.Set(timerId, Time::Now);
        return timerId;
    }

    void LogTimerDelete(const string &in timerId) {
        try { Globals::logTimers.Delete(timerId); } catch { }
    }

    uint64 LogTimerEnd(const string &in timerId, bool logNow = true) {
        uint64 dur;
        if (logNow) {
            string text = timerId.Split("_LogTimer_")[1];
            uint64 start;
            if (Globals::logTimers.Get(timerId, start)) {
                dur = Time::Now - start;
                if (dur == 0)
                    trace(text + " took 0s");
                else
                    trace(text + " took " + (dur / 1000) + "." + (dur % 1000) + "s");
            } else {
                trace("timerId not found: " + timerId);
            }
        }
        LogTimerDelete(timerId);
        return dur;
    }

    void NotifyWarn(const string &in msg) {
        UI::ShowNotification("TMTracker", msg, UI::HSV(0.02, 0.8, 0.9));
    }

    void SetFileVersion() {
        string timerId = LogTimerBegin("setting version.json");

        Json::Value write = Json::Object();
        write["major"] = Globals::version.x;
        write["minor"] = Globals::version.y;
        write["patch"] = Globals::version.z;
        Json::ToFile(Globals::versionFile, write);

        LogTimerEnd(timerId);
    }

    string StrWrap(const string &in input, const string &in wrapper = "'") {
        return wrapper + input + wrapper;
    }

    void WaitToDoNadeoRequestCoro() {
        if (Globals::latestNadeoRequest == 0) {
            Globals::latestNadeoRequest = Time::Now;
            return;
        }

        while (Locks::requesting)
            yield();
        Locks::requesting = true;

        while (Time::Now - Globals::latestNadeoRequest < Settings::timeBetweenNadeoRequests)
            yield();

        Globals::latestNadeoRequest = Time::Now;
    }

    string Zpad2(int num) {
        if (num > 9) return "" + num;
        return "0" + num;
    }
}