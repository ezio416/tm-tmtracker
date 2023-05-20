/*
c 2023-05-16
m 2023-05-19
*/

namespace Storage {
    // Models::Account[] accounts;
    Models::Map[]     currentMap;
    SQLite::Database@ db;
    string            dbFile = IO::FromStorageFolder("TMTracker.db").Replace("\\", "/");
    Models::Map[]     myMaps;
    Models::Map[]     myMapsHidden;
    dictionary        myMapsHiddenUids;
    // Models::Record[]  records;
    string            thumbnailFolder = IO::FromStorageFolder("thumbnails");
    string            title  = "\\$2f3" + Icons::MapO + "\\$z TMTracker";
    Json::Value       zones;

    void ClearCurrentMap() {
        Storage::currentMap.RemoveRange(0, Storage::currentMap.Length);
    }

    void ClearMyMaps() {
        Storage::myMaps.RemoveRange(0, Storage::myMaps.Length);
    }

    void ClearMyMapsHidden() {
        Storage::myMapsHidden.RemoveRange(0, Storage::myMapsHidden.Length);
    }
}