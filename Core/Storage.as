/*
c 2023-05-16
m 2023-05-20
*/

namespace Storage {
    Models::Map[]     currentMaps;
    dictionary        currentMapsUids;
    SQLite::Database@ db;
    string            dbFile = IO::FromStorageFolder("TMTracker.db").Replace("\\", "/");
    UI::Texture@      defaultTexture = UI::LoadTexture("Resources/1x1.png");
    uint64            latestNadeoRequest = 0;
    bool              mapClicked = false;
    Models::Map[]     myMaps;
    Models::Map[]     myMapsHidden;
    dictionary        myMapsHiddenUids;
    int               requestsInProgress = 0;
    string            thumbnailFolder = IO::FromStorageFolder("thumbnails");
    dictionary        thumbnailTextures;
    string            title  = "\\$2f3" + Icons::MapO + "\\$z TMTracker";
    Json::Value       zones;
    bool              zonesFileMissing = true;

    void ClearCurrentMaps() {
        currentMaps.RemoveRange(0, currentMaps.Length);
    }

    void ClearCurrentMapsUids() {
        currentMapsUids.DeleteAll();
    }

    void ClearMyMaps() {
        myMaps.RemoveRange(0, myMaps.Length);
    }

    void ClearMyMapsHidden() {
        myMapsHidden.RemoveRange(0, myMapsHidden.Length);
    }

    void ClearMyMapsHiddenUids() {
        myMapsHiddenUids.DeleteAll();
    }
}