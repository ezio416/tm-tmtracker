/*
c 2023-09-19
m 2023-09-19
*/

namespace Files {
    string db                   = storageFolder + "TMTracker.db";
    string hiddenMaps           = storageFolder + "hiddenMaps.json";
    string mapRecordsTimestamps = storageFolder + "mapRecordsTimestamps.json";
    string storageFolder        = IO::FromStorageFolder("").Replace("\\", "/");
    string thumbnailFolder      = storageFolder + "thumbnails";
    string version              = storageFolder + "version.json";

    void Delete() {
        warn("deleting TMTracker files for safety...");
        try { IO::Delete(hiddenMaps); } catch { }
        try { IO::Delete(mapRecordsTimestamps); } catch { }
        try { IO::Delete(db); } catch { }
        try { IO::Delete(version); } catch { }
    }
}