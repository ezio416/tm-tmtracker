/*
c 2023-05-20
m 2023-07-17
*/

namespace Util {
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

    // courtesy of MisfitMaid
    int64 IsoToUnix(const string &in inTime) {
        auto st = Globals::timeDB.Prepare("SELECT unixepoch(?) as x");
        st.Bind(1, inTime);
        st.Execute();
        st.NextRow();
        st.NextRow();
        return st.GetColumnInt64("x");
    }

    dictionary JsonLoadToDict(const string &in filename) {
        string timerId = LogTimerBegin("loading json file");
        Json::Value json;
        dictionary dict;

        try {
            json = Json::FromFile(filename);
        } catch {
            Warn("json file missing!");
            return dict;
        }

        auto keys = json.GetKeys();
        for (uint i = 0; i < json.Length; i++) {
            auto key = keys[i];
            auto val = json.Get(key);
            dict.Set(key, string(val));
        }
        LogTimerEnd(timerId);
        return dict;
    }

    void JsonSaveFromDict(dictionary dict, const string &in filename) {
        string timerId = LogTimerBegin("saving json file");
        Json::ToFile(filename, dict.ToJson());
        LogTimerEnd(timerId);
    }

    string LogTimerBegin(const string &in text, bool logNow = true) {
        if (logNow) Trace(text + "...");
        string timerId = Globals::logTimerIndex + "_LogTimer_" + text;
        Globals::logTimerIndex++;
        Globals::logTimers.Set(timerId, Time::Now);
        return timerId;
    }

    void LogTimerDelete(const string &in timerId) {
        try { Globals::logTimers.Delete(timerId); } catch { }
    }

    void LogTimerEnd(const string &in timerId, bool logNow = true) {
        if (Settings::logDurations && logNow) {
            string text = timerId.Split("_LogTimer_")[1];
            uint64 start;
            if (Globals::logTimers.Get(timerId, start)) {
                uint64 dur = Time::Now - start;
                if (dur == 0)
                    Trace(text + " took 0s");
                else
                    Trace(text + " took " + (dur / 1000) + "." + (dur % 1000) + "s");
            } else {
                Trace("timerId not found: " + timerId);
            }
        }
        LogTimerDelete(timerId);
    }

    void NotifyWarn(const string &in msg) {
        UI::ShowNotification("TMTracker", msg, UI::HSV(0.02, 0.8, 0.9));
    }

    string StrWrap(const string &in input, const string &in wrapper = "'") {
        return wrapper + input + wrapper;
    }

    void Trace(const string &in text) {
        if (!Settings::logEnabled) return;
        trace(text);
    }

    void WaitToDoNadeoRequestCoro() {
        if (Globals::latestNadeoRequest == 0) {
            Globals::latestNadeoRequest = Time::Now;
            return;
        }

        while (Globals::requesting)
            yield();
        Globals::requesting = true;

        while (Time::Now - Globals::latestNadeoRequest < Settings::timeBetweenNadeoRequests)
            yield();

        Globals::latestNadeoRequest = Time::Now;
    }

    void Warn(const string &in text) {
        if (!Settings::logEnabled) return;
        warn(text);
    }

    string Zpad2(int num) {
        if (num > 9) return "" + num;
        return "0" + num;
    }
}