/*
c 2023-05-16
m 2023-07-12
*/

namespace Globals {
    Models::Account[] accounts;
    dictionary        accountsIndex;
    bool              cancelAllRecords = false;
    Models::Map@[]    currentMaps;
    dictionary        currentMapsIndex;
    bool              debug = false;
    UI::Texture@      defaultTexture = UI::LoadTexture("Assets/1x1.png");
    bool              getAccountNames = true;
    uint64            latestNadeoRequest = 0;
    uint64            logTimerIndex = 0;
    dictionary        logTimers;
    string            clickedMapId;
    string            hiddenMapsFile = storageFolder + "hiddenMaps.json";
    dictionary        hiddenMapsIndex;
    Models::Map[]     maps;
    string            mapSearch;
    dictionary        mapsIndex;
    Models::Record[]  records;
    // string            recordsAccountSearch;
    dictionary        recordsIndex;
    // string            recordsMapSearch;
    Models::Record[]  recordsSorted;
    uint              recordsTimestamp = 0;
    bool              requesting = false;
    bool              showHidden = false;
    uint              shownMaps;
    bool              singleMapRecordStatus = true;
    dictionary        status;
    string            storageFolder = IO::FromStorageFolder("").Replace("\\", "/");
    string            thumbnailFolder = storageFolder + "thumbnails";
    dictionary        thumbnailTextures;
    SQLite::Database@ timeDB = SQLite::Database(":memory:");
    string            title = "\\$2F3" + Icons::MapO + "\\$G TMTracker";
    Json::Value       zones;
    string            zonesFile = "Assets/zones.json";
    bool              zonesFileMissing = true;

    void AddAccount(Models::Account account) {
        if (accountsIndex.Exists(account.accountId)) return;
        accounts.InsertLast(account);
        accountsIndex.Set(account.accountId, @accounts[accounts.Length - 1]);
    }

    void ClearAccounts() {
        accounts.RemoveRange(0, accounts.Length);
        accountsIndex.DeleteAll();
    }

    void AddMap(Models::Map map) {
        if (mapsIndex.Exists(map.mapId)) return;
        if (hiddenMapsIndex.Exists(map.mapId)) map.hidden = true;
        maps.InsertLast(map);
        mapsIndex.Set(map.mapId, @maps[maps.Length - 1]);
    }

    void AddCurrentMap(Models::Map@ map) {
        if (currentMapsIndex.Exists(map.mapId)) return;
        currentMaps.InsertLast(map);
        currentMapsIndex.Set(map.mapId, map);
    }

    void ClearCurrentMaps() {
        currentMaps.RemoveRange(0, currentMaps.Length);
        currentMapsIndex.DeleteAll();
    }

    void HideMap(Models::Map@ map) {
        if (hiddenMapsIndex.Exists(map.mapId)) return;
        hiddenMapsIndex.Set(map.mapId, "");
        map.hidden = true;
        Globals::shownMaps--;
        Util::JsonSaveFromDict(hiddenMapsIndex, hiddenMapsFile);
    }

    void ShowMap(Models::Map@ map) {
        if (!hiddenMapsIndex.Exists(map.mapId)) return;
        hiddenMapsIndex.Delete(map.mapId);
        map.hidden = false;
        Globals::shownMaps++;
        Util::JsonSaveFromDict(hiddenMapsIndex, hiddenMapsFile);
    }

    void ClearHiddenMaps() {
        hiddenMapsIndex.DeleteAll();
    }

    void ClearMaps() {
        maps.RemoveRange(0, maps.Length);
        mapsIndex.DeleteAll();
        // ClearAccounts();
        ClearCurrentMaps();
        // ClearHiddenMaps();
        // ClearRecords();
    }

    void AddRecord(Models::Record record) {
        records.InsertLast(record);
        auto storedRecord = @records[records.Length - 1];
        recordsIndex.Set(record.recordFakeId, storedRecord);
        auto map = cast<Models::Map@>(mapsIndex[record.mapId]);
        map.records.InsertLast(storedRecord);
        map.recordsIndex.Set(record.accountId, storedRecord);
    }

    void SortRecords() {
        auto timerId = Util::LogTimerBegin("sorting records");
        Globals::status.Set("sort-records", "sorting records...");

        recordsSorted = records;
        if (recordsSorted.Length > 1)
            recordsSorted.Sort(function(a,b) { return a.timestampUnix > b.timestampUnix; });  // times out, 3s for 2600 records

        Globals::status.Delete("sort-records");
        Util::LogTimerEnd(timerId);
    }

    void ClearMapRecords(Models::Map@ map) {
        map.records.RemoveRange(0, records.Length);
        map.recordsIndex.DeleteAll();

        if (records.Length == 0) return;
        for (int i = records.Length - 1; i >= 0; i--)
            if (records[i].mapId == map.mapId)
                records.RemoveAt(i);
    }

    void ClearRecords() {
        records.RemoveRange(0, records.Length);
        recordsIndex.DeleteAll();
    }
}