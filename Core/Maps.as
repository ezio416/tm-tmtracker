/*
c 2023-05-16
m 2023-05-25
*/

// Functions for getting/loading data on maps
namespace Maps {
    void GetMyMapsCoro() {
        string timerId = Various::LogTimerStart("updating my maps");

        Storage::ClearMyMaps();

        while (!NadeoServices::IsAuthenticated("NadeoLiveServices")) yield();

        uint offset = 0;
        bool tooManyMaps;

        do {
            auto wait = startnew(CoroutineFunc(Various::WaitToDoNadeoRequestCoro));
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
                Storage::AddMyMap(Models::Map(mapList[i]));

            Storage::requestsInProgress--;
        } while (tooManyMaps);

        for (int i = Storage::myMaps.Length - 1; i >= 0; i--)
            if (Storage::myHiddenMapUids.Exists(Storage::myMaps[i].mapUid))
                Storage::myMaps.RemoveAt(i);

        Various::LogTimerEnd(timerId);

        DB::MyMaps::Save();
        DB::MyMaps::Load();
        DB::Records::Load();
    }

    void GetMyMapsRecordsCoro() {
        string timerId = Various::LogTimerStart("getting my map records");

        for (uint i = 0; i < Storage::myMaps.Length; i++) {
            auto coro = startnew(CoroutineFunc(Storage::myMaps[i].GetRecordsCoro));
            while (coro.IsRunning()) yield();
        }

        Various::LogTimerEnd(timerId);
    }

    void GetMyMapsThumbnailsCoro() {
        string timerId = Various::LogTimerStart("getting my map thumbnails");

        for (uint i = 0; i < Storage::myMaps.Length; i++) {
            auto @coro = startnew(CoroutineFunc(Storage::myMaps[i].GetThumbnailCoro));
            while (coro.IsRunning()) yield();
        }

        Various::LogTimerEnd(timerId);
    }

    void LoadMyMapsThumbnailsCoro() {
        string timerId = Various::LogTimerStart("loading my map thumbnails");

        for (uint i = 0; i < Storage::myMaps.Length; i++) {
            auto @coro = startnew(CoroutineFunc(Storage::myMaps[i].LoadThumbnailCoro));
            while (coro.IsRunning()) yield();
        }

        Various::LogTimerEnd(timerId);
    }
}