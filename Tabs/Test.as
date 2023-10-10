/*
c 2023-10-09
m 2023-10-09
*/

namespace Tabs {
    void Tab_Test() {
        if (!UI::BeginTabItem(Icons::DevTo + " Test"))
            return;

        if (UI::Button("get my records"))
            startnew(CoroutineFunc(Test::GetMyRecordsCoro));

        UI::EndTabItem();
    }
}

namespace Test {
    string[]     mapIds;
    Json::Value@ myRecords = Json::Object();

    void GetMyRecordsCoro() {
        while (!NadeoServices::IsAuthenticated(Globals::apiCore))
            yield();

        mapIds.RemoveRange(0, mapIds.Length);

        sleep(500);
        Net::HttpRequest@ req = NadeoServices::Get(
            Globals::apiCore,
            NadeoServices::BaseURLCore() +
            "/accounts/" + Globals::myAccountId + "/mapRecords"
        );
        req.Start();
        while (!req.Finished())
            yield();

        uint64 now = Time::Now;
        @myRecords = Json::Parse(req.String());
        print("parsing " + myRecords.Length + " records took " + (Time::Now - now) + " ms");

        for (uint i = 0; i < myRecords.Length; i++)
            mapIds.InsertLast(myRecords[i]["mapId"]);

        startnew(CoroutineFunc(GetMapInfoCoro));
    }

    void GetMapInfoCoro() {
        while (mapIds.Length > 0) {
            string[] group;
            int idsToAdd = Math::Min(mapIds.Length, 206);
            for (int i = 0; i < idsToAdd; i++)
                group.InsertLast(mapIds[i]);
            mapIds.RemoveRange(0, idsToAdd);

            sleep(500);
            Net::HttpRequest@ req = NadeoServices::Get(
                Globals::apiCore,
                NadeoServices::BaseURLCore() +
                "/maps/?mapIdList=" + string::Join(group, "%2C")
            );
            req.Start();
            while (!req.Finished())
                yield();

            uint64 now = Time::Now;
            Json::Value@ theseMaps = Json::Parse(req.String());
            print("parsing " + theseMaps.Length + " maps took " + (Time::Now - now) + " ms");

            for (uint i = 0; i < theseMaps.Length; i++) {
                Models::Map map = Models::Map(theseMaps[i], true);
                if (Globals::mapsDict.Exists(map.mapId))
                    continue;
                Globals::AddMap(map);
            }
        }
    }
}