/*
c 2023-09-19
m 2023-09-19
*/

namespace Version {
    string file = Globals::storageFolder + "version.json";
    int3   version;

    bool CheckFile() {
        // TO CHANGE WHEN TMTRACKER IS UPDATED
        // only if files are considered incompatible with new versions

        // string timerId = Log::TimerBegin("checking version.json");

        // int3 fileVersion = GetFile();
        // if (
        //     fileVersion.x < version.x ||
        //     fileVersion.y < version.y ||
        //     fileVersion.z < version.z
        // ) {
        //     warn("old version detected");
        //     Util::DeleteFiles();
        //     Log::TimerEnd(timerId);
        //     return false;
        // }

        // Log::TimerEnd(timerId);
        SetFile();
        return true;
    }

    int3 FromToml() {
        string[]@ parts = Meta::ExecutingPlugin().Version.Split(".");
        version = int3(Text::ParseInt(parts[0]), Text::ParseInt(parts[1]), Text::ParseInt(parts[2]));
        return version;
    }

    // int3 GetFile() {
    //     if (IO::FileExists(Globals::versionFile)) {
    //         try {
    //             Json::Value@ read = Json::FromFile(Globals::versionFile);
    //             return int3(int(read["major"]), int(read["minor"]), int(read["patch"]));
    //         } catch {
    //             warn("error reading version.json!");
    //             Util::DeleteFiles();
    //             return FromToml();
    //         }
    //     } else {
    //         warn("version.json not found!");
    //         Util::DeleteFiles();
    //         return FromToml();
    //     }
    // }

    void SetFile() {
        string timerId = Log::TimerBegin("setting version.json");

        Json::Value write = Json::Object();
        write["major"] = version.x;
        write["minor"] = version.y;
        write["patch"] = version.z;
        Json::ToFile(file, write);

        Log::TimerEnd(timerId);
    }
}