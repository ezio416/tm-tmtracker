// c 2023-05-20
// m 2024-01-19

namespace Util {
    uint64            latestNandoRequest = 0;
    SQLite::Database@ timeDB             = SQLite::Database(":memory:");

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
        SQLite::Statement@ s = timeDB.Prepare("SELECT unixepoch(?) as x");
        s.Bind(1, inTime);
        s.Execute();
        s.NextRow();
        s.NextRow();
        return s.GetColumnInt64("x");
    }

    void NandoRequestWaitCoro() {
        if (latestNandoRequest == 0) {
            latestNandoRequest = Time::Now;
            return;
        }

        while (Locks::requesting)
            yield();
        Locks::requesting = true;

        while (Time::Now - latestNandoRequest < Settings::nandoRequestWait)
            yield();

        latestNandoRequest = Time::Now;
    }

    void NotifyError(const string &in msg, int time = 5000) {
        UI::ShowNotification("TMTracker", msg, vec4(0.8f, 0.1f, 0.1f, 0.8f), time);
        Log::Write(Log::Level::Errors, msg);
    }

    void NotifyGood(const string &in msg) {
        UI::ShowNotification("TMTracker", msg, vec4(0.1f, 0.8f, 0.3f, 0.8f));
        Log::Write(Log::Level::Normal, msg);
    }

    string StrWrap(const string &in input, const string &in wrapper = "'") {
        return wrapper + input + wrapper;
    }

    string TimeFormatColored(int time) {
        return (time > 0 ? "\\$F00+" : "\\$0F0\u2212") + Time::Format(Math::Abs(time));
    }

    void TmioMap(const string &in mapUid) {
        Log::Write(Log::Level::Debug, "opening Trackmania.io for map " + mapUid);
        OpenBrowserURL("https://trackmania.io/#/leaderboard/" + mapUid);
    }

    void TmioPlayer(const string &in accountId) {
        Log::Write(Log::Level::Debug, "opening Trackmania.io for player " + accountId);
        OpenBrowserURL("https://trackmania.io/#/player/" + accountId);
    }

    string UnixToIso(uint timestamp, bool split = false) {
        return Time::FormatString(split ? Globals::dateFormatSplit : Globals::dateFormat, timestamp);
    }
}
