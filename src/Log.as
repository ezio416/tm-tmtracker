namespace Log {
    dictionary@ timers      = dictionary();
    uint        timersCount = 0;

    enum Level {
        Errors,
        Warnings,
        Normal,
        Durations,
        Debug
    }

    string TimerBegin(const string &in text) {
        Write(Level::Normal, text + "...");

        string timerId = timersCount + "_LogTimer_" + text;
        timers.Set(timerId, Time::Now);
        timersCount++;

        return timerId;
    }

    void TimerDelete(const string &in timerId) {
        try {
            timers.Delete(timerId);
        } catch {
            Write(Level::Debug, "delete timerId (" + timerId + ") failed: " + getExceptionInfo());
        }
    }

    uint64 TimerEnd(const string &in timerId) {
        uint64 start;
        uint64 dur;

        string text = timerId.Split("_LogTimer_")[1];

        if (timers.Get(timerId, start)) {
            dur = Time::Now - start;
            if (dur == 0)
                Write(Level::Durations, text + " took 0s");
            else
                Write(Level::Durations, text + " took " + (dur / 1000) + "." + (dur % 1000) + "s");
        } else
            Write(Level::Warnings, "timerId not found: " + timerId);

        TimerDelete(timerId);

        return dur;
    }

    void Write(Level level, const string &in msg) {
        switch (level) {
            case Level::Errors:
                error(msg);
                break;
            case Level::Warnings:
                if (Settings::logLevel >= Level::Warnings)
                    warn(msg);
                break;
            case Level::Normal:
                if (Settings::logLevel >= Level::Normal)
                    trace(msg);
                break;
            case Level::Durations:
                if (Settings::logLevel >= Level::Durations)
                    trace(msg);
                break;
            default:
                if (Settings::logLevel == Level::Debug)
                    trace(msg);
        }
    }
}
