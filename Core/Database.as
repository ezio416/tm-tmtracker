/*
c 2023-05-16
m 2023-05-16
*/

namespace Core {
    // void LoadMaps() {
    // }

    void SaveMaps() {
        Storage::db.Execute("""
            CREATE TABLE IF NOT EXISTS maps (
                authorId      CHAR(36),
                authorTime    INT,
                badUploadTime BOOL,
                bronzeTime    INT,
                downloadUrl   CHAR(93),
                goldTime      INT,
                mapId         CHAR(36),
                mapNameColor  TEXT,
                mapNameRaw    TEXT,
                mapNameText   TEXT,
                mapUid        VARCHAR(27) PRIMARY KEY,
                silverTime    INT,
                thumbnailUrl  CHAR(97),
                uploadedUnix  INT
            );
        """);

        for (uint i = 0; i < Storage::maps.Length; i++) {
            auto map = Storage::maps[i];
            SQLite::Statement@ s;
            @s = Storage::db.Prepare("""
                INSERT INTO maps (
                    authorId,
                    authorTime,
                    badUploadTime,
                    bronzeTime,
                    downloadUrl,
                    goldTime,
                    mapId,
                    mapNameColor,
                    mapNameRaw,
                    mapNameText,
                    mapUid,
                    silverTime,
                    thumbnailUrl,
                    uploadedUnix
                ) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?);
            """);
            s.Bind(1,  map.authorId);
            s.Bind(2,  map.authorTime);
            s.Bind(3,  map.badUploadTime ? 1 : 0);
            s.Bind(4,  map.bronzeTime);
            s.Bind(5,  map.downloadUrl);
            s.Bind(6,  map.goldTime);
            s.Bind(7,  map.mapId);
            s.Bind(8,  map.mapNameColor);
            s.Bind(9,  map.mapNameRaw);
            s.Bind(10, map.mapNameText);
            s.Bind(11, map.mapUid);
            s.Bind(12, map.silverTime);
            s.Bind(13, map.thumbnailUrl);
            s.Bind(14, map.uploadedUnix);
            s.Execute();
        }
    }
}