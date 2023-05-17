/*
c 2023-05-16
m 2023-05-17
*/

namespace DB {
    namespace MyMaps {
        void LoadAll() {
            auto now = Time::Now;
            trace("loading my maps from " + Storage::dbFile);

            SQLite::Statement@ s;
            @Storage::db = SQLite::Database(Storage::dbFile);

            Storage::myMaps.RemoveRange(0, Storage::myMaps.Length);
            try { @s = Storage::db.Prepare("SELECT * FROM MyMaps"); } catch {
                trace("no MyMaps table in database, plugin hasn't been run yet");
                if (Settings::printDurations)
                    trace("returning after " + (Time::Now - now) + " ms");
                return;
            }
            while (true) {
                if (!s.NextRow()) break;
                Storage::myMaps.InsertLast(Models::Map(s));
            }

            Storage::myMapsIgnored.RemoveRange(0, Storage::myMapsIgnored.Length);
            Storage::myMapsIgnoredUids.DeleteAll();
            try { @s = Storage::db.Prepare("SELECT * FROM MyMapsIgnored"); } catch {
                trace("no MyMapsIgnored table in database, maps haven't been ignored yet");
                if (Settings::printDurations)
                    trace("returning after " + (Time::Now - now) + " ms");
                return;
            }
            while (true) {
                if (!s.NextRow()) break;
                auto map = Models::Map(s);
                Storage::myMapsIgnored.InsertLast(map);
                Storage::myMapsIgnoredUids.Set(map.mapUid, "");
            }

            if (Settings::printDurations)
                trace("loading my maps took " + (Time::Now - now) + " ms");
        }

        void SaveAll() {
            auto now = Time::Now;
            trace("saving my maps to " + Storage::dbFile);

            Storage::db.Execute("""
                CREATE TABLE IF NOT EXISTS MyMaps (
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
                );
            """);

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

        void Ignore(Models::Map@ map) {
            auto now = Time::Now;
            trace("ignoring my map (" + map.mapNameText + ") in " + Storage::dbFile);

            Storage::db.Execute("""
                CREATE TABLE IF NOT EXISTS MyMapsIgnored (
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
                );
            """);

            SQLite::Statement@ s;

            @s = Storage::db.Prepare("INSERT INTO MyMapsIgnored SELECT * FROM MyMaps WHERE mapUid=?");
            s.Bind(1, map.mapUid);
            s.Execute();

            @s = Storage::db.Prepare("DELETE FROM MyMaps WHERE mapUid=?");
            s.Bind(1, map.mapUid);
            s.Execute();

            LoadAll();

            if (Settings::printDurations)
                trace("ignoring my map took " + (Time::Now - now) + " ms (includes previous value)");
        }

        void UnIgnore(Models::Map@ map) {
            auto now = Time::Now;
            trace("unignoring my map (" + map.mapNameText + ") in " + Storage::dbFile);

            SQLite::Statement@ s;

            @s = Storage::db.Prepare("INSERT INTO MyMaps SELECT * FROM MyMapsIgnored WHERE mapUid=?");
            s.Bind(1, map.mapUid);
            s.Execute();

            @s = Storage::db.Prepare("DELETE FROM MyMapsIgnored WHERE mapUid=?");
            s.Bind(1, map.mapUid);
            s.Execute();

            LoadAll();

            if (Settings::printDurations)
                trace("unignoring my map took " + (Time::Now - now) + " ms (includes previous value)");
        }
    }
}