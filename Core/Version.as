/*
c 2023-09-19
m 2023-10-09
*/

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

    int3 FromToml() {
        if (version.x > 0)
            return version;

        string[]@ parts = Meta::ExecutingPlugin().Version.Split(".");
        version = int3(Text::ParseInt(parts[0]), Text::ParseInt(parts[1]), Text::ParseInt(parts[2]));
        return version;
    }

    int3 GetFile() {
        FromToml();

        if (IO::FileExists(Files::version)) {
            try {
                Json::Value@ read = Json::FromFile(Files::version);
                return int3(int(read["major"]), int(read["minor"]), int(read["patch"]));
            } catch {
                Log::Write(Log::Level::Errors, "error reading version.json! " + getExceptionInfo());
                Files::Delete();
                return version;
            }
        } else {
            Log::Write(Log::Level::Warnings, "file not found: version.json");
            Files::Delete();
            return version;
        }
    }

    void SetFile() {
        string timerId = Log::TimerBegin("setting version.json");

        FromToml();

        Json::Value write = Json::Object();
        write["major"] = version.x;
        write["minor"] = version.y;
        write["patch"] = version.z;
        try {
            Json::ToFile(Files::version, write);
        } catch {
            Log::Write(Log::Level::Errors, "error setting version.json! " + getExceptionInfo());
            Log::TimerDelete(timerId);
            return;
        }

        Log::TimerEnd(timerId);
    }
}