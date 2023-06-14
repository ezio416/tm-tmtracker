/*
c 2023-05-16
m 2023-06-13
*/

// Classes for holding data gathered during plugin operation
namespace Models {
    // Data on a record driven on a map
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

        Record() { }

        Record(Json::Value record) {
            accountId = record["accountId"];
            position  = record["position"];
            time      = record["score"];
            zoneId    = record["zoneId"];
        }

        Record(SQLite::Statement@ s) {
            accountId    = s.GetColumnString("accountId");
            mapId        = s.GetColumnString("mapId");
            position     = s.GetColumnInt("position");
            recordFakeId = s.GetColumnString("recordFakeId");
            time         = s.GetColumnInt("time");
            zoneId       = s.GetColumnString("zoneId");
        }

        string get_zoneName() {
            return Zones::Get(zoneId);
        }

        void SetMedals(Map@ map) {
            if (time <= map.bronzeTime) medals++;
            if (time <= map.silverTime) medals++;
            if (time <= map.goldTime)   medals++;
            if (time <= map.authorTime) medals++;
        }
    }
}