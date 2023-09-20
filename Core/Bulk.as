/*
c 2023-07-06
m 2023-09-20
*/

namespace Bulk {
    void GetAccountNamesCoro() {
        if (!Globals::getAccountNames) return;

        string timerId = Log::TimerBegin("getting account names");
        Globals::status.Set("account-names", "getting account names...");

        string[] missing;

        for (uint i = 0; i < Globals::accounts.Length; i++) {
            auto account = @Globals::accounts[i];
            if (account.IsNameExpired()) {
                account.accountName = "";
                missing.InsertLast(account.accountId);
            }
        }

        dictionary ret = NadeoServices::GetDisplayNamesAsync(missing);
        for (uint i = 0; i < missing.Length; i++) {
            string id = missing[i];
            auto account = cast<Models::Account@>(Globals::accountsIndex[id]);
            account.accountName = string(ret[id]);
            account.SetNameExpire();
        }

        startnew(CoroutineFunc(Globals::SortRecordsCoro));

        Globals::status.Delete("account-names");
        Log::TimerEnd(timerId);
    }

    void GetMyMapsCoro() {
        while (Locks::myMaps) yield();
        Locks::myMaps = true;
        string timerId = Log::TimerBegin("updating my maps");
        Globals::status.Set("get-my-maps", "getting maps...");

        Globals::ClearMaps();

        while (!NadeoServices::IsAuthenticated("NadeoLiveServices")) yield();

        uint offset = 0;
        bool tooManyMaps;

        do {
            auto waitCoro = startnew(CoroutineFunc(Util::WaitToDoNadeoRequestCoro));
            while (waitCoro.IsRunning()) yield();

            auto req = NadeoServices::Get(
                "NadeoLiveServices",
                NadeoServices::BaseURLLive() + "/api/token/map?length=1000&offset=" + offset
            );
            req.Start();
            while (!req.Finished()) yield();
            Locks::requesting = false;
            offset += 1000;

            auto mapList = Json::Parse(req.String())["mapList"];
            tooManyMaps = mapList.Length == 1000;
            for (uint i = 0; i < mapList.Length; i++) {
                if (Settings::maxMaps >= 0 && Globals::maps.Length >= uint(Settings::maxMaps))
                    break;
                auto map = Models::Map(mapList[i]);
                try { map.recordsTimestamp = uint(Globals::recordsTimestampsIndex.Get(map.mapId)); } catch { }
                Globals::AddMap(map);
            }
        } while (tooManyMaps);

        Globals::status.Delete("get-my-maps");
        Log::TimerEnd(timerId);
        Locks::myMaps = false;

        if (Settings::autoThumbnails)
            startnew(CoroutineFunc(LoadMyMapsThumbnailsCoro));

        startnew(CoroutineFunc(Database::LoadRecordsCoro));
    }

    void GetMyMapsRecordsCoro() {
        if (Locks::allRecords) return;
        Locks::allRecords = true;
        string timerId = Log::TimerBegin("getting records");

        Globals::getAccountNames = false;
        Globals::singleMapRecordStatus = false;
        for (uint i = 0; i < Globals::maps.Length; i++) {
            Globals::status.Set("get-all-records", "getting records... (" + (i + 1) + "/" + Globals::maps.Length + ")");
            auto recordsCoro = startnew(CoroutineFunc(@Globals::maps[i].GetRecordsCoro));
            while (recordsCoro.IsRunning()) yield();
            if (Globals::cancelAllRecords) {
                Globals::cancelAllRecords = false;
                trace("getting records cancelled by user");
                break;
            }
        }
        Globals::getAccountNames = true;
        Globals::singleMapRecordStatus = true;

        auto nameCoro = startnew(CoroutineFunc(GetAccountNamesCoro));
        while (nameCoro.IsRunning()) yield();

        Globals::recordsTimestampsIndex["all"] = Time::Stamp;
        Json::ToFile(Files::mapRecordsTimestamps, Globals::recordsTimestampsIndex);

        Globals::status.Delete("get-all-records");
        Log::TimerEnd(timerId);
        Locks::allRecords = false;
    }

    void LoadMyMapsThumbnailsCoro() {
        if (Locks::thumbs) return;

        string timerId = Log::TimerBegin("loading my map thumbnails");
        Locks::thumbs = true;

        for (uint i = 0; i < Globals::maps.Length; i++) {
            if (Globals::cancelThumbnails) {
                Globals::cancelThumbnails = false;
                break;
            }

            Globals::status.Set("load-thumbs", "loading thumbnails... (" + (i + 1) + "/" + Globals::maps.Length + ")");
            auto map = @Globals::maps[i];
            auto coro = startnew(CoroutineFunc(map.LoadThumbnailCoro));
            while (coro.IsRunning()) yield();
        }

        Locks::thumbs = false;
        Globals::status.Delete("load-thumbs");
        Log::TimerEnd(timerId);
    }
}