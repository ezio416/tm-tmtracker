/*
c 2023-05-16
m 2023-05-25
*/

// Functions for the TMTracker.db file
namespace DB {
    // Functions relating to drivers of any map
    namespace Accounts {
        string tableColumns = """ (
            accountId   CHAR(36) PRIMARY KEY,
            accountName TEXT,
            nameExpire  INT
        ); """;

        void Clear() {
            auto now = Time::Now;
            trace("clearing accounts from program and file...");



            if (Settings::printDurations)
                trace("clearing accounts took " + (Time::Now - now) + " ms");
        }

        void Load() {
            auto now = Time::Now;
            trace("loading accounts from file...");



            if (Settings::printDurations)
                trace("loading accounts took " + (Time::Now - now) + " ms");
        }

        void Save() {
            auto now = Time::Now;
            trace("saving accounts to file...");



            if (Settings::printDurations)
                trace("saving accounts took " + (Time::Now - now) + " ms");
        }
    }

    // Functions relating to the user's own uploaded maps
    namespace MyMaps {
        string tableColumns = """ (
            authorId         CHAR(36),
            authorTime       INT,
            badUploadTime    BOOL,
            bronzeTime       INT,
            downloadUrl      CHAR(93),
            goldTime         INT,
            mapId            CHAR(36),
            mapNameColor     TEXT,
            mapNameRaw       TEXT,
            mapNameText      TEXT,
            mapUid           VARCHAR(27) PRIMARY KEY,
            recordsTimestamp INT,
            silverTime       INT,
            thumbnailUrl     CHAR(97),
            timestamp        INT
        ); """;

        void Clear() {
            auto now = Time::Now;
            trace("clearing my map data from program and " + Storage::dbFile);

            Storage::ClearCurrentMaps();
            Storage::ClearMyHiddenMaps();
            Storage::ClearMyMaps();

            try { Storage::db.Execute("DELETE FROM MyMaps");       } catch { }
            try { Storage::db.Execute("DELETE FROM MyHiddenMaps"); } catch { }

            if (Settings::printDurations)
                trace("clearing my map data took " + (Time::Now - now) + " ms");
        }

        void Load() {
            auto now = Time::Now;
            trace("loading my maps from " + Storage::dbFile);

            Storage::ClearMyMaps();

            SQLite::Statement@ s;
            @Storage::db = SQLite::Database(Storage::dbFile);
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
                Storage::AddMyMap(Models::Map(s));
            }

            Storage::ClearMyHiddenMaps();
            bool anyHidden = false;
            try {
                @s = Storage::db.Prepare("SELECT * FROM MyHiddenMaps");
                anyHidden = true;
            } catch { trace("no MyHiddenMaps table in database, maps haven't been hidden yet"); }

            if (anyHidden)
                while (true) {
                    if (!s.NextRow()) break;
                    Storage::AddMyHiddenMap(Models::Map(s));
                }

            if (Settings::printDurations)
                trace("loading my maps took " + (Time::Now - now) + " ms");

            startnew(CoroutineFunc(Maps::LoadMyMapsThumbnailsCoro));
        }

        void Save() {
            auto now = Time::Now;
            trace("saving my maps to " + Storage::dbFile);

            Storage::db.Execute("CREATE TABLE IF NOT EXISTS MyMaps" + tableColumns);

            for (uint i = 0; i < Storage::myMaps.Length; i++) {
                auto map = Storage::myMaps[i];
                SQLite::Statement@ s;
                try {
                    if (map.recordsTimestamp == 0) throw("");
                    @s = Storage::db.Prepare("UPDATE MyMaps SET recordsTimestamp=? WHERE mapUid=?");
                    s.Bind(1, map.recordsTimestamp);
                    s.Bind(2, map.mapUid);
                    s.Execute();
                } catch {
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
                            recordsTimestamp,
                            silverTime,
                            thumbnailUrl,
                            timestamp
                        ) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?);
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
                    s.Bind(12, map.recordsTimestamp);
                    s.Bind(13, map.silverTime);
                    s.Bind(14, map.thumbnailUrl);
                    s.Bind(15, map.timestamp);
                    s.Execute();
                }
            }

            if (Settings::printDurations)
                trace("saving my maps took " + (Time::Now - now) + " ms");
        }

        void Hide(Models::Map map) {
            auto now = Time::Now;
            trace(map.logName + "hiding in " + Storage::dbFile);

            Storage::db.Execute("CREATE TABLE IF NOT EXISTS MyHiddenMaps" + tableColumns);

            SQLite::Statement@ s;

            @s = Storage::db.Prepare("INSERT INTO MyHiddenMaps SELECT * FROM MyMaps WHERE mapUid=?");
            s.Bind(1, map.mapUid);
            s.Execute();

            @s = Storage::db.Prepare("DELETE FROM MyMaps WHERE mapUid=?");
            s.Bind(1, map.mapUid);
            s.Execute();

            if (Settings::printDurations)
                trace(map.logName + "hiding took " + (Time::Now - now) + " ms");

            Load();
        }

        void UnHide(Models::Map map) {
            auto now = Time::Now;
            trace(map.logName + "unhiding in " + Storage::dbFile);

            SQLite::Statement@ s;

            @s = Storage::db.Prepare("INSERT INTO MyMaps SELECT * FROM MyHiddenMaps WHERE mapUid=?");
            s.Bind(1, map.mapUid);
            s.Execute();

            @s = Storage::db.Prepare("DELETE FROM MyHiddenMaps WHERE mapUid=?");
            s.Bind(1, map.mapUid);
            s.Execute();

            if (Settings::printDurations)
                trace(map.logName + "unhiding took " + (Time::Now - now) + " ms");

            Load();
        }
    }

    // Functions relating to records driven on any map
    namespace Records {
        string tableColumns = """ (
            accountId    CHAR(36),
            accountName  TEXT,
            mapId        CHAR(36),
            mapName      TEXT,
            mapUid       VARCHAR(27),
            position     INT,
            recordFakeId CHAR(73) PRIMARY KEY,
            time         INT,
            zoneId       CHAR(36),
            zoneName     TEXT
        ); """;

        void Clear() {
            auto now = Time::Now;
            trace("clearing records from program and " + Storage::dbFile);

            Storage::ClearRecords();

            try { Storage::db.Execute("DELETE FROM Records"); } catch { }

            if (Settings::printDurations)
                trace("clearing records took " + (Time::Now - now) + " ms");
        }

        void Load() {
            auto now = Time::Now;
            trace("loading records from " + Storage::dbFile);

            Storage::ClearRecords();

            SQLite::Statement@ s;
            @Storage::db = SQLite::Database(Storage::dbFile);

            try {
                @s = Storage::db.Prepare("SELECT * FROM Records");
            } catch {
                trace("no Records table in database, records haven't been gotten yet");
                if (Settings::printDurations)
                    trace("returning after " + (Time::Now - now) + " ms");
                return;
            }
            while (true) {
                if (!s.NextRow()) break;
                Storage::AddRecord(Models::Record(s));
            }

            if (Settings::printDurations)
                trace("loading records took " + (Time::Now - now) + " ms");
        }

        void Save() {
            auto now = Time::Now;
            trace("saving records to " + Storage::dbFile);

            Storage::db.Execute("CREATE TABLE IF NOT EXISTS Records" + tableColumns);

            for (uint i = 0; i < Storage::records.Length; i++) {
                auto record = Storage::records[i];
                SQLite::Statement@ s;
                @s = Storage::db.Prepare("""
                    INSERT INTO Records (
                        accountId,
                        accountName,
                        mapId,
                        mapName,
                        mapUid,
                        position,
                        recordFakeId,
                        time,
                        zoneId,
                        zoneName
                    ) VALUES (?,?,?,?,?,?,?,?,?,?);
                """);
                s.Bind(1,  record.accountId);
                s.Bind(2,  record.accountName);
                s.Bind(3,  record.mapId);
                s.Bind(4,  record.mapName);
                s.Bind(5,  record.mapUid);
                s.Bind(6,  record.position);
                s.Bind(7,  record.recordFakeId);
                s.Bind(8,  record.time);
                s.Bind(9,  record.zoneId);
                s.Bind(10, record.zoneName);
                s.Execute();
            }

            if (Settings::printDurations)
                trace("saving records took " + (Time::Now - now) + " ms");
        }
    }
}