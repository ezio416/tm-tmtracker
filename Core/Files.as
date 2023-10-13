/*
c 2023-09-19
m 2023-10-12
*/

namespace Files {
    string db                   = storageFolder + "TMTracker.db";
    string hiddenMaps           = storageFolder + "hiddenMaps.json";
    string mapRecordsTimestamps = storageFolder + "mapRecordsTimestamps.json";
    string storageFolder        = IO::FromStorageFolder("").Replace("\\", "/");
    string thumbnailFolder      = storageFolder + "thumbnails";
    string version              = storageFolder + "version.json";
    string zones                = "Assets/zones.json";

    void Delete() {
        Log::Write(Log::Level::Warnings, "deleting TMTracker files for safety...");

        try {
            IO::Delete(db);
        } catch {
            Log::Write(Log::Level::Debug, "failed to delete database file - " + getExceptionInfo());
        }

        try {
            IO::Delete(hiddenMaps);
        } catch {
            Log::Write(Log::Level::Debug, "failed to delete hidden maps file - " + getExceptionInfo());
        }

        try {
            IO::Delete(mapRecordsTimestamps);
        } catch {
            Log::Write(Log::Level::Debug, "failed to delete record timestamp file - " + getExceptionInfo());
        }

        try {
            IO::Delete(version);
        } catch {
            Log::Write(Log::Level::Debug, "failed to delete version file - " + getExceptionInfo());
        }
    }

    void LoadHiddenMaps() {
        string timerId = Log::TimerBegin("loading hiddenMaps.json");

        if (IO::FileExists(Files::hiddenMaps)) {
            try {
                Globals::hiddenMapsJson = Json::FromFile(Files::hiddenMaps);
            } catch {
                Log::Write(Log::Level::Errors, "error loading hiddenMaps.json! " + getExceptionInfo());
            }
        } else {
            Log::Write(Log::Level::Warnings, "file not found: hiddenMaps.json");
        }

        Log::TimerEnd(timerId);
    }

    void LoadRecordsTimestamps() {
        string timerId = Log::TimerBegin("loading mapRecordsTimestamps.json");

        if (IO::FileExists(Files::mapRecordsTimestamps)) {
            try {
                Globals::recordsTimestampsJson = Json::FromFile(Files::mapRecordsTimestamps);
            } catch {
                Log::Write(Log::Level::Errors, "error loading mapRecordsTimestamps.json! " + getExceptionInfo());
            }
        } else {
            Log::Write(Log::Level::Warnings, "file not found: mapRecordsTimestamps.json");
        }

        Log::TimerEnd(timerId);
    }

    void SaveHiddenMaps() {
        string timerId = Log::TimerBegin("saving hiddenMaps.json");

        try {
            Json::ToFile(hiddenMaps, Globals::hiddenMapsJson);
        } catch {
            Log::Write(Log::Level::Errors, "error saving hiddenMaps.json! " + getExceptionInfo());
            Log::TimerDelete(timerId);
            return;
        }

        Log::TimerEnd(timerId);
    }

    void SaveRecordsTimestamps() {
        string timerId = Log::TimerBegin("saving mapRecordsTimestamps.json");

        try {
            Json::ToFile(Files::mapRecordsTimestamps, Globals::recordsTimestampsJson);
        } catch {
            Log::Write(Log::Level::Errors, "error saving mapRecordsTimestamps.json! " + getExceptionInfo());
            Log::TimerDelete(timerId);
            return;
        }

        Log::TimerEnd(timerId);
    }
}