// c 2023-07-14
// m 2023-12-25

namespace Database {
    uint sqlLoadBatch = 100;
    uint sqlMaxValues = 1000;

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
        thumbnailUrl     CHAR(97),
        updateTimestamp  INT,
        uploadTimestamp  INT
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

    void ClearCoro() {
        while (Locks::db)
            yield();
        Locks::db = true;
        string timerId = Log::TimerBegin("clearing database");

        SQLite::Database@ db = SQLite::Database(Files::db);
        try {
            db.Execute("DELETE FROM Accounts");
        } catch {
            Log::Write(Log::Level::Debug, "no Accounts table in database");
        }

        try {
            db.Execute("DELETE FROM Maps");
        } catch {
            Log::Write(Log::Level::Debug, "no Maps table in database");
        }

        try {
            db.Execute("DELETE FROM Records");
        } catch {
            Log::Write(Log::Level::Debug, "no Records table in database");
        }

        Log::TimerEnd(timerId);
        Locks::db = false;
    }

    void ClearMapRecords(Models::Map@ map) {
        while (Locks::db)
            yield();
        Locks::db = true;
        string timerId = Log::TimerBegin(map.logName + "clearing database records...");

        SQLite::Database@ db = SQLite::Database(Files::db);
        try {
            db.Execute("DELETE FROM Records WHERE mapId = " + Util::StrWrap(map.mapId));
        } catch {
            Log::Write(Log::Level::Warnings, map.logName + "couldn't clear records: " + getExceptionInfo());
        }

        Log::TimerEnd(timerId);
        Locks::db = false;
    }

    void LoadCoro() {
        while (Locks::myMaps)
            yield();
        Locks::myMaps = true;
        string timerId = Log::TimerBegin("loading database");
        string statusId = "db-load";
        Globals::status.Set(statusId, "loading database...");

        Meta::PluginCoroutine@ mapsCoro = startnew(CoroutineFunc(LoadMapsCoro));
        while (mapsCoro.IsRunning())
            yield();

        Meta::PluginCoroutine@ accountsCoro = startnew(CoroutineFunc(LoadAccountsCoro));
        while (accountsCoro.IsRunning())
            yield();

        Meta::PluginCoroutine@ recordsCoro = startnew(CoroutineFunc(LoadRecordsCoro));
        while (recordsCoro.IsRunning())
            yield();

        Globals::status.Delete(statusId);
        Log::TimerEnd(timerId);
        Locks::myMaps = false;
    }

    void LoadMapsCoro() {
        while (Locks::db)
            yield();
        Locks::db = true;
        string timerId = Log::TimerBegin("loading maps from database");

        SQLite::Database@ db = SQLite::Database(Files::db);
        SQLite::Statement@ s;

        Globals::ClearMyMaps();

        try {
            @s = db.Prepare("SELECT * FROM Maps");
        } catch {
            Log::Write(Log::Level::Warnings, "no Maps table in database");
            Log::TimerDelete(timerId);
            Locks::db = false;
            return;
        }

        uint i = 0;
        while (s.NextRow()) {
            Globals::AddMyMap(Models::Map(s));

            i++;
            if (i % sqlLoadBatch == 0)
                yield();
        }

        Globals::myMaps.Reverse();

        Log::TimerEnd(timerId);
        Locks::db = false;
    }

    void LoadAccountsCoro() {
        while (Locks::db)
            yield();
        Locks::db = true;
        string timerId = Log::TimerBegin("loading accounts from database");

        SQLite::Database@ db = SQLite::Database(Files::db);
        SQLite::Statement@ s;

        Globals::ClearAccounts();

        try {
            @s = db.Prepare("SELECT * FROM Accounts");
        } catch {
            Log::Write(Log::Level::Warnings, "no Accounts table in database");
            Log::TimerDelete(timerId);
            Locks::db = false;
            return;
        }

        uint i = 0;
        while (s.NextRow()) {
            Globals::AddAccount(Models::Account(s));

            i++;
            if (i % sqlLoadBatch == 0)
                yield();
        }

        Log::TimerEnd(timerId);
        Locks::db = false;
    }

    void LoadRecordsCoro() {
        while (Locks::db)
            yield();
        Locks::db = true;
        string timerId = Log::TimerBegin("loading records from database");

        SQLite::Database@ db = SQLite::Database(Files::db);
        SQLite::Statement@ s;

        Globals::ClearMyMapsRecords();

        try {
            @s = db.Prepare("SELECT * FROM Records");
        } catch {
            Log::Write(Log::Level::Warnings, "no Records table in database");
            Log::TimerDelete(timerId);
            Locks::db = false;
            return;
        }

        uint i = 0;
        while (s.NextRow()) {
            try {
                Globals::AddMyMapsRecord(Models::Record(s));
            } catch {
                Log::Write(Log::Level::Errors, "couldn't add record: " + getExceptionInfo());
            }

            i++;
            if (i % sqlLoadBatch == 0)
                yield();
        }

        Log::TimerEnd(timerId);
        Locks::db = false;

        startnew(Sort::MyMapsRecordsCoro);
    }

    void SaveCoro() {
        while (Locks::db)
            yield();
        Locks::db = true;
        string timerId = Log::TimerBegin("saving database");
        string statusId = "db-save";
        Globals::status.Set(statusId, "saving database...");

        SQLite::Database@ db = SQLite::Database(Files::db);
        SQLite::Statement@ s;

        Log::Write(Log::Level::Debug, "saving accounts to database...");
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
        Log::Write(Log::Level::Debug, "saved accounts to database");

        Log::Write(Log::Level::Debug, "saving maps to database...");
        db.Execute("CREATE TABLE IF NOT EXISTS Maps" + mapColumns);
        string[] mapGroups = MapGroups(Globals::myMaps);
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
                    thumbnailUrl,
                    updateTimestamp,
                    uploadTimestamp
                ) VALUES """ + mapGroups[i]);
            s.Execute();
            yield();
        }
        Log::Write(Log::Level::Debug, "saved maps to database");

        Log::Write(Log::Level::Debug, "saving records to database...");
        db.Execute("CREATE TABLE IF NOT EXISTS Records" + recordColumns);
        string[] recordGroups = RecordGroups(Globals::myMapsRecords);
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
        Log::Write(Log::Level::Debug, "saved records to database");

        Globals::status.Delete(statusId);
        Log::TimerEnd(timerId);
        Locks::db = false;
    }

    string[] AccountGroups(Models::Account[] accounts) {
        string[] ret;

        while (accounts.Length > 0) {
            uint accountsToAdd = Math::Min(accounts.Length, sqlMaxValues);
            string accountValue = "";

            for (uint i = 0; i < accountsToAdd; i++) {
                Models::Account@ account = @accounts[i];

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

        maps.Reverse();

        while (maps.Length > 0) {
            uint mapsToAdd = Math::Min(maps.Length, sqlMaxValues);
            string mapValue = "";

            for (uint i = 0; i < mapsToAdd; i++) {
                Models::Map@ map = @maps[i];

                mapValue += "(" +
                    Util::StrWrap(map.authorId) + "," +
                    map.authorTime + "," +
                    map.bronzeTime + "," +
                    Util::StrWrap(map.downloadUrl) + "," +
                    map.goldTime + "," +
                    (map.hidden ? 1 : 0) + "," +
                    Util::StrWrap(map.mapId);
                mapValue += "," +
                    Util::StrWrap(map.mapNameRaw.Replace("'", "''")) + "," +
                    Util::StrWrap(map.mapUid) + "," +
                    map.recordsTimestamp + "," +
                    map.silverTime + "," +
                    Util::StrWrap(map.thumbnailUrl) + "," +
                    map.updateTimestamp + "," +
                    map.uploadTimestamp + ")";

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
            uint recordsToAdd = Math::Min(records.Length, sqlMaxValues);
            string recordValue = "";

            for (uint i = 0; i < recordsToAdd; i++) {
                Models::Record@ record = @records[i];

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