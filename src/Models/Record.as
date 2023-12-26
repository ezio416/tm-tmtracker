// c 2023-05-16
// m 2023-12-26

namespace Models { class Record {
    string accountId;
    int    mapAuthorDelta = 0;
    uint   mapAuthorTime  = 0;
    string mapId;
    string mapNameColor;
    string mapNameText;
    string mapUid;
    uint   medals         = 0;
    uint   position;
    string recordFakeId;
    string recordId;
    uint   time;
    string timestampIso;
    int64  timestampUnix;
    string zoneId;

    Record() { }
    Record(Json::Value@ record) {
        accountId = record["accountId"];
        position  = record["position"];
        time      = record["score"];
        zoneId    = record["zoneId"];
    }
    Record(Json::Value@ record, bool fromMyRecords) {
        accountId     = Globals::myAccountId;
        mapId         = record["mapId"];
        medals        = record["medal"];
        time          = record["recordScore"]["time"];
        timestampIso  = record["timestamp"];
        timestampUnix = Util::IsoToUnix(timestampIso);
    }
    Record(SQLite::Statement@ s) {
        accountId     = s.GetColumnString("accountId");
        mapId         = s.GetColumnString("mapId");
        position      = s.GetColumnInt   ("position");
        recordFakeId  = s.GetColumnString("recordFakeId");
        recordId      = s.GetColumnString("recordId");
        time          = s.GetColumnInt   ("time");
        timestampUnix = s.GetColumnInt   ("timestampUnix");
    }

    void SetMedals(Map@ map) {
        if (time <= map.bronzeTime) medals++;
        if (time <= map.silverTime) medals++;
        if (time <= map.goldTime)   medals++;
        if (time <= map.authorTime) medals++;
    }
}}