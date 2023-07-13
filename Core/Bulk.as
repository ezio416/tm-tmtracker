/*
c 2023-07-06
m 2023-07-12
*/

namespace Bulk {
    void GetAccountNamesCoro() {
        if (!Globals::getAccountNames) return;

        string timerId = Util::LogTimerBegin("getting account names");
        Globals::status.Set("account-names", "getting account names...");

        string[] missing;

        for (uint i = 0; i < Globals::accounts.Length; i++) {
            auto account = @Globals::accounts[i];
            if (account.IsNameExpired()) {
                account.accountName = "";
                missing.InsertLast(account.accountId);
            }
        }

        auto ret = NadeoServices::GetDisplayNamesAsync(missing);
        for (uint i = 0; i < missing.Length; i++) {
            string id = missing[i];
            auto account = cast<Models::Account@>(Globals::accountsIndex[id]);
            account.accountName = string(ret[id]);
            account.SetNameExpire();
        }

        startnew(CoroutineFunc(Globals::SortRecordsCoro));

        Globals::status.Delete("account-names");
        Util::LogTimerEnd(timerId);
    }

    void GetMyMapsCoro() {
        if (Locks::myMaps) return;
        Locks::myMaps = true;
        string timerId = Util::LogTimerBegin("updating my maps");
        Globals::status.Set("get-my-maps", "getting maps...");

        Globals::ClearMaps();

        while (!NadeoServices::IsAuthenticated("NadeoLiveServices")) yield();

        uint offset = 0;
        bool tooManyMaps;

        do {
            auto wait = startnew(CoroutineFunc(Util::WaitToDoNadeoRequestCoro));
            while (wait.IsRunning()) yield();

            auto req = NadeoServices::Get(
                "NadeoLiveServices",
                NadeoServices::BaseURLLive() + "/api/token/map?length=1000&offset=" + offset
            );
            req.Start();
            while (!req.Finished()) yield();
            Globals::requesting = false;
            offset += 1000;

            auto mapList = Json::Parse(req.String())["mapList"];
            tooManyMaps = mapList.Length == 1000;
            for (uint i = 0; i < mapList.Length; i++)
                Globals::AddMap(Models::Map(mapList[i]));
        } while (tooManyMaps);

        Globals::shownMaps = Math::Max(Globals::maps.Length - Globals::hiddenMapsIndex.GetSize(), 0);

        Globals::status.Delete("get-my-maps");
        Util::LogTimerEnd(timerId);
        Locks::myMaps = false;

        startnew(CoroutineFunc(LoadMyMapsThumbnailsCoro));
    }

    void GetMyMapsRecordsCoro() {
        if (Locks::allRecords) return;
        Locks::allRecords = true;
        string timerId = Util::LogTimerBegin("getting records");

        Globals::getAccountNames = false;
        Globals::singleMapRecordStatus = false;
        for (uint i = 0; i < Globals::maps.Length; i++) {
            Globals::status.Set("get-all-records", "getting records... (" + (i + 1) + "/" + Globals::maps.Length + ")");
            auto recordsCoro = startnew(CoroutineFunc(@Globals::maps[i].GetRecordsCoro));
            while (recordsCoro.IsRunning()) yield();
            if (Globals::cancelAllRecords) {
                Globals::cancelAllRecords = false;
                Util::Trace("getting records cancelled by user");
                Locks::allRecords = false;
                break;
            }
        }
        Globals::getAccountNames = true;
        Globals::singleMapRecordStatus = true;

        auto nameCoro = startnew(CoroutineFunc(GetAccountNamesCoro));
        while (nameCoro.IsRunning()) yield();

        Globals::recordsTimestamp = Time::Stamp;

        Globals::status.Delete("get-all-records");
        Util::LogTimerEnd(timerId);
        Locks::allRecords = false;
    }

    void LoadMyMapsThumbnailsCoro() {
        string timerId = Util::LogTimerBegin("loading my map thumbnails");

        for (uint i = 0; i < Globals::maps.Length; i++) {
            Globals::status.Set("load-thumbs", "loading thumbnails... (" + (i + 1) + "/" + Globals::maps.Length + ")");
            auto map = @Globals::maps[i];
            auto coro = startnew(CoroutineFunc(map.LoadThumbnailCoro));
            while (coro.IsRunning()) yield();
        }

        Globals::status.Delete("load-thumbs");
        Util::LogTimerEnd(timerId);
    }
}