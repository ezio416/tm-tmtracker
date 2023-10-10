/*
c 2023-05-16
m 2023-10-09
*/

namespace Globals {
    Models::Account[] accounts;
    dictionary        accountsDict;
    string            apiCore                = "NadeoServices";
    string            apiLive                = "NadeoLiveServices";
    bool              cancelAllRecords       = false;
    string            clickedMapId;
    string            colorAuthor            = "\\$4B0";
    string            colorBronze            = "\\$C80";
    string            colorGold              = "\\$DD1";
    string            colorSilver            = "\\$AAA";
    Models::Map@[]    currentMaps;
    dictionary        currentMapsDict;
    string            dateFormat             = "\\$AAA%a \\$G%Y-%m-%d %H:%M:%S \\$AAA";
    bool              debugTab               = false;
    bool              getAccountNames        = true;
    Json::Value@      hiddenMapsJson         = Json::Object();
    uint64            latestNandoRequest     = 0;
    Models::Map[]     maps;
    dictionary        mapsDict;
    string            mapSearch;
    string            myAccountId            = GetApp().LocalPlayerInfo.WebServicesUserId;
    Models::Record[]  myRecords;
    Models::Map[]     myRecordsMaps;
    dictionary        myRecordsMapsDict;
    Models::Record[]  records;
    dictionary        recordsDict;
    Models::Record@[] recordsSorted;
    Json::Value@      recordsTimestampsJson  = Json::Object();
    float             scale                  = UI::GetScale();
    bool              showHidden             = false;
    uint              shownMaps              = 0;
    bool              singleMapRecordStatus  = true;
    dictionary        status;
    vec4              tableRowBgAltColor     = vec4(0, 0, 0, 0.5);
    string            title                  = "\\$2F3" + Icons::MapO + "\\$G TMTracker";

    void AddAccount(Models::Account account) {
        if (accountsDict.Exists(account.accountId))
            return;

        accounts.InsertLast(account);
        accountsDict.Set(account.accountId, @accounts[accounts.Length - 1]);
    }

    void ClearAccounts() {
        Log::Write(Log::Level::Debug, "clearing accounts...");

        accounts.RemoveRange(0, accounts.Length);
        accountsDict.DeleteAll();
    }

    void AddMap(Models::Map map) {
        if (mapsDict.Exists(map.mapId))
            return;

        if (hiddenMapsJson.HasKey(map.mapId))
            map.hidden = true;
        else
            shownMaps++;

        maps.InsertLast(map);
        mapsDict.Set(map.mapId, @maps[maps.Length - 1]);
    }

    void AddCurrentMap(Models::Map@ map) {
        if (currentMapsDict.Exists(map.mapId))
            return;

        Log::Write(Log::Level::Debug, map.logName + "adding to current...");

        currentMaps.InsertLast(map);
        currentMapsDict.Set(map.mapId, map);
        clickedMapId = map.mapId;
    }

    void ClearCurrentMaps() {
        Log::Write(Log::Level::Debug, "clearing current maps...");

        currentMaps.RemoveRange(0, currentMaps.Length);
        currentMapsDict.DeleteAll();
    }

    void HideMap(Models::Map@ map) {
        if (hiddenMapsJson.HasKey(map.mapId))
            return;

        Log::Write(Log::Level::Debug, map.logName + "hiding...");

        hiddenMapsJson[map.mapId] = 0;
        map.hidden = true;
        Globals::shownMaps--;
        Files::SaveHiddenMaps();
    }

    void ShowMap(Models::Map@ map) {
        if (!hiddenMapsJson.HasKey(map.mapId))
            return;

        Log::Write(Log::Level::Debug, map.logName + "showing...");

        hiddenMapsJson.Remove(map.mapId);
        map.hidden = false;
        Globals::shownMaps++;
        Files::SaveHiddenMaps();
    }

    void ClearMaps() {
        Log::Write(Log::Level::Debug, "clearing maps...");

        maps.RemoveRange(0, maps.Length);
        mapsDict.DeleteAll();
        ClearCurrentMaps();
        shownMaps = 0;
    }

    void AddRecord(Models::Record record) {
        if (record.timestampIso == "")
            record.timestampIso = Time::FormatString("%Y-%m-%dT%H:%M:%S+00:00", record.timestampUnix);
        records.InsertLast(record);
        Models::Record@ storedRecord = @records[records.Length - 1];
        recordsDict.Set(record.recordFakeId, storedRecord);

        Models::Map@ map = cast<Models::Map@>(mapsDict[record.mapId]);
        storedRecord.SetMedals(map);
        storedRecord.mapName = map.mapNameText;
        map.records.InsertLast(storedRecord);
        map.recordsDict.Set(record.accountId, storedRecord);
    }

    void SortRecordsCoro() {
        while (Locks::sortRecords)
            yield();
        Locks::sortRecords = true;
        string timerId = Log::TimerBegin("sorting records");
        string statusId = "sort-records";

        recordsSorted.RemoveRange(0, recordsSorted.Length);

        for (uint i = 0; i < records.Length; i++) {
            Globals::status.Set(statusId, "sorting records... (" + i + "/" + records.Length + ")");
            Models::Record@ record = @records[i];

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

            if (i % 5 == 0)
                yield();
        }

        Globals::status.Delete(statusId);
        Log::TimerEnd(timerId);
        Locks::sortRecords = false;

        startnew(CoroutineFunc(Database::SaveCoro));
    }

    void ClearMapRecords(Models::Map@ map) {
        Log::Write(Log::Level::Debug, map.logName + "clearing records...");

        map.records.RemoveRange(0, map.records.Length);
        map.recordsDict.DeleteAll();

        if (records.Length == 0) return;
        for (int i = records.Length - 1; i >= 0; i--)
            if (records[i].mapId == map.mapId)
                records.RemoveAt(i);
    }

    void ClearRecords() {
        Log::Write(Log::Level::Debug, "clearing records...");

        records.RemoveRange(0, records.Length);
        recordsDict.DeleteAll();
    }
}