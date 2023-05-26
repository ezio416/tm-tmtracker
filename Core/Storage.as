/*
c 2023-05-16
m 2023-05-26
*/

// Global variables for plugin operation, as well as functions to add/clear
namespace Storage {
    Models::Account[] accounts;
    dictionary        accountIds;
    Models::Map@[]    currentMaps;
    dictionary        currentMapUids;
    SQLite::Database@ db;
    UI::Texture@      defaultTexture = UI::LoadTexture("Assets/1x1.png");
    bool              dev = false;
    bool              getAccountNames = true;
    uint64            latestNadeoRequest = 0;
    uint64            logTimerIndex = 0;
    dictionary        logTimers;
    bool              mapClicked = false;
    Models::Map[]     myHiddenMaps;
    dictionary        myHiddenMapUids;
    Models::Map[]     myMaps;
    dictionary        myMapUids;
    dictionary        recordIds;
    Models::Record[]  records;
    int               requestsInProgress = 0;
    string            storageFolder = IO::FromStorageFolder("").Replace("\\", "/");
    string            dbFile = storageFolder + "TMTracker.db";
    string            thumbnailFolder = storageFolder + "thumbnails";
    dictionary        thumbnailTextures;
    string            title = "\\$2f3" + Icons::MapO + "\\$z TMTracker";
    Json::Value       zones;
    bool              zonesFileMissing = true;

    void AddAccount(Models::Account account) {
        if (accountIds.Exists(account.accountId)) return;
        accountIds.Set(account.accountId, accountIds.GetKeys().Length);
        accounts.InsertLast(account);
    }

    void AddMyMap(Models::Map map) {
        if (myMapUids.Exists(map.mapUid)) return;
        myMapUids.Set(map.mapUid, myMapUids.GetKeys().Length);
        map.hidden = false;
        myMaps.InsertLast(map);
    }

    void AddMyHiddenMap(Models::Map map) {
        if (myHiddenMapUids.Exists(map.mapUid)) return;
        myHiddenMapUids.Set(map.mapUid, "");
        map.hidden = true;
        myHiddenMaps.InsertLast(map);
    }

    void AddRecord(Models::Record record) {
        if (recordIds.Exists(record.recordFakeId)) return;
        recordIds.Set(record.recordFakeId, "");
        records.InsertLast(record);

        auto ix = uint(myMapUids[record.mapUid]);
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
        ClearCurrentMapUids();
    }

    void ClearCurrentMapUids() {
        currentMapUids.DeleteAll();
    }

    void ClearMyMaps() {
        myMaps.RemoveRange(0, myMaps.Length);
        ClearMyMapUids();
    }

    void ClearMyMapUids() {
        myMapUids.DeleteAll();
    }

    void ClearMyHiddenMaps() {
        myHiddenMaps.RemoveRange(0, myHiddenMaps.Length);
        ClearMyHiddenMapUids();
    }

    void ClearMyHiddenMapUids() {
        myHiddenMapUids.DeleteAll();
    }

    void ClearRecords() {
        records.RemoveRange(0, records.Length);
        ClearRecordIds();
    }

    void ClearRecordIds() {
        recordIds.DeleteAll();
    }
}