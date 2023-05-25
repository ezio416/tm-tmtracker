/*
c 2023-05-20
m 2023-05-25
*/

// Functions that don't fit nicely in other categories
namespace Various {
    string FormatSeconds(int seconds) {
        int minutes = seconds / 60;
        seconds %= 60;
        int hours = minutes / 60;
        minutes %= 60;
        int days = hours / 24;
        hours %= 24;

        if (days > 0)
            return Zpad2(days) + ":" + Zpad2(hours) + ":" + Zpad2(minutes) + ":" + Zpad2(seconds);
        if (hours > 0)
            return "00:" + Zpad2(hours) + ":" + Zpad2(minutes) + ":" + Zpad2(seconds);
        if (minutes > 0)
            return "00:00:" + Zpad2(minutes) + ":" + Zpad2(seconds);
        return "00:00:00:" + Zpad2(seconds);
    }

    string LogTimerStart(const string &in text, bool logNow = true) {
        auto now = Time::Now;
        if (Settings::logEnabled && logNow) trace(text + "...");
        string timerId = Storage::logTimerIndex + "_LogTimer_" + text;
        Storage::logTimerIndex++;
        Storage::logTimers.Set(timerId, now);
        return timerId;
    }

    void LogTimerDelete(const string &in timerId) {
        try { Storage::logTimers.Delete(timerId); } catch { }
    }

    void LogTimerEnd(const string &in timerId) {
        string text = timerId.Split("_LogTimer_")[1];
        if (Settings::logEnabled && Settings::logDurations) {
            try {
                uint64 dur = Time::Now - uint64(Storage::logTimers[timerId]);
                if (dur == 0) trace(text + " took 0s");
                else          trace(text + " took " + (dur / 1000) + "." + (dur % 1000) + "s");
            } catch {
                trace("timerId not found: " + timerId);
            }
        }
        LogTimerDelete(timerId);
    }

    void WaitToDoNadeoRequestCoro() {
        if (Storage::latestNadeoRequest == 0) {
            Storage::latestNadeoRequest = Time::Now;
            return;
        }

        while (Storage::requestsInProgress > 0)
            yield();
        if (Storage::requestsInProgress < 0)  // hopefully won't happen
            Storage::requestsInProgress = 0;
        Storage::requestsInProgress++;

        while (Time::Now - Storage::latestNadeoRequest < Settings::timeBetweenNadeoRequests)
            yield();

        Storage::latestNadeoRequest = Time::Now;
    }

    string Zpad2(int num) {
        if (num > 9) return "" + num;
        return "0" + num;
    }
}