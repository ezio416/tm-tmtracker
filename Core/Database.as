/*
c 2023-05-16
m 2023-05-26
*/

// Functions for the TMTracker.db file
namespace DB {
    // Functions relating to drivers of any map
    namespace AllAccounts {
        string tableColumns = """ (
            accountId   CHAR(36) PRIMARY KEY,
            accountName TEXT,
            nameExpire  INT,
            zoneId      CHAR(36),
            zoneName    TEXT
        ); """;

        void Clear() {
            string timerId = Various::LogTimerBegin("clearing accounts from program and file");

            Globals::ClearAccounts();

            try { Globals::db.Execute("DELETE FROM Accounts"); } catch { }

            Various::LogTimerEnd(timerId);
        }

        void Load() {
            string timerId = Various::LogTimerBegin("loading accounts from file");

            Globals::ClearAccounts();

            SQLite::Statement@ s;
            @Globals::db = SQLite::Database(Globals::dbFile);

            try {
                @s = Globals::db.Prepare("SELECT * FROM Accounts ORDER BY accountName ASC");
            } catch {
                Various::Trace("no Accounts table in database, plugin (likely) hasn't been run yet");
                Various::LogTimerEnd(timerId);
                return;
            }
            while (true) {
                if (!s.NextRow()) break;
                Globals::AddAccount(Models::Account(s));
            }

            Various::LogTimerEnd(timerId);
        }

        void Save() {
            string timerId = Various::LogTimerBegin("saving accounts to file");

            Globals::db.Execute("CREATE TABLE IF NOT EXISTS Accounts" + tableColumns);

            for (uint i = 0; i < Globals::accounts.Length; i++) {
                auto account = Globals::accounts[i];
                SQLite::Statement@ s;
                try {
                    @s = Globals::db.Prepare(
                        "UPDATE Accounts SET accountName=? nameExpire=? zoneId=? zoneName=? WHERE accountId=?"
                    );
                    s.Bind(1, account.accountName);
                    s.Bind(2, account.nameExpire);
                    s.Bind(3, account.zoneId);
                    s.Bind(4, account.zoneName);
                    s.Bind(5, account.accountId);
                    s.Execute();
                } catch {
                    @s = Globals::db.Prepare("""
                        INSERT INTO Accounts (
                            accountId,
                            accountName,
                            nameExpire,
                            zoneId,
                            zoneName
                        ) VALUES (?,?,?,?,?);
                    """);
                    s.Bind(1, account.accountId);
                    s.Bind(2, account.accountName);
                    s.Bind(3, account.nameExpire);
                    s.Bind(4, account.zoneId);
                    s.Bind(5, account.zoneName);
                    s.Execute();
                }
            }

            Various::LogTimerEnd(timerId);
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
            mapId            CHAR(36) PRIMARY KEY,
            mapNameColor     TEXT,
            mapNameRaw       TEXT,
            mapNameText      TEXT,
            mapUid           VARCHAR(27),
            recordsTimestamp INT,
            silverTime       INT,
            thumbnailUrl     CHAR(97),
            timestamp        INT
        ); """;

        void Clear() {
            string timerId = Various::LogTimerBegin("clearing my maps from program and file");

            Globals::ClearCurrentMaps();
            Globals::ClearMyHiddenMaps();
            Globals::ClearMyMaps();

            try { Globals::db.Execute("DELETE FROM MyMaps");       } catch { }
            try { Globals::db.Execute("DELETE FROM MyHiddenMaps"); } catch { }

            Various::LogTimerEnd(timerId);
        }

        void Load() {
            string timerId = Various::LogTimerBegin("loading my maps from file");

            Globals::ClearMyMaps();

            SQLite::Statement@ s;
            @Globals::db = SQLite::Database(Globals::dbFile);
            string order = (Settings::sortMapsNewest) ? "DESC" : "ASC";
            try {
                @s = Globals::db.Prepare("SELECT * FROM MyMaps ORDER BY timestamp " + order);
            } catch {
                Various::Trace("no MyMaps table in database, plugin hasn't been run yet");
                Various::LogTimerEnd(timerId);
                return;
            }
            while (true) {
                if (!s.NextRow()) break;
                Globals::AddMyMap(Models::Map(s));
            }

            Globals::ClearMyHiddenMaps();
            bool anyHidden = false;
            try {
                @s = Globals::db.Prepare("SELECT * FROM MyHiddenMaps");
                anyHidden = true;
            } catch {
                Various::Trace("no MyHiddenMaps table in database, no maps are hidden yet");
            }

            if (anyHidden)
                while (true) {
                    if (!s.NextRow()) break;
                    Globals::AddMyHiddenMap(Models::Map(s));
                }

            Various::LogTimerEnd(timerId);

            startnew(CoroutineFunc(Maps::LoadMyMapsThumbnailsCoro));
        }

        void Save() {
            string timerId = Various::LogTimerBegin("saving my maps to file");

            Globals::db.Execute("CREATE TABLE IF NOT EXISTS MyMaps" + tableColumns);

            for (uint i = 0; i < Globals::myMaps.Length; i++) {
                auto map = Globals::myMaps[i];
                SQLite::Statement@ s;
                try {
                    if (map.recordsTimestamp == 0) throw("");
                    @s = Globals::db.Prepare("UPDATE MyMaps SET recordsTimestamp=? WHERE mapUid=?");
                    s.Bind(1, map.recordsTimestamp);
                    s.Bind(2, map.mapUid);
                    s.Execute();
                } catch {
                    @s = Globals::db.Prepare("""
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

            Various::LogTimerEnd(timerId);
        }

        void Hide(Models::Map@ map) {
            string timerId = Various::LogTimerBegin(map.logName + "hiding");

            map.hidden = true;

            Globals::db.Execute("CREATE TABLE IF NOT EXISTS MyHiddenMaps" + tableColumns);
            SQLite::Statement@ s;

            @s = Globals::db.Prepare("INSERT INTO MyHiddenMaps SELECT * FROM MyMaps WHERE mapUid=?");
            s.Bind(1, map.mapUid);
            s.Execute();

            @s = Globals::db.Prepare("DELETE FROM MyMaps WHERE mapUid=?");
            s.Bind(1, map.mapUid);
            s.Execute();

            Various::LogTimerEnd(timerId);

            Load();
        }

        void UnHide(Models::Map@ map) {
            string timerId = Various::LogTimerBegin(map.logName + "unhiding");

            map.hidden = false;

            SQLite::Statement@ s;

            @s = Globals::db.Prepare("INSERT INTO MyMaps SELECT * FROM MyHiddenMaps WHERE mapUid=?");
            s.Bind(1, map.mapUid);
            s.Execute();

            @s = Globals::db.Prepare("DELETE FROM MyHiddenMaps WHERE mapUid=?");
            s.Bind(1, map.mapUid);
            s.Execute();

            Various::LogTimerEnd(timerId);

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
            string timerId = Various::LogTimerBegin("clearing records from program and file");

            Globals::ClearRecords();

            try { Globals::db.Execute("DELETE FROM Records"); } catch { }

            Various::LogTimerEnd(timerId);
        }

        void Load() {
            string timerId = Various::LogTimerBegin("loading records from file");

            Globals::ClearRecords();

            SQLite::Statement@ s;
            @Globals::db = SQLite::Database(Globals::dbFile);

            try {
                @s = Globals::db.Prepare("SELECT * FROM Records");
            } catch {
                Various::Trace("no Records table in database, no records gotten yet");
                Various::LogTimerEnd(timerId);
                return;
            }
            while (true) {
                if (!s.NextRow()) break;
                Globals::AddRecord(Models::Record(s));
            }

            Various::LogTimerEnd(timerId);
        }

        void Save() {
            string timerId = Various::LogTimerBegin("saving records to file");

            Globals::db.Execute("CREATE TABLE IF NOT EXISTS Records" + tableColumns);

            for (uint i = 0; i < Globals::records.Length; i++) {
                auto record = Globals::records[i];
                SQLite::Statement@ s;
                @s = Globals::db.Prepare("""
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

            Various::LogTimerEnd(timerId);
        }
    }
}