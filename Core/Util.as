/*
c 2023-05-20
m 2023-09-19
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
        if (!UI::IsItemHovered()) return;
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

    void NotifyWarn(const string &in msg) {
        UI::ShowNotification("TMTracker", msg, UI::HSV(0.02, 0.8, 0.9));
    }

    string StrWrap(const string &in input, const string &in wrapper = "'") {
        return wrapper + input + wrapper;
    }

    void WaitToDoNadeoRequestCoro() {
        if (Globals::latestNadeoRequest == 0) {
            Globals::latestNadeoRequest = Time::Now;
            return;
        }

        while (Locks::requesting) yield();
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