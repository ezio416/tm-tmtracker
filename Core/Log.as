/*
c 2023-09-19
m 2023-09-19
*/

namespace Log {
    uint64     timerIndex = 0;
    dictionary timers;

    string TimerBegin(const string &in text, bool logNow = true) {
        if (logNow) trace(text + "...");
        string timerId = timerIndex + "_LogTimer_" + text;
        timerIndex++;
        timers.Set(timerId, Time::Now);
        return timerId;
    }

    void TimerDelete(const string &in timerId) {
        try { timers.Delete(timerId); } catch { }
    }

    uint64 TimerEnd(const string &in timerId, bool logNow = true) {
        uint64 dur;
        if (logNow) {
            string text = timerId.Split("_LogTimer_")[1];
            uint64 start;
            if (timers.Get(timerId, start)) {
                dur = Time::Now - start;
                if (dur == 0)
                    trace(text + " took 0s");
                else
                    trace(text + " took " + (dur / 1000) + "." + (dur % 1000) + "s");
            } else {
                trace("timerId not found: " + timerId);
            }
        }
        TimerDelete(timerId);
        return dur;
    }
}