/*
c 2023-05-16
m 2023-05-20
*/

namespace Models {
    class Record {
        string accountId;
        string accountName;
        string ghostUrl;
        string mapId;
        string mapName;
        string mapUid;
        uint   medal;
        uint   position;
        string recordId;
        uint   time;
        string timeFormatted;
        uint   timestamp;
        string zoneId;
        string zoneName;

        Record() { }

        Record(Json::Value record) {
            accountId = record["accountId"];
            zoneId    = record["zoneId"];
            position  = record["position"];
            time      = record["score"];

            if (Storage::zones == null) Zones::Load();
            try   { zoneName = Storage::zones[zoneId]; }
            catch { zoneName = record["zoneName"]; }
        }
    }
}