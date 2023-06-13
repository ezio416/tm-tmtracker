/*
c 2023-05-16
m 2023-06-13
*/

// Functions for getting/loading data on maps
namespace Maps {
    void GetMyMapsCoro() {
        string timerId = Util::LogTimerBegin("updating my maps");

        Globals::ClearMyMaps();

        while (!NadeoServices::IsAuthenticated("NadeoLiveServices")) yield();

        uint offset = 0;
        bool tooManyMaps;

        do {
            auto wait = startnew(CoroutineFunc(Util::WaitToDoNadeoRequestCoro));
            while (wait.IsRunning()) yield();

            auto req = NadeoServices::Get(
                "NadeoLiveServices",
                NadeoServices::BaseURL() + "/api/token/map?length=1000&offset=" + offset
            );
            offset += 1000;
            req.Start();
            while (!req.Finished()) yield();

            auto mapList = Json::Parse(req.String())["mapList"];
            tooManyMaps = mapList.Length == 1000;
            for (uint i = 0; i < mapList.Length; i++)
                Globals::AddMyMap(Models::Map(mapList[i]));

            Globals::requestsInProgress--;
        } while (tooManyMaps);

        for (int i = Globals::myMaps.Length - 1; i >= 0; i--)
            if (Globals::myHiddenMapIds.Exists(Globals::myMaps[i].mapId))
                Globals::myMaps.RemoveAt(i);

        Util::LogTimerEnd(timerId);

        DB::MyMaps::Save();
        DB::MyMaps::Load();
        DB::Records::Load();
    }

    void GetMyMapsRecordsCoro() {
        string timerId = Util::LogTimerBegin("getting my map records");

        Globals::getAccountNames = false;
        for (uint i = 0; i < Globals::myMaps.Length; i++) {
            auto coro = startnew(CoroutineFunc(Globals::myMaps[i].GetRecordsCoro));
            while (coro.IsRunning()) yield();
        }
        Globals::getAccountNames = true;

        auto coro = startnew(CoroutineFunc(Accounts::GetAccountNamesCoro));
        while (coro.IsRunning()) yield();

        Util::LogTimerEnd(timerId);
    }

    void GetMyMapsThumbnailsCoro() {
        string timerId = Util::LogTimerBegin("getting my map thumbnails");

        for (uint i = 0; i < Globals::myMaps.Length; i++) {
            auto @coro = startnew(CoroutineFunc(Globals::myMaps[i].GetThumbnailCoro));
            while (coro.IsRunning()) yield();
        }

        Util::LogTimerEnd(timerId);
    }

    void LoadMyMapsThumbnailsCoro() {
        string timerId = Util::LogTimerBegin("loading my map thumbnails");

        for (uint i = 0; i < Globals::myMaps.Length; i++) {
            auto @coro = startnew(CoroutineFunc(Globals::myMaps[i].LoadThumbnailCoro));
            while (coro.IsRunning()) yield();
        }

        Util::LogTimerEnd(timerId);
    }
}