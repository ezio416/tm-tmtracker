// c 2023-05-16
// m 2023-12-26

namespace Globals {
    Models::Account[] accounts;
    dictionary        accountsDict;
    string            apiCore                 = "NadeoServices";
    string            apiLive                 = "NadeoLiveServices";
    bool              cancelAllRecords        = false;
    string            colorMedalAuthor;
    string            colorMedalBronze;
    string            colorMedalGold;
    string            colorMedalNone;
    string            colorMedalSilver;
    vec4              colorTableRowBgAlt      = vec4(0.0f, 0.0f, 0.0f, 0.5f);
    string            colorTop5;
    string            dateFormat              = "\\$AAA%a \\$G%Y-%m-%d %H:%M:%S \\$AAA";
    bool              getAccountNames         = true;
    Json::Value@      hiddenMapsJson          = Json::Object();
    string            myAccountId;
    Models::Map[]     myMaps;
    dictionary        myMapsDict;
    Models::Record[]  myMapsRecords;
    dictionary        myMapsRecordsDict;
    Models::Record@[] myMapsRecordsSorted;
    Models::Map@[]    myMapsViewing;
    dictionary        myMapsViewingDict;
    string            myMapsViewingMapId;
    bool              myMapsViewingSet        = false;
    Models::Record[]  myRecords;
    dictionary        myRecordsDict;
    Models::Map[]     myRecordsMaps;
    dictionary        myRecordsMapsDict;
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

        if (myMapsDict.Exists(record.mapId)) {
            myMapsRecords.InsertLast(record);
            Models::Record@ storedRecord = @myMapsRecords[myMapsRecords.Length - 1];
            myMapsRecordsDict.Set(record.recordFakeId, storedRecord);

            Models::Map@ map = cast<Models::Map@>(myMapsDict[record.mapId]);

            storedRecord.SetMedals(map);
            storedRecord.mapNameColor = map.mapNameColor;
            storedRecord.mapNameText = map.mapNameText;

            map.records.InsertLast(storedRecord);
            map.recordsSorted.InsertLast(storedRecord);
            map.recordsDict.Set(record.accountId, storedRecord);
        }
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

        // NOT WORKING???
        startnew(CoroutineFunc(map.SortRecordsCoro));
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
        map.recordsSorted.RemoveRange(0, map.recordsSorted.Length);
        map.recordsDict.DeleteAll();

        if (myMapsRecords.Length == 0)
            return;

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

        map.hidden = true;
        Globals::shownMaps--;

        hiddenMapsJson[map.mapId] = 0;
        Files::SaveHiddenMaps();
    }

    void SetColors() {
        Globals::colorMedalAuthor = "\\" + Text::FormatGameColor(Settings::colorMedalAuthor);
        Globals::colorMedalBronze = "\\" + Text::FormatGameColor(Settings::colorMedalBronze);
        Globals::colorMedalGold   = "\\" + Text::FormatGameColor(Settings::colorMedalGold);
        Globals::colorMedalNone   = "\\" + Text::FormatGameColor(Settings::colorMedalNone);
        Globals::colorMedalSilver = "\\" + Text::FormatGameColor(Settings::colorMedalSilver);
        Globals::colorTop5        = "\\" + Text::FormatGameColor(Settings::colorTop5);
    }

    void ShowMyMap(Models::Map@ map) {
        if (!hiddenMapsJson.HasKey(map.mapId))
            return;

        Log::Write(Log::Level::Debug, map.logName + "showing...");

        map.hidden = false;
        Globals::shownMaps++;

        hiddenMapsJson.Remove(map.mapId);
        Files::SaveHiddenMaps();
    }
}