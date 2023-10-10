/*
c 2023-09-19
m 2023-10-09
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

    void SaveHiddenMaps() {
        Log::Write(Log::Level::Debug, "saving hiddenMaps.json...");

        try {
            Json::ToFile(hiddenMaps, Globals::hiddenMapsJson);
        } catch {
            Log::Write(Log::Level::Errors, "error saving hiddenMaps.json! " + getExceptionInfo());
        }
    }

    void SaveRecordsTimestamps() {
        Log::Write(Log::Level::Debug, "saving mapRecordsTimestamps.json...");

        try {
            Json::ToFile(Files::mapRecordsTimestamps, Globals::recordsTimestampsJson);
        } catch {
            Log::Write(Log::Level::Errors, "error saving mapRecordsTimestamps.json! " + getExceptionInfo());
        }
    }
}