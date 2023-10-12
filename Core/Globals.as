/*
c 2023-05-16
m 2023-10-12
*/

namespace Globals {
    Models::Account[] accounts;
    dictionary        accountsDict;
    string            apiCore                 = "NadeoServices";
    string            apiLive                 = "NadeoLiveServices";
    bool              cancelAllRecords        = false;
    string            colorAuthor             = "\\$4B0";
    string            colorBronze             = "\\$C80";
    string            colorGold               = "\\$DD1";
    string            colorSilver             = "\\$AAA";
    string            dateFormat              = "\\$AAA%a \\$G%Y-%m-%d %H:%M:%S \\$AAA";
    bool              debugTab                = false;
    bool              getAccountNames         = true;
    Json::Value@      hiddenMapsJson          = Json::Object();
    uint64            latestNandoRequest      = 0;
    string            myAccountId;
    Models::Map[]     myMaps;
    dictionary        myMapsDict;
    Models::Record[]  myMapsRecords;
    dictionary        myMapsRecordsDict;
    Models::Record@[] myMapsRecordsSorted;
    string            myMapsSearch;
    Models::Map@[]    myMapsViewing;
    dictionary        myMapsViewingDict;
    string            myMapsViewingMapId;
    bool              myMapsViewingSet        = false;
    Models::Record[]  myRecords;
    dictionary        myRecordsDict;
    Models::Map[]     myRecordsMaps;
    dictionary        myRecordsMapsDict;
    string            myRecordsMapsSearch;
    Models::Map@[]    myRecordsMapsViewing;
    dictionary        myRecordsMapsViewingDict;
    string            myRecordsMapsViewingMapId;
    bool              myRecordsMapsViewingSet = false;
    Models::Record@[] myRecordsSorted;
    Json::Value@      recordsTimestampsJson   = Json::Object();
    float             scale                   = UI::GetScale();
    bool              showHidden              = false;
    uint              shownMaps               = 0;
    bool              singleMapRecordStatus   = true;
    dictionary        status;
    vec4              tableRowBgAltColor      = vec4(0, 0, 0, 0.5);
    string            title                   = "\\$2F3" + Icons::MapO + "\\$G TMTracker";

    void AddAccount(Models::Account account) {
        if (accountsDict.Exists(account.accountId))
            return;

        accounts.InsertLast(account);
        accountsDict.Set(account.accountId, @accounts[accounts.Length - 1]);
    }

    void AddMyMap(Models::Map map) {
        if (myMapsDict.Exists(map.mapId))
            return;

        if (hiddenMapsJson.HasKey(map.mapId))
            map.hidden = true;
        else
            shownMaps++;

        myMaps.InsertLast(map);
        myMapsDict.Set(map.mapId, @myMaps[myMaps.Length - 1]);
    }

    void AddMyMapsRecord(Models::Record record) {
        if (record.timestampIso == "")
            record.timestampIso = Time::FormatString("%Y-%m-%dT%H:%M:%S+00:00", record.timestampUnix);
        myMapsRecords.InsertLast(record);
        Models::Record@ storedRecord = @myMapsRecords[myMapsRecords.Length - 1];
        myMapsRecordsDict.Set(record.recordFakeId, storedRecord);

        Models::Map@ map = cast<Models::Map@>(myMapsDict[record.mapId]);
        storedRecord.SetMedals(map);
        storedRecord.mapNameColor = map.mapNameColor;
        storedRecord.mapNameText = map.mapNameText;
        map.records.InsertLast(storedRecord);
        map.recordsDict.Set(record.accountId, storedRecord);
    }

    void AddMyMapViewing(Models::Map@ map) {
        if (!myMapsViewingDict.Exists(map.mapId)) {
            Log::Write(Log::Level::Debug, map.logName + "adding to my maps viewing...");

            myMapsViewing.InsertLast(map);
            myMapsViewingDict.Set(map.mapId, map);
        }

        if (Settings::viewingSwitchOnClicked) {
            myMapsViewingMapId = map.mapId;
            myMapsViewingSet = true;
        }
    }

    void AddMyRecordsMapViewing(Models::Map@ map) {
        if (!myRecordsMapsViewingDict.Exists(map.mapId)) {
            Log::Write(Log::Level::Debug, map.logName + "adding to my records maps viewing...");

            myRecordsMapsViewing.InsertLast(map);
            myRecordsMapsViewingDict.Set(map.mapId, map);
        }

        if (Settings::viewingSwitchOnClicked) {
            myRecordsMapsViewingMapId = map.mapId;
            myRecordsMapsViewingSet = true;
        }
    }

    void ClearAccounts() {
        Log::Write(Log::Level::Debug, "clearing accounts...");

        accounts.RemoveRange(0, accounts.Length);
        accountsDict.DeleteAll();
    }

    void ClearMyMaps() {
        Log::Write(Log::Level::Debug, "clearing my maps...");

        myMaps.RemoveRange(0, myMaps.Length);
        myMapsDict.DeleteAll();
        ClearMyMapsViewing();
        shownMaps = 0;
    }

    void ClearMyMapRecords(Models::Map@ map) {
        Log::Write(Log::Level::Debug, map.logName + "clearing my maps records...");

        map.records.RemoveRange(0, map.records.Length);
        map.recordsDict.DeleteAll();

        if (myMapsRecords.Length == 0) return;
        for (int i = myMapsRecords.Length - 1; i >= 0; i--)
            if (myMapsRecords[i].mapId == map.mapId)
                myMapsRecords.RemoveAt(i);
    }

    void ClearMyMapsRecords() {
        Log::Write(Log::Level::Debug, "clearing my maps records...");

        myMapsRecords.RemoveRange(0, myMapsRecords.Length);
        myMapsRecordsDict.DeleteAll();
    }

    void ClearMyMapsViewing() {
        Log::Write(Log::Level::Debug, "clearing my maps viewing...");

        myMapsViewing.RemoveRange(0, myMapsViewing.Length);
        myMapsViewingDict.DeleteAll();
    }

    void ClearMyRecordsMapsViewing() {
        Log::Write(Log::Level::Debug, "clearing my records maps viewing...");

        myRecordsMapsViewing.RemoveRange(0, myRecordsMapsViewing.Length);
        myRecordsMapsViewingDict.DeleteAll();
    }

    void HideMyMap(Models::Map@ map) {
        if (hiddenMapsJson.HasKey(map.mapId))
            return;

        Log::Write(Log::Level::Debug, map.logName + "hiding...");

        hiddenMapsJson[map.mapId] = 0;
        map.hidden = true;
        Globals::shownMaps--;
        Files::SaveHiddenMaps();
    }

    void ShowMyMap(Models::Map@ map) {
        if (!hiddenMapsJson.HasKey(map.mapId))
            return;

        Log::Write(Log::Level::Debug, map.logName + "showing...");

        hiddenMapsJson.Remove(map.mapId);
        map.hidden = false;
        Globals::shownMaps++;
        Files::SaveHiddenMaps();
    }

    void SortMyMapsRecordsCoro() {
        while (Locks::sortMyMapsRecords)
            yield();
        Locks::sortMyMapsRecords = true;
        string timerId = Log::TimerBegin("sorting my maps records");
        string statusId = "sort-records";

        myMapsRecordsSorted.RemoveRange(0, myMapsRecordsSorted.Length);

        for (uint i = 0; i < myMapsRecords.Length; i++) {
            Globals::status.Set(statusId, "sorting my maps records... (" + i + "/" + myMapsRecords.Length + ")");
            Models::Record@ record = @myMapsRecords[i];

            for (uint j = 0; j < myMapsRecordsSorted.Length; j++) {
                if (record.timestampUnix > myMapsRecordsSorted[j].timestampUnix) {
                    myMapsRecordsSorted.InsertAt(j, record);
                    break;
                }

                if (j == myMapsRecordsSorted.Length - 1) {
                    myMapsRecordsSorted.InsertLast(record);
                    break;
                }
            }

            if (myMapsRecordsSorted.Length == 0)
                myMapsRecordsSorted.InsertLast(record);

            if (i % 5 == 0)
                yield();
        }

        Globals::status.Delete(statusId);
        Log::TimerEnd(timerId);
        Locks::sortMyMapsRecords = false;

        startnew(CoroutineFunc(Database::SaveCoro));
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