/*
c 2023-05-16
m 2023-05-29
*/

// Global variables for plugin operation, as well as functions to add/clear
namespace Globals {
    Models::Account[] accounts;
    dictionary        accountIds;
    Models::Map@[]    currentMaps;
    dictionary        currentMapIds;
    SQLite::Database@ db;
    UI::Texture@      defaultTexture = UI::LoadTexture("Assets/1x1.png");
    bool              dev = false;
    bool              getAccountNames = true;
    uint64            latestNadeoRequest = 0;
    uint64            logTimerIndex = 0;
    dictionary        logTimers;
    bool              mapClicked = false;
    Models::Map[]     myHiddenMaps;
    dictionary        myHiddenMapIds;
    Models::Map[]     myMaps;
    dictionary        myMapIds;
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
        if (myMapIds.Exists(map.mapId)) return;
        myMapIds.Set(map.mapId, myMapIds.GetKeys().Length);
        map.hidden = false;
        myMaps.InsertLast(map);
    }

    void AddMyHiddenMap(Models::Map map) {
        if (myHiddenMapIds.Exists(map.mapId)) return;
        myHiddenMapIds.Set(map.mapId, "");
        map.hidden = true;
        myHiddenMaps.InsertLast(map);
    }

    void AddRecord(Models::Record record) {
        if (recordIds.Exists(record.recordFakeId)) return;

        auto ix = uint(myMapIds[record.mapId]);
        auto @map = myMaps[ix];

        record.SetMedals(map);

        recordIds.Set(record.recordFakeId, records.Length);
        records.InsertLast(record);

        if (!map.recordAccountIds.Exists(record.accountId)) {
            map.recordAccountIds.Set(record.accountId, records.Length);
            map.records.InsertLast(record);
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
        ClearCurrentMapIds();
    }

    void ClearCurrentMapIds() {
        currentMapIds.DeleteAll();
    }

    void ClearMyMaps() {
        myMaps.RemoveRange(0, myMaps.Length);
        ClearMyMapIds();
    }

    void ClearMyMapIds() {
        myMapIds.DeleteAll();
    }

    void ClearMyHiddenMaps() {
        myHiddenMaps.RemoveRange(0, myHiddenMaps.Length);
        ClearMyHiddenMapIds();
    }

    void ClearMyHiddenMapIds() {
        myHiddenMapIds.DeleteAll();
    }

    void ClearRecords() {
        records.RemoveRange(0, records.Length);
        ClearRecordIds();
    }

    void ClearRecordIds() {
        recordIds.DeleteAll();
    }
}