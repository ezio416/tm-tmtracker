/*
c 2023-07-06
m 2023-10-09
*/

namespace Bulk {
    string[] myRecordsMapIds;

    void GetAccountNamesCoro() {
        if (!Globals::getAccountNames)
            return;

        string timerId = Log::TimerBegin("getting account names");
        string statusId = "account-names";
        Globals::status.Set(statusId, "getting account names...");

        string[] missing;

        for (uint i = 0; i < Globals::accounts.Length; i++) {
            Models::Account@ account = @Globals::accounts[i];
            if (account.IsNameExpired()) {
                account.accountName = "";
                missing.InsertLast(account.accountId);
            }
        }

        dictionary ret = NadeoServices::GetDisplayNamesAsync(missing);
        for (uint i = 0; i < missing.Length; i++) {
            string id = missing[i];
            Models::Account@ account = cast<Models::Account@>(Globals::accountsDict[id]);
            account.accountName = string(ret[id]);
            account.SetNameExpire();
        }

        startnew(CoroutineFunc(Globals::SortRecordsCoro));

        Globals::status.Delete(statusId);
        Log::TimerEnd(timerId);
    }

    void GetMyMapsCoro() {
        while (Locks::myMaps)
            yield();
        Locks::myMaps = true;
        string timerId = Log::TimerBegin("updating my maps");
        string statusId = "get-my-maps";
        Globals::status.Set(statusId, "getting maps...");

        Globals::ClearMaps();

        while (!NadeoServices::IsAuthenticated(Globals::apiLive))
            yield();

        uint offset = 0;
        bool tooManyMaps;

        do {
            Meta::PluginCoroutine@ waitCoro = startnew(CoroutineFunc(Util::NandoRequestWaitCoro));
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

            Json::Value@ mapList = Json::Parse(req.String())["mapList"];
            tooManyMaps = mapList.Length == 1000;

            for (uint i = 0; i < mapList.Length; i++) {
                Models::Map map = Models::Map(mapList[i]);
                try {
                    map.recordsTimestamp = uint(Globals::recordsTimestampsDict.Get(map.mapId));
                } catch { }  // error means no records gotten yet
                Globals::AddMap(map);
            }
        } while (tooManyMaps);

        Log::Write(Log::Level::Debug, "number of maps gotten: " + Globals::maps.Length);

        Globals::status.Delete(statusId);
        Log::TimerEnd(timerId);
        Locks::myMaps = false;

        startnew(CoroutineFunc(Database::LoadRecordsCoro));
    }

    void GetMyMapsRecordsCoro() {
        if (Locks::allRecords)
            return;

        Locks::allRecords = true;
        string timerId = Log::TimerBegin("getting records");
        string statusId = "get-all-records";

        Globals::getAccountNames = false;
        Globals::singleMapRecordStatus = false;

        for (uint i = 0; i < Globals::maps.Length; i++) {
            Globals::status.Set(statusId, "getting records... (" + (i + 1) + "/" + Globals::maps.Length + ")");

            Models::Map@ map = @Globals::maps[i];
            Meta::PluginCoroutine@ recordsCoro = startnew(CoroutineFunc(map.GetRecordsCoro));
            while (recordsCoro.IsRunning())
                yield();

            if (Globals::cancelAllRecords) {
                Globals::cancelAllRecords = false;
                Log::Write(Log::Level::Normal, "getting my map records cancelled by user");
                break;
            }
        }

        Globals::getAccountNames = true;
        Globals::singleMapRecordStatus = true;

        Meta::PluginCoroutine@ nameCoro = startnew(CoroutineFunc(GetAccountNamesCoro));
        while (nameCoro.IsRunning())
            yield();

        Globals::recordsTimestampsDict["all"] = Time::Stamp;
        Json::ToFile(Files::mapRecordsTimestamps, Globals::recordsTimestampsDict);

        Globals::status.Delete(statusId);
        Log::TimerEnd(timerId);
        Locks::allRecords = false;
    }

    void GetMyRecordsCoro() {
        if (Locks::myRecords)
            return;

        Locks::myRecords = true;
        string timerId = Log::TimerBegin("getting my records");
        string statusId = "my-records";
        Globals::status.Set(statusId, "getting my records...");

        Globals::myRecords.RemoveRange(0, Globals::myRecords.Length);
        Globals::myRecordsMapsDict.DeleteAll();
        myRecordsMapIds.RemoveRange(0, myRecordsMapIds.Length);

        while (!NadeoServices::IsAuthenticated(Globals::apiCore))
            yield();

        Meta::PluginCoroutine@ waitCoro = startnew(CoroutineFunc(Util::NandoRequestWaitCoro));
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

        Json::Value@ records = Json::Parse(req.String());
        for (uint i = 0; i < records.Length; i++) {
            Models::Record record = Models::Record(records[i], true);
            Globals::myRecords.InsertLast(record);
            myRecordsMapIds.InsertLast(record.mapId);
        }

        Globals::status.Delete(statusId);
        Log::TimerEnd(timerId);
        Locks::myRecords = false;

        startnew(CoroutineFunc(GetMyRecordsMapInfoCoro));
    }

    void GetMyRecordsMapInfoCoro() {
        if (Locks::mapInfo)
            return;

        Locks::mapInfo = true;
        string timerId = Log::TimerBegin("getting my records map info");
        string statusId = "my-record-map-info";
        uint count = myRecordsMapIds.Length;

        while (myRecordsMapIds.Length > 0) {
            Globals::status.Set(statusId, "getting my records map info... (" + (count - myRecordsMapIds.Length) + "/" + count + ")");
            string[] group;
            int idsToAdd = Math::Min(myRecordsMapIds.Length, 206);
            for (int i = 0; i < idsToAdd; i++)
                group.InsertLast(myRecordsMapIds[i]);
            myRecordsMapIds.RemoveRange(0, idsToAdd);

            Meta::PluginCoroutine@ waitCoro = startnew(CoroutineFunc(Util::NandoRequestWaitCoro));
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

            Json::Value@ maps = Json::Parse(req.String());

            for (uint i = 0; i < maps.Length; i++) {
                Models::Map map = Models::Map(maps[i], true);
                Globals::myRecordsMaps.InsertLast(map);
                Globals::myRecordsMapsDict.Set(map.mapId, @Globals::myRecordsMaps[Globals::myRecordsMaps.Length - 1]);
            }
        }

        Globals::status.Delete(statusId);
        Log::TimerEnd(timerId);
        Locks::mapInfo = false;
    }
}