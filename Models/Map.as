/*
c 2023-05-16
m 2023-05-17
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
        uint     timestamp;

        int opCmp(int i) { return timestamp - i; }
        int opCmp(Map m) { return timestamp - m.timestamp; }

        Map() {}

        Map(Json::Value map) {
            mapUid       = map['uid'];
            mapId        = map['mapId'];
            mapNameRaw   = map['name'];
            mapNameColor = ColoredString(mapNameRaw);
            mapNameText  = StripFormatCodes(mapNameRaw);
            authorId     = map['author'];
            authorTime   = map['authorTime'];
            goldTime     = map['goldTime'];
            silverTime   = map['silverTime'];
            bronzeTime   = map['bronzeTime'];
            downloadUrl  = string(map['downloadUrl']).Replace('\\', '');
            thumbnailUrl = string(map['thumbnailUrl']).Replace('\\', '');
            if (map['uploadTimestamp'] < 1600000000) {
                badUploadTime = true;  // for some maps, Nadeo only provides the year
                timestamp  = map['updateTimestamp'];
            } else
                timestamp  = map['uploadTimestamp'];
        }

        Map(SQLite::Statement@ s) {
            authorId      = s.GetColumnString('authorId');
            authorTime    = s.GetColumnInt('authorTime');
            badUploadTime = s.GetColumnInt('badUploadTime') == 1 ? true : false;
            bronzeTime    = s.GetColumnInt('bronzeTime');
            downloadUrl   = s.GetColumnString('downloadUrl');
            goldTime      = s.GetColumnInt('goldTime');
            mapId         = s.GetColumnString('mapId');
            mapNameRaw    = s.GetColumnString('mapNameRaw');
            mapNameColor  = ColoredString(mapNameRaw);
            mapNameText   = StripFormatCodes(mapNameRaw);
            mapUid        = s.GetColumnString('mapUid');
            silverTime    = s.GetColumnInt('silverTime');
            thumbnailUrl  = s.GetColumnString('thumbnailUrl');
            timestamp     = s.GetColumnInt('timestamp');
        }
    }
}