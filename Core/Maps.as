/*
c 2023-05-16
m 2023-05-16
*/

namespace Core {
    Models::Map[] GetMyMaps() {
        string live = "NadeoLiveServices";
        NadeoServices::AddAudience(live);
        while (!NadeoServices::IsAuthenticated(live)) yield();

        Models::Map[] maps;
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
                maps.InsertLast(Models::Map(mapList[i]));
        } while (tooManyMaps);

        // insertion sort, most maps are already in order
        for (uint i = 1; i < maps.Length; i++) {
            Models::Map key = maps[i];
            int j = i - 1;
            for (j; j >= 0 && maps[j] > key; j--)
                maps[j + 1] = maps[j];
            maps[j + 1] = key;
        }

        if (Settings::sortMapsNewest)
            maps.Reverse();
        return maps;
    }
}