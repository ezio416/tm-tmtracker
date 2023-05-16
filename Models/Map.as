/*
c 2023-05-16
m 2023-05-16
*/

namespace Models {
    class Map {
        string   authorId;
        uint     authorTime;
        bool     badUploadTime;
        uint     bronzeTime;
        string   downloadUrl;
        uint     goldTime;
        string   mapId;
        string   mapNameColor;
        string   mapNameRaw;
        string   mapNameText;
        string   mapUid;
        Record[] records;
        uint     silverTime;
        string   thumbnailUrl;
        uint     uploadedUnix;

        int opCmp(int i) { return uploadedUnix - i; }
        int opCmp(Map m) { return uploadedUnix - m.uploadedUnix; }

        Map() {}

        Map(Json::Value map) {
            mapUid       = map["uid"];
            mapId        = map["mapId"];
            mapNameRaw   = map["name"];
            mapNameColor = ColoredString(mapNameRaw);
            mapNameText  = StripFormatCodes(mapNameRaw);
            authorId     = map["author"];
            authorTime   = map["authorTime"];
            goldTime     = map["goldTime"];
            silverTime   = map["silverTime"];
            bronzeTime   = map["bronzeTime"];
            downloadUrl  = string(map["downloadUrl"]).Replace("\\", "");
            thumbnailUrl = string(map["thumbnailUrl"]).Replace("\\", "");
            if (map["uploadTimestamp"] < 1600000000) {
                badUploadTime = true;  // for some maps, Nadeo only provides the year
                uploadedUnix  = map["updateTimestamp"];
            } else
                uploadedUnix  = map["uploadTimestamp"];
        }
    }
}