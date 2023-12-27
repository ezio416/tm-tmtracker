// c 2023-09-19
// m 2023-10-12

namespace Version {
    int3 version;

    bool CheckFile() {
        string timerId = Log::TimerBegin("checking version.json");

        int3 fileVersion = GetFile();
        if (
            fileVersion.x < 3 ||
            fileVersion.y < 1 ||
            fileVersion.z < 0
        ) {
            Log::Write(Log::Level::Warnings, "old version detected: " + tostring(fileVersion));
            Files::Delete();
            Log::TimerEnd(timerId);
            return false;
        }

        Log::TimerEnd(timerId);
        SetFile();
        return true;
    }

    void FromToml() {
        if (version.x > 0)
            return;

        string[]@ parts = Meta::ExecutingPlugin().Version.Split(".");
        version = int3(Text::ParseInt(parts[0]), Text::ParseInt(parts[1]), Text::ParseInt(parts[2]));
    }

    int3 GetFile() {
        string timerId = Log::TimerBegin("loading version.json");

        int3 readVersion;

        FromToml();

        if (IO::FileExists(Files::version)) {
            try {
                Json::Value@ read = Json::FromFile(Files::version);
                readVersion = int3(int(read["major"]), int(read["minor"]), int(read["patch"]));
            } catch {
                Log::Write(Log::Level::Errors, "error loading version.json! " + getExceptionInfo());
                Files::Delete();
                Log::TimerDelete(timerId);
                return version;
            }
        } else {
            Log::Write(Log::Level::Warnings, "file not found: version.json");
            Files::Delete();
            Log::TimerDelete(timerId);
            return version;
        }

        Log::TimerEnd(timerId);
        return readVersion;
    }

    void SetFile() {
        string timerId = Log::TimerBegin("saving version.json");

        FromToml();

        Json::Value write = Json::Object();
        write["major"] = version.x;
        write["minor"] = version.y;
        write["patch"] = version.z;

        try {
            Json::ToFile(Files::version, write);
        } catch {
            Log::Write(Log::Level::Errors, "error saving version.json! " + getExceptionInfo());
            Log::TimerDelete(timerId);
            return;
        }

        Log::TimerEnd(timerId);
    }
}