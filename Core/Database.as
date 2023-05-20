/*
c 2023-05-16
m 2023-05-19
*/

namespace DB {
    namespace MyMaps {
        string tableColumns = """ (
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
            timestamp     INT
        ); """;

        void Load() {
            auto now = Time::Now;
            trace("loading my maps from " + Storage::dbFile);

            SQLite::Statement@ s;
            @Storage::db = SQLite::Database(Storage::dbFile);

            Storage::myMaps.RemoveRange(0, Storage::myMaps.Length);
            try {
                string order = (Settings::sortMapsNewest) ? "DESC" : "ASC";
                @s = Storage::db.Prepare("SELECT * FROM MyMaps ORDER BY timestamp " + order);
            } catch {
                trace("no MyMaps table in database, plugin hasn't been run yet");
                if (Settings::printDurations)
                    trace("returning after " + (Time::Now - now) + " ms");
                return;
            }
            while (true) {
                if (!s.NextRow()) break;
                Storage::myMaps.InsertLast(Models::Map(s));
            }

            Storage::myMapsHidden.RemoveRange(0, Storage::myMapsHidden.Length);
            Storage::myMapsHiddenUids.DeleteAll();
            bool anyHidden = false;
            try {
                @s = Storage::db.Prepare("SELECT * FROM MyMapsHidden");
                anyHidden = true;
            } catch { trace("no MyMapsHidden table in database, maps haven't been hidden yet"); }

            if (anyHidden)
                while (true) {
                    if (!s.NextRow()) break;
                    auto map = Models::Map(s);
                    Storage::myMapsHidden.InsertLast(map);
                    Storage::myMapsHiddenUids.Set(map.mapUid, "");
                }

            if (Settings::printDurations)
                trace("loading my maps took " + (Time::Now - now) + " ms");
        }

        void Save() {
            auto now = Time::Now;
            trace("saving my maps to " + Storage::dbFile);

            Storage::db.Execute("CREATE TABLE IF NOT EXISTS MyMaps" + tableColumns);

            for (uint i = 0; i < Storage::myMaps.Length; i++) {
                auto map = Storage::myMaps[i];
                SQLite::Statement@ s;
                @s = Storage::db.Prepare("""
                    INSERT INTO MyMaps (
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
                        timestamp
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
                s.Bind(14, map.timestamp);
                s.Execute();
            }

            if (Settings::printDurations)
                trace("saving my maps took " + (Time::Now - now) + " ms");
        }

        void Hide(Models::Map map) {
            auto now = Time::Now;
            trace("hiding my map (" + map.mapNameText + ") in " + Storage::dbFile);

            Storage::db.Execute("CREATE TABLE IF NOT EXISTS MyMapsHidden" + tableColumns);

            SQLite::Statement@ s;

            @s = Storage::db.Prepare("INSERT INTO MyMapsHidden SELECT * FROM MyMaps WHERE mapUid=?");
            s.Bind(1, map.mapUid);
            s.Execute();

            @s = Storage::db.Prepare("DELETE FROM MyMaps WHERE mapUid=?");
            s.Bind(1, map.mapUid);
            s.Execute();

            if (Settings::printDurations)
                trace("hiding my map took " + (Time::Now - now) + " ms");

            Load();
        }

        void UnHide(Models::Map map) {
            auto now = Time::Now;
            trace("unhiding my map (" + map.mapNameText + ") in " + Storage::dbFile);

            SQLite::Statement@ s;

            @s = Storage::db.Prepare("INSERT INTO MyMaps SELECT * FROM MyMapsHidden WHERE mapUid=?");
            s.Bind(1, map.mapUid);
            s.Execute();

            @s = Storage::db.Prepare("DELETE FROM MyMapsHidden WHERE mapUid=?");
            s.Bind(1, map.mapUid);
            s.Execute();

            if (Settings::printDurations)
                trace("unhiding my map took " + (Time::Now - now) + " ms");
        }

        void Nuke() {
            auto now = Time::Now;
            trace("nuking my map data from program and " + Storage::dbFile);

            Storage::ClearCurrentMap();
            Storage::ClearMyMaps();
            Storage::ClearMyMapsHidden();
            Storage::myMapsHiddenUids.DeleteAll();

            try { Storage::db.Execute("DELETE FROM MyMaps");       } catch { }
            try { Storage::db.Execute("DELETE FROM MyMapsHidden"); } catch { }

            if (Settings::printDurations)
                trace("nuking my map data took " + (Time::Now - now) + " ms");
        }
    }
}