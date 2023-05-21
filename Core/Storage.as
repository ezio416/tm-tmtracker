/*
c 2023-05-16
m 2023-05-20
*/

// Global variables for plugin operation, as well as functions to add/clear
namespace Storage {
    Models::Account[] accounts;
    dictionary        accountIds;
    Models::Map@[]    currentMaps;
    dictionary        currentMapsUids;
    SQLite::Database@ db;
    string            dbFile = IO::FromStorageFolder("TMTracker.db").Replace("\\", "/");
    UI::Texture@      defaultTexture = UI::LoadTexture("Resources/1x1.png");
    uint64            latestNadeoRequest = 0;
    bool              mapClicked = false;
    Models::Map[]     myMaps;
    dictionary        myMapsUids;
    Models::Map[]     myMapsHidden;
    dictionary        myMapsHiddenUids;
    Models::Record[]  records;
    dictionary        recordIds;
    int               requestsInProgress = 0;
    string            thumbnailFolder = IO::FromStorageFolder("thumbnails");
    dictionary        thumbnailTextures;
    string            title = "\\$2f3" + Icons::MapO + "\\$z TMTracker";
    Json::Value       zones;
    bool              zonesFileMissing = true;

    void AddMyMap(Models::Map map) {
        if (myMapsUids.Exists(map.mapUid)) return;
        myMapsUids.Set(map.mapUid, myMapsUids.GetKeys().Length);
        map.hidden = false;
        myMaps.InsertLast(map);
    }

    void AddMyMapHidden(Models::Map map) {
        if (myMapsHiddenUids.Exists(map.mapUid)) return;
        myMapsHiddenUids.Set(map.mapUid, "");
        map.hidden = true;
        myMapsHidden.InsertLast(map);
    }

    void AddRecord(Models::Record record) {
        if (recordIds.Exists(record.recordFakeId)) return;
        recordIds.Set(record.recordFakeId, "");
        records.InsertLast(record);

        auto ix = uint(myMapsUids[record.mapUid]);
        if (!myMaps[ix].recordAccountIds.Exists(record.accountId)) {
            myMaps[ix].recordAccountIds.Set(record.accountId, "");
            myMaps[ix].records.InsertLast(record);
        }
    }

    void ClearAccounts() {
        accounts.RemoveRange(0, accounts.Length);
        ClearAccountIds();
    }

    void ClearAccountIds() {
        accountIds.DeleteAll();
    }

    void ClearCurrentMaps() {
        currentMaps.RemoveRange(0, currentMaps.Length);
        ClearCurrentMapsUids();
    }

    void ClearCurrentMapsUids() {
        currentMapsUids.DeleteAll();
    }

    void ClearMyMaps() {
        myMaps.RemoveRange(0, myMaps.Length);
        ClearMyMapsUids();
    }

    void ClearMyMapsUids() {
        myMapsUids.DeleteAll();
    }

    void ClearMyMapsHidden() {
        myMapsHidden.RemoveRange(0, myMapsHidden.Length);
        ClearMyMapsHiddenUids();
    }

    void ClearMyMapsHiddenUids() {
        myMapsHiddenUids.DeleteAll();
    }

    void ClearRecords() {
        records.RemoveRange(0, records.Length);
        ClearRecordIds();
    }

    void ClearRecordIds() {
        recordIds.DeleteAll();
    }
}