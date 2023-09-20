/*
c 2023-09-19
m 2023-09-19
*/

namespace Version {
    bool CheckFile() {
        // TO CHANGE WHEN TMTRACKER IS UPDATED
        // only if files are considered incompatible with new versions

        // string timerId = Log::TimerBegin("checking version.json");

        // int3 version = GetFile();
        // if (
        //     version.x < Globals::version.x ||
        //     version.y < Globals::version.y ||
        //     version.z < Globals::version.z
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
        Globals::version = int3(Text::ParseInt(parts[0]), Text::ParseInt(parts[1]), Text::ParseInt(parts[2]));
        return Globals::version;
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
        write["major"] = Globals::version.x;
        write["minor"] = Globals::version.y;
        write["patch"] = Globals::version.z;
        Json::ToFile(Globals::versionFile, write);

        Log::TimerEnd(timerId);
    }
}