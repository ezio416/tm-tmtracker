// c 2023-07-06
// m 2023-12-27

namespace Bulk {
    string[] myRecordsMapIds;

    void GetAccountNamesCoro() {
        if (!Globals::getAccountNames)
            return;

        while (Locks::accountNames)
            yield();
        Locks::accountNames = true;
        string timerId = Log::TimerBegin("getting account names");
        string statusId = "account-names";
        Globals::status.Set(statusId, "getting account names...");

        string[] missing;

        for (uint i = 0; i < Globals::accounts.Length; i++) {
            Models::Account@ account = @Globals::accounts[i];

            if (account.accountId == "d2372a08-a8a1-46cb-97fb-23a161d85ad0") {
                account.accountName = "Nadeo";
                continue;
            }

            if (account.IsNameExpired()) {
                account.accountName = "";
                missing.InsertLast(account.accountId);
            }
        }

        Log::Write(Log::Level::Debug, "missing account names to get: " + missing.Length);

        dictionary names = NadeoServices::GetDisplayNamesAsync(missing);
        for (uint i = 0; i < missing.Length; i++) {
            string accountId = missing[i];
            Models::Account@ account = cast<Models::Account@>(Globals::accountsDict[accountId]);
            account.accountName = string(names[accountId]);
            account.SetNameExpire();
        }

        Globals::status.Delete(statusId);
        Log::TimerEnd(timerId);
        Locks::accountNames = false;
    }

    void GetMyMapsCoro() {
        while (Locks::myMaps)
            yield();
        Locks::myMaps = true;
        string timerId = Log::TimerBegin("getting my maps");
        string statusId = "get-my-maps";
        Globals::status.Set(statusId, "getting my maps...");

        Globals::ClearMyMaps();

        while (!NadeoServices::IsAuthenticated(Globals::apiLive))
            yield();

        uint offset = 0;
        bool tooManyMaps;

        do {
            Meta::PluginCoroutine@ waitCoro = startnew(Util::NandoRequestWaitCoro);
            while (waitCoro.IsRunning())
                yield();

            Net::HttpRequest@ req = NadeoServices::Get(
                Globals::apiLive,
                NadeoServices::BaseURLLive() + "/api/token/map?length=1000&offset=" + offset
            );
            req.Start();
            while (!req.Finished())
                yield();
            Locks::requesting = false;
            offset += 1000;

            Json::Value@ mapList;
            try {
                @mapList = Json::Parse(req.String())["mapList"];
            } catch {
                Log::Write(Log::Level::Errors, "error parsing mapList: " + getExceptionInfo());
                break;
            }

            tooManyMaps = mapList.Length == 1000;

            for (uint i = 0; i < mapList.Length; i++) {
                Models::Map map = Models::Map(mapList[i]);

                try {
                    map.recordsTimestamp = uint(Globals::recordsTimestampsJson.Get(map.mapId));
                } catch { }  // error should mean no records have been gotten yet

                if (Settings::maxMaps == 0 || Globals::myMaps.Length < Settings::maxMaps)
                    Globals::AddMyMap(map);
                else
                    break;
            }

            if (tooManyMaps)
                Log::Write(Log::Level::Debug, "tooManyMaps, getting more...");
        } while (tooManyMaps);

        uint runningNumber = 1;
        for (int i = Globals::myMaps.Length - 1; i >= 0; i--) {
            Globals::myMaps[i].number = runningNumber;
            runningNumber++;
        }

        Log::Write(Log::Level::Debug, "number of maps gotten: " + Globals::myMaps.Length);

        Globals::status.Delete(statusId);
        Log::TimerEnd(timerId);
        Locks::myMaps = false;

        Meta::PluginCoroutine@ loadCoro = startnew(Database::LoadRecordsCoro);
        while (loadCoro.IsRunning())
            yield();

        startnew(Sort::Maps::MyMapsCoro);
        startnew(Database::SaveCoro);
    }

    void GetMyMapsRecordsCoro() {
        if (Locks::allRecords)
            return;

        Locks::allRecords = true;
        string timerId = Log::TimerBegin("getting my maps' records");
        string statusId = "get-all-records";

        Globals::getAccountNames = false;
        Globals::singleMapRecordStatus = false;

        Sort::Records::allMaps = false;

        for (uint i = 0; i < Globals::myMaps.Length; i++) {
            Globals::status.Set(statusId, "getting my maps records... (" + (i + 1) + "/" + Globals::myMaps.Length + ")");

            Models::Map@ map = @Globals::myMaps[i];

            Meta::PluginCoroutine@ recordsCoro = startnew(CoroutineFunc(map.GetRecordsCoro));
            while (recordsCoro.IsRunning())
                yield();

            if (Globals::cancelAllRecords) {
                Globals::cancelAllRecords = false;
                Log::Write(Log::Level::Normal, "getting my maps' records cancelled by user");
                break;
            }
        }

        Sort::Records::allMaps = true;

        Globals::getAccountNames = true;
        Globals::singleMapRecordStatus = true;

        Meta::PluginCoroutine@ nameCoro = startnew(GetAccountNamesCoro);
        while (nameCoro.IsRunning())
            yield();

        Sort::Records::dbSave = true;
        startnew(Sort::Records::MyMapsRecordsCoro);

        Globals::recordsTimestampsJson["myMaps"] = Time::Stamp;
        Files::SaveRecordsTimestamps();

        Globals::status.Delete(statusId);
        Log::TimerEnd(timerId);
        Locks::allRecords = false;

        if (Settings::myMapsRecordsNotify)
            Util::NotifyGood("Done getting records!");
    }

    void GetMyRecordsCoro() {
        if (Locks::myRecords)
            return;

        Locks::myRecords = true;
        string timerId = Log::TimerBegin("getting my records");
        string statusId = "my-records";
        Globals::status.Set(statusId, "getting my records...");

        Globals::myRecords.RemoveRange(0, Globals::myRecords.Length);
        Globals::myRecordsSorted.RemoveRange(0, Globals::myRecordsSorted.Length);
        Globals::myRecordsMapsDict.DeleteAll();
        myRecordsMapIds.RemoveRange(0, myRecordsMapIds.Length);

        while (!NadeoServices::IsAuthenticated(Globals::apiCore))
            yield();

        Meta::PluginCoroutine@ waitCoro = startnew(Util::NandoRequestWaitCoro);
        while (waitCoro.IsRunning())
            yield();

        Net::HttpRequest@ req = NadeoServices::Get(
            Globals::apiCore,
            NadeoServices::BaseURLCore() + "/accounts/" + Globals::myAccountId + "/mapRecords"
        );
        req.Start();
        while (!req.Finished())
            yield();
        Locks::requesting = false;

        Json::Value@ records;
        try {
            @records = Json::Parse(req.String());
        } catch {
            Log::Write(Log::Level::Errors, "error parsing my records: " + getExceptionInfo());
        }

        if (records !is null) {
            for (uint i = 0; i < records.Length; i++) {
                Models::Record record = Models::Record(records[i], true);
                Globals::myRecords.InsertLast(record);
                Globals::myRecordsDict.Set(record.mapId, @Globals::myRecords[Globals::myRecords.Length - 1]);
                myRecordsMapIds.InsertLast(record.mapId);
            }
        }

        Globals::recordsTimestampsJson["myRecords"] = Time::Stamp;
        Files::SaveRecordsTimestamps();

        Globals::status.Delete(statusId);
        Log::TimerEnd(timerId);
        Locks::myRecords = false;

        startnew(Sort::Records::MyRecordsCoro);
        startnew(GetMyRecordsMapInfoCoro);
    }

    void GetMyRecordsMapInfoCoro() {
        if (Locks::mapInfo)
            return;

        Locks::mapInfo = true;
        string timerId = Log::TimerBegin("getting my records' map info");
        string statusId = "my-record-map-info";
        uint count = myRecordsMapIds.Length;

        while (myRecordsMapIds.Length > 0) {
            Globals::status.Set(statusId, "getting my records' map info... (" + (count - myRecordsMapIds.Length) + "/" + count + ")");

            string[] group;
            int idsToAdd = Math::Min(myRecordsMapIds.Length, 206);
            for (int i = 0; i < idsToAdd; i++)
                group.InsertLast(myRecordsMapIds[i]);
            myRecordsMapIds.RemoveRange(0, idsToAdd);

            Meta::PluginCoroutine@ waitCoro = startnew(Util::NandoRequestWaitCoro);
            while (waitCoro.IsRunning())
                yield();

            Net::HttpRequest@ req = NadeoServices::Get(
                Globals::apiCore,
                NadeoServices::BaseURLCore() + "/maps/?mapIdList=" + string::Join(group, "%2C")
            );
            req.Start();
            while (!req.Finished())
                yield();
            Locks::requesting = false;

            Json::Value@ maps;
            try {
                @maps = Json::Parse(req.String());
            } catch {
                Log::Write(Log::Level::Errors, "error parsing map info: " + getExceptionInfo());
            }

            if (maps !is null) {
                for (uint i = 0; i < maps.Length; i++) {  //! json not object or array 2024-02-25
                    Models::Map map = Models::Map(maps[i], true);

                    Globals::AddAccount(Models::Account(map.authorId));

                    Globals::myRecordsMaps.InsertLast(map);
                    Globals::myRecordsMapsDict.Set(map.mapId, @Globals::myRecordsMaps[Globals::myRecordsMaps.Length - 1]);

                    Models::Record@ record = cast<Models::Record@>(Globals::myRecordsDict[map.mapId]);
                    record.mapAuthorTime = map.authorTime;
                    record.mapAuthorDelta = record.time - map.authorTime;
                    record.mapNameColor = map.mapNameColor;
                    record.mapNameText = map.mapNameText;
                    record.mapAuthorId = map.authorId;
                }
            }
        }

        Globals::status.Delete(statusId);
        Log::TimerEnd(timerId);
        Locks::mapInfo = false;

        startnew(GetAccountNamesCoro);
    }
}
