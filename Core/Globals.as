/*
c 2023-05-16
m 2023-10-11
*/

namespace Globals {
    Models::Account[] accounts;
    dictionary        accountsDict;
    string            apiCore                = "NadeoServices";
    string            apiLive                = "NadeoLiveServices";
    bool              cancelAllRecords       = false;
    string            colorAuthor            = "\\$4B0";
    string            colorBronze            = "\\$C80";
    string            colorGold              = "\\$DD1";
    string            colorSilver            = "\\$AAA";
    string            dateFormat             = "\\$AAA%a \\$G%Y-%m-%d %H:%M:%S \\$AAA";
    bool              debugTab               = false;
    bool              getAccountNames        = true;
    Json::Value@      hiddenMapsJson         = Json::Object();
    uint64            latestNandoRequest     = 0;
    Models::Map[]     maps;
    dictionary        mapsDict;
    string            mapSearch;
    string            myAccountId;
    Models::Record[]  myRecords;
    Models::Map[]     myRecordsMaps;
    dictionary        myRecordsMapsDict;
    Models::Record@[] myRecordsSorted;
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
    Models::Map@[]    viewingMaps;
    dictionary        viewingMapsDict;

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

    void AddViewingMap(Models::Map@ map) {
        if (viewingMapsDict.Exists(map.mapId))
            return;

        Log::Write(Log::Level::Debug, map.logName + "adding to viewing...");

        viewingMaps.InsertLast(map);
        viewingMapsDict.Set(map.mapId, map);
    }

    void ClearViewingMaps() {
        Log::Write(Log::Level::Debug, "clearing viewing maps...");

        viewingMaps.RemoveRange(0, viewingMaps.Length);
        viewingMapsDict.DeleteAll();
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
        ClearViewingMaps();
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

    void SortMyMapsRecordsCoro() {
        while (Locks::sortMyMapsRecords)
            yield();
        Locks::sortMyMapsRecords = true;
        string timerId = Log::TimerBegin("sorting my maps records");
        string statusId = "sort-records";

        recordsSorted.RemoveRange(0, recordsSorted.Length);

        for (uint i = 0; i < records.Length; i++) {
            Globals::status.Set(statusId, "sorting my maps records... (" + i + "/" + records.Length + ")");
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
        Locks::sortMyMapsRecords = false;

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

    void ClearMyMapsRecords() {
        Log::Write(Log::Level::Debug, "clearing records...");

        records.RemoveRange(0, records.Length);
        recordsDict.DeleteAll();
    }

    void SortMyRecordsCoro() {
        while (Locks::sortMyRecords)
            yield();
        Locks::sortMyRecords = true;
        string timerId = Log::TimerBegin("sorting my records");
        string statusId = "sort-my-records";

        myRecordsSorted.RemoveRange(0, myRecordsSorted.Length);

        for (uint i = 0; i < myRecords.Length; i++) {
            Globals::status.Set(statusId, "sorting my records... (" + i + "/" + myRecords.Length + ")");
            Models::Record@ record = @myRecords[i];

            for (uint j = 0; j < myRecordsSorted.Length; j++) {
                if (record.timestampUnix > myRecordsSorted[j].timestampUnix) {
                    myRecordsSorted.InsertAt(j, record);
                    break;
                }

                if (j == myRecordsSorted.Length - 1) {
                    myRecordsSorted.InsertLast(record);
                    break;
                }
            }

            if (myRecordsSorted.Length == 0)
                myRecordsSorted.InsertLast(record);

            if (i % 5 == 0)
                yield();
        }

        Globals::status.Delete(statusId);
        Log::TimerEnd(timerId);
        Locks::sortMyRecords = false;
    }
}