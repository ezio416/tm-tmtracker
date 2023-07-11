/*
c 2023-05-16
m 2023-07-10
*/

namespace Models {
    class Record {
        string accountId;
        string mapId;
        string mapName;
        string mapUid;
        uint   medals = 0;
        uint   position;
        string recordFakeId;
        uint   time;
        string zoneId;

        string get_zoneName() { return Zones::Get(zoneId); }

        Record() { }
        Record(Json::Value record) {
            accountId = record["accountId"];
            position  = record["position"];
            time      = record["score"];
            zoneId    = record["zoneId"];
        }

        void SetMedals(Map@ map) {
            if (time <= map.bronzeTime) medals++;
            if (time <= map.silverTime) medals++;
            if (time <= map.goldTime)   medals++;
            if (time <= map.authorTime) medals++;
        }
    }
}