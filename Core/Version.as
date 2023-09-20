/*
c 2023-09-19
m 2023-09-20
*/

namespace Version {
    int3 version;

    bool CheckFile() {
        // TO CHANGE WHEN TMTRACKER IS UPDATED
        // only if files are considered incompatible with new versions

        string timerId = Log::TimerBegin("checking version.json");

        int3 fileVersion = GetFile();
        if (
            fileVersion.x < 3 ||
            fileVersion.y < 1 ||
            fileVersion.z < 0
        ) {
            warn("old version detected");
            Files::Delete();
            Log::TimerEnd(timerId);
            return false;
        }

        Log::TimerEnd(timerId);
        SetFile();
        return true;
    }

    int3 FromToml() {
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
                warn("error reading version.json!");
                Files::Delete();
                return version;
            }
        } else {
            warn("version.json not found!");
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
        Json::ToFile(Files::version, write);

        Log::TimerEnd(timerId);
    }
}