/*
c 2023-07-06
m 2023-07-11
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

        Globals::status.Delete("account-names");
        Util::LogTimerEnd(timerId);
    }

    void GetMyMapsCoro() {
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

        Globals::status.Delete("get-my-maps");
        Util::LogTimerEnd(timerId);

        startnew(CoroutineFunc(LoadMyMapsThumbnailsCoro));
    }

    void GetMyMapsRecordsCoro() {
        string timerId = Util::LogTimerBegin("getting records");

        Globals::getAccountNames = false;
        Globals::singleMapRecordStatus = false;
        for (uint i = 0; i < Globals::maps.Length; i++) {
            Globals::status.Set("get-all-records", "getting records... (" + (i + 1) + "/" + Globals::maps.Length + ")");
            auto recordsCoro = startnew(CoroutineFunc(@Globals::maps[i].GetRecordsCoro));
            while (recordsCoro.IsRunning()) yield();
        }
        Globals::getAccountNames = true;
        Globals::singleMapRecordStatus = true;

        auto nameCoro = startnew(CoroutineFunc(GetAccountNamesCoro));
        while (nameCoro.IsRunning()) yield();

        Globals::status.Delete("get-all-records");
        Util::LogTimerEnd(timerId);
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