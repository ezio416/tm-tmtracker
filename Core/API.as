/*
c 2023-07-06
m 2023-07-06
*/

namespace API {
    // void GetAccountNamesCoro() {
    //     string timerId = Util::LogTimerBegin("getting account names");

    //     string[] missing;
    //     dictionary names;

    //     for (uint i = 0; i < Globals::accounts.Length; i++)
    //         if (Globals::accounts[i].IsNameExpired())
    //             Globals::accounts[i].accountName = "";

    //     auto ids = Globals::accountIds.GetKeys();
    //     for (uint i = 0; i < ids.Length; i++)
    //         if (string(Globals::accountIds[ids[i]]) == "")
    //             missing.InsertLast(ids[i]);

    //     auto ret = NadeoServices::GetDisplayNamesAsync(missing);
    //     for (uint i = 0; i < missing.Length; i++) {
    //         string id = missing[i];
    //         names.Set(id, string(ret[id]));
    //     }

    //     for (uint i = 0; i < Globals::accounts.Length; i++) {
    //         auto account = @Globals::accounts[i];
    //         if (account.accountName != "") continue;
    //         account.accountName = string(names[account.accountId]);
    //         account.SetNameExpire();
    //         Globals::accountIds.Set(account.accountId, account.accountName);
    //     }

    //     Util::LogTimerEnd(timerId);
    // }

    void GetMyMapsCoro() {
        string timerId = Util::LogTimerBegin("updating my maps");
        Globals::status.Set("get-my-maps", "getting maps...");

        Globals::ClearMyMaps();

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
                Globals::AddMyMap(Models::Map(mapList[i]));
        } while (tooManyMaps);

        // for (int i = Globals::myMaps.Length - 1; i >= 0; i--)
        //     if (Globals::myHiddenMapIds.Exists(Globals::myMaps[i].mapId))
        //         Globals::myMaps.RemoveAt(i);

        Globals::status.Delete("get-my-maps");
        Util::LogTimerEnd(timerId);

        // auto mapSaveCoro = startnew(CoroutineFunc(DB::MyMaps::SaveCoro));
        // while (mapSaveCoro.IsRunning()) yield();
        // auto mapLoadCoro = startnew(CoroutineFunc(DB::MyMaps::LoadCoro));
        // while (mapLoadCoro.IsRunning()) yield();
        // auto recLoadCoro = startnew(CoroutineFunc(DB::Records::LoadCoro));
        // while (recLoadCoro.IsRunning()) yield();

        startnew(CoroutineFunc(Maps::LoadMyMapsThumbnailsCoro));
    }

    // void GetMyMapsRecordsCoro() {
    //     string timerId = Util::LogTimerBegin("getting my map records");

    //     Globals::getAccountNames = false;
    //     // Globals::save = false;
    //     for (uint i = 0; i < Globals::myMaps.Length; i++) {
    //         auto coro = startnew(CoroutineFunc(Globals::myMaps[i].GetRecordsCoro));
    //         while (coro.IsRunning()) yield();
    //     }
    //     Globals::getAccountNames = true;
    //     // Globals::save = true;

    //     auto nameCoro = startnew(CoroutineFunc(API::GetAccountNamesCoro));
    //     while (nameCoro.IsRunning()) yield();

    //     // auto accSaveCoro = startnew(CoroutineFunc(DB::AllAccounts::SaveCoro));
    //     // while (accSaveCoro.IsRunning()) yield();
    //     // auto accLoadCoro = startnew(CoroutineFunc(DB::AllAccounts::LoadCoro));
    //     // while (accLoadCoro.IsRunning()) yield();
    //     // auto mapCoro = startnew(CoroutineFunc(DB::MyMaps::SaveCoro));
    //     // while (mapCoro.IsRunning()) yield();
    //     // auto recCoro = startnew(CoroutineFunc(DB::Records::SaveCoro));
    //     // while (recCoro.IsRunning()) yield();

    //     Util::LogTimerEnd(timerId);
    // }
}