/*
c 2023-05-16
m 2023-05-19
*/

namespace Maps {
    void GetMyMaps() {
        auto now = Time::Now;

        string live = "NadeoLiveServices";
        NadeoServices::AddAudience(live);
        while (!NadeoServices::IsAuthenticated(live)) yield();

        Storage::myMaps.RemoveRange(0, Storage::myMaps.Length);

        uint offset = 0;
        bool tooManyMaps;

        do {
            auto req = NadeoServices::Get(
                live,
                NadeoServices::BaseURL() + "/api/token/map?length=1000&offset=" + offset
            );
            offset += 1000;
            req.Start();
            while (!req.Finished()) continue;

            auto mapList = Json::Parse(req.String())["mapList"];
            tooManyMaps = mapList.Length == 1000;
            for (uint i = 0; i < mapList.Length; i++)
                Storage::myMaps.InsertLast(Models::Map(mapList[i]));
        } while (tooManyMaps);

        for (int i = Storage::myMaps.Length - 1; i >= 0; i--)
            if (Storage::myMapsHiddenUids.Exists(Storage::myMaps[i].mapUid))
                Storage::myMaps.RemoveAt(i);

        if (Settings::printDurations)
            trace("refreshing my maps took " + (Time::Now - now) + " ms");

        DB::MyMaps::Save();
        DB::MyMaps::Load();
    }

    void GetMyMapsThumbnailsCoro() {
        auto now = Time::Now;
        trace("getting thumbnails");

        for (uint i = 0; i < Storage::myMaps.Length; i++) {
            auto @coro = startnew(CoroutineFunc(Storage::myMaps[i].GetThumbnailCoro));
            while (coro.IsRunning()) yield();
        }

        if (Settings::printDurations)
            trace("getting " + Storage::myMaps.Length + " thumbnails took " + (Time::Now - now) + " ms");
    }

    void LoadMyMapsThumbnailsCoro() {
        auto now = Time::Now;
        trace("loading my map thumbnails...");

        for (uint i = 0; i < Storage::myMaps.Length; i++) {
            auto @coro = startnew(CoroutineFunc(Storage::myMaps[i].LoadThumbnailCoro));
            while (coro.IsRunning()) yield();
        }

        if (Settings::printDurations)
            trace("loading " + Storage::myMaps.Length + " thumbnails took " + (Time::Now - now) + " ms");
    }
}