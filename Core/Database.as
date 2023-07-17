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
        recordId      CHAR(36) PRIMARY KEY,
        time          INT,
        timestampUnix INT,
        zoneId        CHAR(36)
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
        @db = SQLite::Database(dbFile);
        Util::LogTimerEnd(timerId);
    }

    void SaveCoro() {
        string timerId = Util::LogTimerBegin("saving database");

        @db = SQLite::Database(dbFile);

        db.Execute("CREATE TABLE IF NOT EXISTS Accounts" + accountColumns);
        string[] accountGroups = AccountGroups(Globals::accounts);
        for (uint i = 0; i < accountGroups.Length; i++) {
            SQLite::Statement@ s;
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

        // db.Execute("CREATE TABLE IF NOT EXISTS Maps" + mapColumns);
        // db.Execute("CREATE TABLE IF NOT EXISTS Records" + recordColumns);

        Util::LogTimerEnd(timerId);
    }

    string[] AccountGroups(Models::Account[]@ accounts) {
        string[] ret;

        while (accounts.Length > 0) {
            uint accountsToAdd = Math::Min(accounts.Length, maxSqlValues);
            string accountValue = "";

            for (uint i = 0; i < accountsToAdd; i++) {
                auto account = accounts[i];
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

    // string[] MapGroups(Models::Map@[]@ newMaps) {
    //     string[] ret;

    //     while (newMaps.Length > 0) {
    //         uint mapsToAdd = Math::Min(newMaps.Length, maxSqlValues);
    //         string mapValue = "";

    //         for (uint i = 0; i < mapsToAdd; i++) {
    //             auto map = newMaps[i];
    //             mapValue += "(" +
    //                 Util::StrWrap(map.authorId) + "," +
    //                 map.authorTime + "," +
    //                 map.bronzeTime + "," +
    //                 Util::StrWrap(map.downloadUrl) + "," +
    //                 map.goldTime + "," +
    //                 Util::StrWrap(map.mapId) + "," +
    //                 Util::StrWrap(map.mapNameRaw.Replace("'", "''")) + "," +
    //                 Util::StrWrap(map.mapUid) + "," +
    //                 map.recordsTimestamp + "," +
    //                 map.silverTime + "," +
    //                 Util::StrWrap(map.thumbnailUrl) + ")";

    //             if (i < mapsToAdd - 1)
    //                 mapValue += ",";
    //         }

    //         newMaps.RemoveRange(0, mapsToAdd);
    //         ret.InsertLast(mapValue);
    //     }

    //     return ret;
    // }

    // string[] RecordGroups(Models::Record@[]@ newRecords) {
    //     string[] ret;

    //     while (newRecords.Length > 0) {
    //         uint recordsToAdd = Math::Min(newRecords.Length, maxSqlValues);
    //         string recordValue = "";

    //         for (uint i = 0; i < recordsToAdd; i++) {
    //             auto record = newRecords[i];
    //             recordValue += "('" +
    //                 record.accountId + "','" +
    //                 record.mapId + "'," +
    //                 record.position + ",'" +
    //                 record.recordFakeId + "'," +
    //                 record.time + ",'" +
    //                 record.zoneId + "')";

    //             if (i < recordsToAdd - 1)
    //                 recordValue += ",";
    //         }

    //         newRecords.RemoveRange(0, recordsToAdd);
    //         ret.InsertLast(recordValue);
    //     }

    //     return ret;
    // }
}