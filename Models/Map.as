/*
c 2023-05-16
m 2023-05-16
*/

namespace Models {
    class Map {
        // string   authorName;
        string   authorId;
        uint     authorTime;
        bool     badUploadTime;
        uint     bronzeTime;
        string   downloadUrl;
        uint     goldTime;
        string   mapId;
        // string   mapName;
        string   mapNameRaw;
        string   mapNameText;
        string   mapUid;
        // int      personalMedal;
        // uint     personalTime;
        // Record[] records;
        uint     silverTime;
        string   thumbnailUrl;
        // string   uploadedIsoUtc;
        uint     uploadedUnix;

        int opCmp(int i) { return uploadedUnix - i; }
        int opCmp(Map m) { return uploadedUnix - m.uploadedUnix; }

        Map() {}

        Map(Json::Value map) {
            mapUid       = map["uid"];
            mapId        = map["mapId"];
            mapNameRaw   = map["name"];
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