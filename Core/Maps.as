/*
c 2023-05-16
m 2023-05-25
*/

// Functions for getting/loading data on maps
namespace Maps {
    void GetMyMapsCoro() {
        auto now = Time::Now;
        if (Settings::logEnabled)
            trace("updating my maps...");

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

        if (Settings::logEnabled && Settings::logDurations)
            trace("updating my maps took " + (Time::Now - now) + " ms");

        DB::MyMaps::Save();
        DB::MyMaps::Load();
        DB::Records::Load();
    }

    void GetMyMapsRecordsCoro() {
        auto now = Time::Now;
        if (Settings::logEnabled)
            trace("getting my map records...");

        for (uint i = 0; i < Storage::myMaps.Length; i++) {
            auto coro = startnew(CoroutineFunc(Storage::myMaps[i].GetRecordsCoro));
            while (coro.IsRunning()) yield();
        }

        if (Settings::logEnabled && Settings::logDurations)
            trace("getting my map records took " + (Time::Now - now) + " ms");
    }

    void GetMyMapsThumbnailsCoro() {
        auto now = Time::Now;
        if (Settings::logEnabled)
            trace("getting my map thumbnails...");

        for (uint i = 0; i < Storage::myMaps.Length; i++) {
            auto @coro = startnew(CoroutineFunc(Storage::myMaps[i].GetThumbnailCoro));
            while (coro.IsRunning()) yield();
        }

        if (Settings::logEnabled && Settings::logDurations)
            trace("getting " + Storage::myMaps.Length + " thumbnails took " + (Time::Now - now) + " ms");
    }

    void LoadMyMapsThumbnailsCoro() {
        auto now = Time::Now;
        if (Settings::logEnabled)
            trace("loading my map thumbnails...");

        for (uint i = 0; i < Storage::myMaps.Length; i++) {
            auto @coro = startnew(CoroutineFunc(Storage::myMaps[i].LoadThumbnailCoro));
            while (coro.IsRunning()) yield();
        }

        if (Settings::logEnabled && Settings::logDurations)
            trace("loading " + Storage::myMaps.Length + " thumbnails took " + (Time::Now - now) + " ms");
    }
}