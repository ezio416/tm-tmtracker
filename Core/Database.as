/*
c 2023-07-14
m 2023-07-16
*/

namespace Database {
    SQLite::Database@ db;
    string            dbFile = Globals::storageFolder + "TMTracker.db";
    uint              maxSqlValues = 1000;
    uint              sqlLoadBatch = 100;

    string accountColumns = """ (
        accountId   CHAR(36) PRIMARY KEY,
        accountName TEXT,
        nameExpire  INT,
        zoneId      CHAR(36)
    ); """;

    string mapColumns = """ (
        authorId         CHAR(36),
        authorTime       INT,
        bronzeTime       INT,
        downloadUrl      CHAR(93),
        goldTime         INT,
        hidden           BOOL,
        mapId            CHAR(36) PRIMARY KEY,
        mapNameRaw       TEXT,
        mapUid           VARCHAR(27),
        recordsTimestamp INT,
        silverTime       INT,
        thumbnailUrl     CHAR(97)
    ); """;

    string recordColumns = """ (
        accountId     CHAR(36),
        mapId         CHAR(36),
        position      INT,
        recordFakeId  CHAR(73) PRIMARY KEY,
        recordId      CHAR(36),
        time          INT,
        timestampUnix INT
    ); """;

    void Clear() {
        string timerId = Util::LogTimerBegin("clearing database");
        @db = SQLite::Database(dbFile);
        try { db.Execute("DELETE FROM Accounts"); } catch { }
        try { db.Execute("DELETE FROM Maps");     } catch { }
        try { db.Execute("DELETE FROM Records");  } catch { }
        Util::LogTimerEnd(timerId);
    }

    void Load() {
        string timerId = Util::LogTimerBegin("loading database");
        Globals::status.Set("db-load", "loading database...");

        @db = SQLite::Database(dbFile);

        Globals::status.Delete("db-load");
        Util::LogTimerEnd(timerId);
    }

    void SaveCoro() {
        while (Locks::dbSave) yield();
        Locks::dbSave = true;

        string timerId = Util::LogTimerBegin("saving database");
        Globals::status.Set("db-save", "saving database...");

        @db = SQLite::Database(dbFile);
        SQLite::Statement@ s;

        db.Execute("CREATE TABLE IF NOT EXISTS Accounts" + accountColumns);
        string[] accountGroups = AccountGroups(Globals::accounts);
        for (uint i = 0; i < accountGroups.Length; i++) {
            @s = db.Prepare("""
                REPLACE INTO Accounts (
                    accountId,
                    accountName,
                    nameExpire,
                    zoneId
                ) VALUES """ + accountGroups[i]);
            s.Execute();
            yield();
        }

        db.Execute("CREATE TABLE IF NOT EXISTS Maps" + mapColumns);
        string[] mapGroups = MapGroups(Globals::maps);
        for (uint i = 0; i < mapGroups.Length; i++) {
            @s = db.Prepare("""
                REPLACE INTO Maps (
                    authorId,
                    authorTime,
                    bronzeTime,
                    downloadUrl,
                    goldTime,
                    hidden,
                    mapId,
                    mapNameRaw,
                    mapUid,
                    recordsTimestamp,
                    silverTime,
                    thumbnailUrl
                ) VALUES """ + mapGroups[i]);
            s.Execute();
            yield();
        }

        db.Execute("CREATE TABLE IF NOT EXISTS Records" + recordColumns);
        string[] recordGroups = RecordGroups(Globals::records);
        for (uint i = 0; i < recordGroups.Length; i++) {
            @s = db.Prepare("""
                REPLACE INTO Records (
                    accountId,
                    mapId,
                    position,
                    recordFakeId,
                    recordId,
                    time,
                    timestampUnix
                ) VALUES """ + recordGroups[i]);
            s.Execute();
            yield();
        }

        Globals::status.Delete("db-save");
        Util::LogTimerEnd(timerId);
        Locks::dbSave = false;
    }

    string[] AccountGroups(Models::Account[] accounts) {
        string[] ret;

        while (accounts.Length > 0) {
            uint accountsToAdd = Math::Min(accounts.Length, maxSqlValues);
            string accountValue = "";

            for (uint i = 0; i < accountsToAdd; i++) {
                auto account = @accounts[i];
                accountValue += "(" +
                    Util::StrWrap(account.accountId) + "," +
                    Util::StrWrap(account.accountName) + "," +
                    account.nameExpire + "," +
                    Util::StrWrap(account.zoneId) + ")";

                if (i < accountsToAdd - 1)
                    accountValue += ",";
            }

            accounts.RemoveRange(0, accountsToAdd);
            ret.InsertLast(accountValue);
        }

        return ret;
    }

    string[] MapGroups(Models::Map[] maps) {
        string[] ret;

        while (maps.Length > 0) {
            uint mapsToAdd = Math::Min(maps.Length, maxSqlValues);
            string mapValue = "";

            for (uint i = 0; i < mapsToAdd; i++) {
                auto map = @maps[i];
                mapValue += "(" +
                    Util::StrWrap(map.authorId) + "," +
                    map.authorTime + "," +
                    map.bronzeTime + "," +
                    Util::StrWrap(map.downloadUrl) + "," +
                    map.goldTime + "," +
                    (map.hidden ? 1 : 0) + "," +
                    Util::StrWrap(map.mapId) + "," +
                    Util::StrWrap(map.mapNameRaw.Replace("'", "''")) + "," +
                    Util::StrWrap(map.mapUid) + "," +
                    map.recordsTimestamp + "," +
                    map.silverTime + "," +
                    Util::StrWrap(map.thumbnailUrl) + ")";

                if (i < mapsToAdd - 1)
                    mapValue += ",";
            }

            maps.RemoveRange(0, mapsToAdd);
            ret.InsertLast(mapValue);
        }

        return ret;
    }

    string[] RecordGroups(Models::Record[] records) {
        string[] ret;

        while (records.Length > 0) {
            uint recordsToAdd = Math::Min(records.Length, maxSqlValues);
            string recordValue = "";

            for (uint i = 0; i < recordsToAdd; i++) {
                auto record = @records[i];
                recordValue += "(" +
                    Util::StrWrap(record.accountId) + "," +
                    Util::StrWrap(record.mapId) + "," +
                    record.position + "," +
                    Util::StrWrap(record.recordFakeId) + "," +
                    Util::StrWrap(record.recordId) + "," +
                    record.time + "," +
                    record.timestampUnix + ")";

                if (i < recordsToAdd - 1)
                    recordValue += ",";
            }

            records.RemoveRange(0, recordsToAdd);
            ret.InsertLast(recordValue);
        }

        return ret;
    }
}