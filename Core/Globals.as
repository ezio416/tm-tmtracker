/*
c 2023-05-16
m 2023-08-13
*/

namespace Globals {
    int3              version = int3(3, 0, 0);

    Models::Account[] accounts;
    dictionary        accountsIndex;
    bool              cancelAllRecords = false;
    Models::Map@[]    currentMaps;
    dictionary        currentMapsIndex;
    bool              debug = false;
    UI::Texture@      defaultTexture = UI::LoadTexture("Assets/1x1.png");
    UI::Texture@      eyeTexture = UI::LoadTexture("Assets/eye.png");
    bool              getAccountNames = true;
    uint64            latestNadeoRequest = 0;
    uint64            logTimerIndex = 0;
    dictionary        logTimers;
    string            clickedMapId;
    string            hiddenMapsFile = storageFolder + "hiddenMaps.json";
    Json::Value       hiddenMapsIndex = Json::Object();
    Models::Map[]     maps;
    string            mapRecordsTimestampsFile = storageFolder + "mapRecordsTimestamps.json";
    string            mapSearch;
    dictionary        mapsIndex;
    Models::Record[]  records;
    dictionary        recordsIndex;
    Models::Record@[] recordsSorted;
    Json::Value       recordsTimestampsIndex = Json::Object();
    bool              saveSettings = false;
    float             scale = UI::GetScale();
    bool              showHidden = false;
    uint              shownMaps = 0;
    bool              singleMapRecordStatus = true;
    dictionary        status;
    string            storageFolder = IO::FromStorageFolder("").Replace("\\", "/");
    vec4              tableRowBgAltColor = vec4(0, 0, 0, 0.5);
    string            thumbnailFolder = storageFolder + "thumbnails";
    dictionary        thumbnailTextures;
    SQLite::Database@ timeDB = SQLite::Database(":memory:");
    string            title = "\\$2F3" + Icons::MapO + "\\$G TMTracker";
    string            versionFile = storageFolder + "version.json";
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
        if (hiddenMapsIndex.HasKey(map.mapId))
            map.hidden = true;
        else
            shownMaps++;
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
        if (hiddenMapsIndex.HasKey(map.mapId)) return;
        hiddenMapsIndex[map.mapId] = 0;
        map.hidden = true;
        Globals::shownMaps--;
        Json::ToFile(Globals::hiddenMapsFile, Globals::hiddenMapsIndex);
    }

    void ShowMap(Models::Map@ map) {
        if (!hiddenMapsIndex.HasKey(map.mapId)) return;
        hiddenMapsIndex.Remove(map.mapId);
        map.hidden = false;
        Globals::shownMaps++;
        Json::ToFile(Globals::hiddenMapsFile, Globals::hiddenMapsIndex);
    }

    void ClearMaps() {
        maps.RemoveRange(0, maps.Length);
        mapsIndex.DeleteAll();
        ClearCurrentMaps();
        shownMaps = 0;
    }

    void AddRecord(Models::Record record) {
        if (record.timestampIso == "")
            record.timestampIso = Time::FormatString("%Y-%m-%dT%H:%M:%S+00:00", record.timestampUnix);
        records.InsertLast(record);
        auto storedRecord = @records[records.Length - 1];
        recordsIndex.Set(record.recordFakeId, storedRecord);

        auto map = cast<Models::Map@>(mapsIndex[record.mapId]);
        storedRecord.SetMedals(map);
        storedRecord.mapName = map.mapNameText;
        map.records.InsertLast(storedRecord);
        map.recordsIndex.Set(record.accountId, storedRecord);
    }

    void SortRecordsCoro() {
        while (Locks::sortRecords) yield();
        Locks::sortRecords = true;

        string timerId = Util::LogTimerBegin("sorting records");

        recordsSorted.RemoveRange(0, recordsSorted.Length);

        for (uint i = 0; i < records.Length; i++) {
            Globals::status.Set("sort-records", "sorting records... (" + i + "/" + records.Length + ")");
            auto record = @records[i];
            for (uint j = 0; j < recordsSorted.Length; j++) {
                if (record.timestampUnix > recordsSorted[j].timestampUnix) {
                    recordsSorted.InsertAt(j, record);
                    break;
                }
                if (j == recordsSorted.Length - 1) {
                    recordsSorted.InsertLast(record);
                    break;
                }
            }
            if (recordsSorted.Length == 0)
                recordsSorted.InsertLast(record);
            if (i % 5 == 0) yield();
        }

        startnew(CoroutineFunc(Database::SaveCoro));

        Globals::status.Delete("sort-records");
        Util::LogTimerEnd(timerId);
        Locks::sortRecords = false;
    }

    void ClearMapRecords(Models::Map@ map) {
        map.records.RemoveRange(0, map.records.Length);
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