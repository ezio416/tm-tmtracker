/*
c 2023-05-16
m 2023-05-20
*/

// Classes for holding data gathered during plugin operation
namespace Models {
    // Data on a record driven on a map
    class Record {
        string accountId;
        string accountName;
        string mapId;
        string mapName;
        string mapUid;
        uint   position;
        string recordFakeId;
        uint   time;
        string zoneId;
        string zoneName;

        Record() { }

        Record(Json::Value record) {
            accountId = record["accountId"];
            zoneId    = record["zoneId"];
            position  = record["position"];
            time      = record["score"];

            Zones::Load();
            try   { zoneName = Storage::zones[zoneId]; }
            catch { zoneName = record["zoneName"]; }
        }

        Record(SQLite::Statement@ s) {
            accountId    = s.GetColumnString("accountId");
            accountName  = s.GetColumnString("accountName");
            mapId        = s.GetColumnString("mapId");
            mapName      = s.GetColumnString("mapName");
            mapUid       = s.GetColumnString("mapUid");
            position     = s.GetColumnInt("position");
            recordFakeId = s.GetColumnString("recordFakeId");
            time         = s.GetColumnInt("time");
            zoneId       = s.GetColumnString("zoneId");
            zoneName     = s.GetColumnString("zoneName");
        }
    }
}