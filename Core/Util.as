/*
c 2023-05-20
m 2023-10-11
*/

namespace Util {
    SQLite::Database@ timeDB = SQLite::Database(":memory:");

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

    void HoverTooltip(const string &in msg) {
        if (!UI::IsItemHovered())
            return;

        UI::BeginTooltip();
            UI::Text(msg);
        UI::EndTooltip();
    }

    // courtesy of MisfitMaid
    int64 IsoToUnix(const string &in inTime) {
        auto s = timeDB.Prepare("SELECT unixepoch(?) as x");
        s.Bind(1, inTime);
        s.Execute();
        s.NextRow();
        s.NextRow();
        return s.GetColumnInt64("x");
    }

    void NandoRequestWaitCoro() {
        if (Globals::latestNandoRequest == 0) {
            Globals::latestNandoRequest = Time::Now;
            return;
        }

        while (Locks::requesting)
            yield();
        Locks::requesting = true;

        while (Time::Now - Globals::latestNandoRequest < Settings::nandoRequestWait)
            yield();

        Globals::latestNandoRequest = Time::Now;
    }

    void NotifyError(const string &in msg, int time = 5000) {
        UI::ShowNotification("TMTracker", msg, UI::HSV(0.02, 0.8, 0.9), time);
        Log::Write(Log::Level::Errors, msg);
    }

    string StrWrap(const string &in input, const string &in wrapper = "'") {
        return wrapper + input + wrapper;
    }

    string TimeFormatColored(int time) {
        return (time > 0 ? "\\$F00+" : "\\$0F0-") + Time::Format(Math::Abs(time));
    }

    void TmioMap(const string &in mapUid) {
        Log::Write(Log::Level::Debug, "opening Trackmania.io for map " + mapUid);
        OpenBrowserURL("https://trackmania.io/#/leaderboard/" + mapUid);
    }

    void TmioPlayer(const string &in accountId) {
        Log::Write(Log::Level::Debug, "opening Trackmania.io for player " + accountId);
        OpenBrowserURL("https://trackmania.io/#/player/" + accountId);
    }

    string UnixToIso(uint timestamp, const string &in format = "%Y-%m-%d %H:%M:%S \\$AAA(%a)") {
        return Time::FormatString(format, timestamp);
    }

    string Zpad2(int num) {
        if (num > 9)
            return "" + num;
        return "0" + num;
    }
}