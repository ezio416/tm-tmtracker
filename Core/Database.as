/*
c 2023-05-16
m 2023-06-13
*/

// Functions for the TMTracker.db file
namespace DB {
    // Functions relating to drivers of any map
    namespace AllAccounts {
        string tableColumns = """ (
            accountId   CHAR(36) PRIMARY KEY,
            accountName TEXT,
            nameExpire  INT,
            zoneId      CHAR(36)
        ); """;

        void Clear() {
            string timerId = Util::LogTimerBegin("clearing accounts from program and file");

            Globals::ClearAccounts();

            try { Globals::db.Execute("DELETE FROM Accounts"); } catch { }

            Util::LogTimerEnd(timerId);
        }

        void Load() {
            string timerId = Util::LogTimerBegin("loading accounts from file");

            Globals::ClearAccounts();

            SQLite::Statement@ s;
            @Globals::db = SQLite::Database(Globals::dbFile);

            try {
                @s = Globals::db.Prepare("SELECT * FROM Accounts ORDER BY accountName ASC");
            } catch {
                Util::Trace("no Accounts table in database, plugin (likely) hasn't been run yet");
                Util::LogTimerEnd(timerId);
                return;
            }
            while (true) {
                if (!s.NextRow()) break;
                Globals::AddAccount(Models::Account(s));
            }

            Util::LogTimerEnd(timerId);
        }

        void Save() {
            string timerId = Util::LogTimerBegin("saving accounts to file");

            Globals::db.Execute("CREATE TABLE IF NOT EXISTS Accounts" + tableColumns);

            for (uint i = 0; i < Globals::accounts.Length; i++) {
                auto account = Globals::accounts[i];
                SQLite::Statement@ s;
                try {
                    @s = Globals::db.Prepare(
                        "UPDATE Accounts SET accountName=? nameExpire=? zoneId=? WHERE accountId=?"
                    );
                    s.Bind(1, account.accountName);
                    s.Bind(2, account.nameExpire);
                    s.Bind(3, account.zoneId);
                    s.Bind(4, account.accountId);
                    s.Execute();
                } catch {
                    @s = Globals::db.Prepare("""
                        INSERT INTO Accounts (
                            accountId,
                            accountName,
                            nameExpire,
                            zoneId
                        ) VALUES (?,?,?,?);
                    """);
                    s.Bind(1, account.accountId);
                    s.Bind(2, account.accountName);
                    s.Bind(3, account.nameExpire);
                    s.Bind(4, account.zoneId);
                    s.Execute();
                }
            }

            Util::LogTimerEnd(timerId);
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
            string timerId = Util::LogTimerBegin("clearing my maps from program and file");

            Globals::ClearCurrentMaps();
            Globals::ClearMyHiddenMaps();
            Globals::ClearMyMaps();

            try { Globals::db.Execute("DELETE FROM MyMaps");       } catch { }
            try { Globals::db.Execute("DELETE FROM MyHiddenMaps"); } catch { }

            Util::LogTimerEnd(timerId);
        }

        void Load() {
            string timerId = Util::LogTimerBegin("loading my maps from file");

            Globals::ClearMyMaps();

            SQLite::Statement@ s;
            @Globals::db = SQLite::Database(Globals::dbFile);
            string order = (Settings::sortMapsNewest) ? "DESC" : "ASC";
            try {
                @s = Globals::db.Prepare("SELECT * FROM MyMaps ORDER BY timestamp " + order);
            } catch {
                Util::Trace("no MyMaps table in database, plugin hasn't been run yet");
                Util::LogTimerEnd(timerId);
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
                Util::Trace("no MyHiddenMaps table in database, no maps are hidden yet");
            }

            if (anyHidden)
                while (true) {
                    if (!s.NextRow()) break;
                    Globals::AddMyHiddenMap(Models::Map(s));
                }

            Util::LogTimerEnd(timerId);

            startnew(CoroutineFunc(Maps::LoadMyMapsThumbnailsCoro));
        }

        void Save() {
            string timerId = Util::LogTimerBegin("saving my maps to file");

            Globals::db.Execute("CREATE TABLE IF NOT EXISTS MyMaps" + tableColumns);

            for (uint i = 0; i < Globals::myMaps.Length; i++) {
                auto map = Globals::myMaps[i];
                SQLite::Statement@ s;
                try {
                    if (map.recordsTimestamp == 0) throw("");
                    @s = Globals::db.Prepare("UPDATE MyMaps SET recordsTimestamp=? WHERE mapId=?");
                    s.Bind(1, map.recordsTimestamp);
                    s.Bind(2, map.mapId);
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

            Util::LogTimerEnd(timerId);
        }

        void Hide(Models::Map@ map) {
            string timerId = Util::LogTimerBegin(map.logName + "hiding");

            map.hidden = true;

            Globals::db.Execute("CREATE TABLE IF NOT EXISTS MyHiddenMaps" + tableColumns);
            SQLite::Statement@ s;

            @s = Globals::db.Prepare("INSERT INTO MyHiddenMaps SELECT * FROM MyMaps WHERE mapId=?");
            s.Bind(1, map.mapId);
            s.Execute();

            @s = Globals::db.Prepare("DELETE FROM MyMaps WHERE mapId=?");
            s.Bind(1, map.mapId);
            s.Execute();

            Util::LogTimerEnd(timerId);

            Load();
        }

        void UnHide(Models::Map@ map) {
            string timerId = Util::LogTimerBegin(map.logName + "unhiding");

            map.hidden = false;

            SQLite::Statement@ s;

            @s = Globals::db.Prepare("INSERT INTO MyMaps SELECT * FROM MyHiddenMaps WHERE mapId=?");
            s.Bind(1, map.mapId);
            s.Execute();

            @s = Globals::db.Prepare("DELETE FROM MyHiddenMaps WHERE mapId=?");
            s.Bind(1, map.mapId);
            s.Execute();

            Util::LogTimerEnd(timerId);

            Load();
        }
    }

    // Functions relating to records driven on any map
    namespace Records {
        string tableColumns = """ (
            accountId    CHAR(36),
            mapId        CHAR(36),
            position     INT,
            recordFakeId CHAR(73) PRIMARY KEY,
            time         INT,
            zoneId       CHAR(36)
        ); """;

        void Clear() {
            string timerId = Util::LogTimerBegin("clearing records from program and file");

            Globals::ClearRecords();

            try { Globals::db.Execute("DELETE FROM Records"); } catch { }

            Util::LogTimerEnd(timerId);
        }

        void Load() {
            string timerId = Util::LogTimerBegin("loading records from file");

            Globals::ClearRecords();

            SQLite::Statement@ s;
            @Globals::db = SQLite::Database(Globals::dbFile);

            try {
                @s = Globals::db.Prepare("SELECT * FROM Records");
            } catch {
                Util::Trace("no Records table in database, no records gotten yet");
                Util::LogTimerEnd(timerId);
                return;
            }
            while (true) {
                if (!s.NextRow()) break;
                Globals::AddRecord(Models::Record(s));
            }

            Util::LogTimerEnd(timerId);
        }

        void Save() {
            string timerId = Util::LogTimerBegin("saving records to file");

            Globals::db.Execute("CREATE TABLE IF NOT EXISTS Records" + tableColumns);

            for (uint i = 0; i < Globals::records.Length; i++) {
                auto record = Globals::records[i];
                SQLite::Statement@ s;
                @s = Globals::db.Prepare("""
                    INSERT INTO Records (
                        accountId,
                        mapId,
                        position,
                        recordFakeId,
                        time,
                        zoneId
                    ) VALUES (?,?,?,?,?,?);
                """);
                s.Bind(1, record.accountId);
                s.Bind(2, record.mapId);
                s.Bind(3, record.position);
                s.Bind(4, record.recordFakeId);
                s.Bind(5, record.time);
                s.Bind(6, record.zoneId);
                s.Execute();
            }

            Util::LogTimerEnd(timerId);
        }
    }
}