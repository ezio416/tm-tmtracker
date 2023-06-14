/*
c 2023-05-16
m 2023-06-14
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

        void LoadCoro() {
            string timerId = Util::LogTimerBegin("loading accounts from file");

            Globals::ClearAccounts();

            SQLite::Statement@ s;
            @Globals::db = SQLite::Database(Globals::dbFile);

            try {
                @s = Globals::db.Prepare("SELECT * FROM Accounts ORDER BY accountName ASC");
            } catch {
                Util::Warn("no Accounts table in database");
                Util::LogTimerEnd(timerId, false);
                return;
            }
            uint i = 0;
            while (s.NextRow()) {
                i++;
                Globals::AddAccount(Models::Account(s));
                if (i % Globals::sqlLoadBatch == 0) yield();
            }

            Util::LogTimerEnd(timerId);
        }

        void SaveCoro() {
            string timerId = Util::LogTimerBegin("saving accounts to file");

            Globals::db.Execute("CREATE TABLE IF NOT EXISTS Accounts" + tableColumns);

            Models::Account[] newAccounts;

            for (uint i = 0; i < Globals::accounts.Length; i++) {
                auto account = Globals::accounts[i];
                SQLite::Statement@ s;
                @s = Globals::db.Prepare("SELECT * FROM Accounts WHERE accountId=?");
                s.Bind(1, account.accountId);
                if (s.NextRow()) {
                    @s = Globals::db.Prepare("UPDATE Accounts SET accountName=?, nameExpire=?, zoneId=? WHERE accountId=?");
                    s.Bind(1, account.accountName);
                    s.Bind(2, account.nameExpire);
                    s.Bind(3, account.zoneId);
                    s.Bind(4, account.accountId);
                    s.Execute();
                } else {
                    newAccounts.InsertLast(account);
                }
            }

            string[] accountGroups = AccountGroups(newAccounts);
            for (uint i = 0; i < accountGroups.Length; i++) {
                SQLite::Statement@ s;
                @s = Globals::db.Prepare("""
                    INSERT INTO Accounts (
                        accountId,
                        accountName,
                        nameExpire,
                        zoneId
                    ) VALUES """ + accountGroups[i] + ";");
                s.Execute();
                yield();
            }

            Util::LogTimerEnd(timerId);
        }

        string[] AccountGroups(Models::Account[]@ newAccounts) {
            string[] ret;

            while (newAccounts.Length > 0) {
                uint accountsToAdd = Math::Min(newAccounts.Length, Globals::maxSqlValues);
                string accountValue = "";

                for (uint i = 0; i < accountsToAdd; i++) {
                    auto account = newAccounts[i];
                    accountValue += "(" +
                        Util::StrWrap(account.accountId) + "," +
                        Util::StrWrap(account.accountName) + "," +
                        account.nameExpire + "," +
                        Util::StrWrap(account.zoneId) + ")";

                    if (i < accountsToAdd - 1)
                        accountValue += ",";
                }
                newAccounts.RemoveRange(0, accountsToAdd);
                ret.InsertLast(accountValue);
            }
            return ret;
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
            mapNameRaw       TEXT,
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

            try { Globals::db.Execute("DELETE FROM MyHiddenMaps"); } catch { }
            try { Globals::db.Execute("DELETE FROM MyMaps");       } catch { }

            Util::LogTimerEnd(timerId);
        }

        void LoadCoro() {
            string timerId = Util::LogTimerBegin("loading my maps from file");

            Globals::ClearMyMaps();

            SQLite::Statement@ s;
            @Globals::db = SQLite::Database(Globals::dbFile);
            string order = (Settings::sortMapsNewest) ? "DESC" : "ASC";
            try {
                @s = Globals::db.Prepare("SELECT * FROM MyMaps ORDER BY timestamp " + order);
            } catch {
                Util::Warn("no MyMaps table in database");
                Util::LogTimerEnd(timerId);
                return;
            }
            uint i = 0;
            while (s.NextRow()) {
                i++;
                Globals::AddMyMap(Models::Map(s));
                if (i % Globals::sqlLoadBatch == 0) yield();
            }

            Globals::ClearMyHiddenMaps();
            bool anyHidden = false;
            try {
                @s = Globals::db.Prepare("SELECT * FROM MyHiddenMaps");
                anyHidden = true;
            } catch {
                Util::Warn("no MyHiddenMaps table in database");
            }

            i = 0;
            if (anyHidden)
                while (s.NextRow()) {
                    i++;
                    Globals::AddMyHiddenMap(Models::Map(s));
                    if (i % Globals::sqlLoadBatch == 0) yield();
                }

            Util::LogTimerEnd(timerId);

            startnew(CoroutineFunc(Maps::LoadMyMapsThumbnailsCoro));
        }

        void SaveCoro() {
            string timerId = Util::LogTimerBegin("saving my maps to file");

            Globals::db.Execute("CREATE TABLE IF NOT EXISTS MyMaps" + tableColumns);

            Models::Map[] newMaps;

            for (uint i = 0; i < Globals::myMaps.Length; i++) {
                auto map = Globals::myMaps[i];
                SQLite::Statement@ s;
                @s = Globals::db.Prepare("SELECT * FROM MyMaps WHERE mapId=?");
                s.Bind(1, map.mapId);
                if (s.NextRow() && map.recordsTimestamp != 0) {
                    @s = Globals::db.Prepare("UPDATE MyMaps SET recordsTimestamp=? WHERE mapId=?");
                    s.Bind(1, map.recordsTimestamp);
                    s.Bind(2, map.mapId);
                    s.Execute();
                } else {
                    newMaps.InsertLast(map);
                }
            }

            string[] mapGroups = MapGroups(newMaps);
            for (uint i = 0; i < mapGroups.Length; i++) {
                SQLite::Statement@ s;
                @s = Globals::db.Prepare("""
                    INSERT INTO MyMaps (
                        authorId,
                        authorTime,
                        badUploadTime,
                        bronzeTime,
                        downloadUrl,
                        goldTime,
                        mapId,
                        mapNameRaw,
                        mapUid,
                        recordsTimestamp,
                        silverTime,
                        thumbnailUrl,
                        timestamp
                    ) VALUES """ + mapGroups[i] + ";");
                s.Execute();
                yield();
            }

            Util::LogTimerEnd(timerId);
        }

        string[] MapGroups(Models::Map[]@ newMaps) {
            string[] ret;

            while (newMaps.Length > 0) {
                uint mapsToAdd = Math::Min(newMaps.Length, Globals::maxSqlValues);
                string mapValue = "";

                for (uint i = 0; i < mapsToAdd; i++) {
                    auto map = newMaps[i];
                    mapValue += "(" +
                        Util::StrWrap(map.authorId) + "," +
                        map.authorTime + "," +
                        map.badUploadTime + "," +
                        map.bronzeTime + "," +
                        Util::StrWrap(map.downloadUrl) + "," +
                        map.goldTime + "," +
                        Util::StrWrap(map.mapId) + "," +
                        Util::StrWrap(map.mapNameRaw.Replace("'", "''")) + "," +
                        Util::StrWrap(map.mapUid) + "," +
                        map.recordsTimestamp + "," +
                        map.silverTime + "," +
                        Util::StrWrap(map.thumbnailUrl) + "," +
                        map.timestamp + ")";

                    if (i < mapsToAdd - 1)
                        mapValue += ",";
                }
                newMaps.RemoveRange(0, mapsToAdd);
                ret.InsertLast(mapValue);
            }
            return ret;
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

            startnew(CoroutineFunc(LoadCoro));
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

            startnew(CoroutineFunc(LoadCoro));
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

        void LoadCoro() {
            string timerId = Util::LogTimerBegin("loading records from file");

            Globals::ClearRecords();

            SQLite::Statement@ s;
            @Globals::db = SQLite::Database(Globals::dbFile);

            try {
                @s = Globals::db.Prepare("SELECT * FROM Records");
            } catch {
                Util::Warn("no Records table in database");
                Util::LogTimerEnd(timerId, false);
                return;
            }
            uint i = 0;
            while (s.NextRow()) {
                i++;
                Globals::AddRecord(Models::Record(s));
                if (i % Globals::sqlLoadBatch == 0) yield();
            }

            Util::LogTimerEnd(timerId);
        }

        void SaveCoro() {
            string timerId = Util::LogTimerBegin("saving records to file");

            Globals::db.Execute("CREATE TABLE IF NOT EXISTS Records" + tableColumns);

            Models::Record[] newRecords;

            for (uint i = 0; i < Globals::records.Length; i++) {
                auto record = Globals::records[i];
                SQLite::Statement@ s;
                @s = Globals::db.Prepare("SELECT * FROM Records WHERE recordFakeId=?");
                s.Bind(1, record.recordFakeId);
                if (s.NextRow()) {
                    @s = Globals::db.Prepare("UPDATE Records SET position=?, time=? WHERE recordFakeId=?");
                    s.Bind(1, record.position);
                    s.Bind(2, record.time);
                    s.Bind(3, record.recordFakeId);
                    s.Execute();
                } else {
                    newRecords.InsertLast(record);
                }
            }

            string[] recordGroups = RecordGroups(newRecords);
            for (uint i = 0; i < recordGroups.Length; i++) {
                SQLite::Statement@ s;
                @s = Globals::db.Prepare("""
                    INSERT INTO Records (
                        accountId,
                        mapId,
                        position,
                        recordFakeId,
                        time,
                        zoneId
                    ) VALUES """ + recordGroups[i] + ";");
                s.Execute();
                yield();
            }

            Util::LogTimerEnd(timerId);
        }

        string[] RecordGroups(Models::Record[]@ newRecords) {
            string[] ret;

            while (newRecords.Length > 0) {
                uint recordsToAdd = Math::Min(newRecords.Length, Globals::maxSqlValues);
                string recordValue = "";

                for (uint i = 0; i < recordsToAdd; i++) {
                    auto record = newRecords[i];
                    recordValue += "('" +
                        record.accountId + "','" +
                        record.mapId + "'," +
                        record.position + ",'" +
                        record.recordFakeId + "'," +
                        record.time + ",'" +
                        record.zoneId + "')";

                    if (i < recordsToAdd - 1)
                        recordValue += ",";
                }
                newRecords.RemoveRange(0, recordsToAdd);
                ret.InsertLast(recordValue);
            }
            return ret;
        }
    }
}