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
        // string ghostUrl;
        string mapId;
        string mapName;
        string mapUid;
        // uint   medal;
        uint   position;
        // string recordId;
        uint   time;
        // uint   timestamp;
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
    }
}