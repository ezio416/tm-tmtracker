/*
c 2023-05-16
m 2023-10-13
*/

namespace Models { class Map {
    string       authorId;
    uint         authorTime;
    uint         bronzeTime;
    string       downloadUrl;
    uint         goldTime;
    bool         hidden;
    string       logName;
    string       mapId;
    string       mapNameColor;
    string       mapNameRaw;
    string       mapNameText;
    string       mapUid;
    Record@[]    records;
    dictionary   recordsDict;
    uint         recordsTimestamp;
    uint         silverTime;
    string       thumbnailFile;
    bool         thumbnailLoading;
    UI::Texture@ thumbnailTexture;
    string       thumbnailUrl;
    uint         updateTimestamp;
    uint         uploadTimestamp;
    bool         viewing;

    Map() { }
    Map(Json::Value@ map) {
        mapUid          = map["uid"];
        thumbnailFile   = Files::thumbnailFolder + "/" + mapUid + ".jpg";  // needs to be Uid
        mapId           = map["mapId"];
        mapNameRaw      = map["name"];
        mapNameColor    = ColoredString(mapNameRaw);
        mapNameText     = StripFormatCodes(mapNameRaw);
        logName         = "MAP[ " + mapNameText + " ] - ";
        authorId        = map["author"];
        authorTime      = map["authorTime"];
        goldTime        = map["goldTime"];
        silverTime      = map["silverTime"];
        bronzeTime      = map["bronzeTime"];
        downloadUrl     = string(map["downloadUrl"]).Replace("\\", "");
        thumbnailUrl    = string(map["thumbnailUrl"]).Replace("\\", "");
        uploadTimestamp = map["uploadTimestamp"];
        updateTimestamp = map["updateTimestamp"];
    }
    Map(Json::Value@ map, bool fromMapInfo) {
        authorId        = map["author"];
        authorTime      = map["authorScore"];
        bronzeTime      = map["bronzeScore"];
        downloadUrl     = map["fileUrl"];
        goldTime        = map["goldScore"];
        mapId           = map["mapId"];
        mapNameRaw      = map["name"];
        mapNameColor    = ColoredString(mapNameRaw);
        mapNameText     = StripFormatCodes(mapNameRaw);
        logName         = "MAP[ " + mapNameText + " ] - ";
        mapUid          = map["mapUid"];
        silverTime      = map["silverScore"];
        thumbnailFile    = Files::thumbnailFolder + "/" + mapUid + ".jpg";
        thumbnailUrl    = map["thumbnailUrl"];
        updateTimestamp = Util::IsoToUnix(map["timestamp"]);
        uploadTimestamp = updateTimestamp;
    }
    Map(SQLite::Statement@ s) {
        authorId         = s.GetColumnString("authorId");
        authorTime       = s.GetColumnInt   ("authorTime");
        bronzeTime       = s.GetColumnInt   ("bronzeTime");
        downloadUrl      = s.GetColumnString("downloadUrl");
        goldTime         = s.GetColumnInt   ("goldTime");
        mapId            = s.GetColumnString("mapId");
        mapNameRaw       = s.GetColumnString("mapNameRaw");
        mapNameColor     = ColoredString(mapNameRaw);
        mapNameText      = StripFormatCodes(mapNameRaw);
        logName          = "MAP[ " + mapNameText + " ] - ";
        mapUid           = s.GetColumnString("mapUid");
        recordsTimestamp = s.GetColumnInt   ("recordsTimestamp");
        silverTime       = s.GetColumnInt   ("silverTime");
        thumbnailFile    = Files::thumbnailFolder + "/" + mapUid + ".jpg";
        thumbnailUrl     = s.GetColumnString("thumbnailUrl");
        updateTimestamp  = s.GetColumnInt   ("updateTimestamp");
        uploadTimestamp  = s.GetColumnInt   ("uploadTimestamp");
    }

    // courtesy of "Play Map" plugin - https://github.com/XertroV/tm-play-map
    void EditCoro() {
        if (Locks::editMap)
            return;

        Locks::editMap = true;
        Log::Write(Log::Level::Normal, logName + "loading map for editing");

        CTrackMania@ app = cast<CTrackMania@>(GetApp());
        app.BackToMainMenu();
        while (!app.ManiaTitleControlScriptAPI.IsReady)
            yield();
        while (app.Switcher.ModuleStack.Length == 0 || cast<CTrackManiaMenus>(app.Switcher.ModuleStack[0]) is null)
            yield();
        yield();
        app.ManiaTitleControlScriptAPI.EditMap(downloadUrl, "", "");

        uint64 waitToEditAgain = 5000;
        uint64 now = Time::Now;
        while (Time::Now - now < waitToEditAgain)
            yield();

        Locks::editMap = false;
    }

    void GetRecordsCoro() {
        if (Locks::singleRecords)
            return;

        if (hidden) {
            Log::Write(Log::Level::Debug, logName + "map hidden, records skipped");
            return;
        }

        Locks::singleRecords = true;
        string timerId = Log::TimerBegin(logName + "getting records");
        string statusId = "map-records-" + mapUid;

        if (Globals::singleMapRecordStatus)
            Globals::status.Set(statusId, "getting records for " + mapNameText + " ...");

        string[] accountIds;
        uint offset = 0;
        Record[] tmpRecords;
        dictionary tmpRecordsDict;
        bool tooManyRecords;

        if (records.Length > Settings::maxRecordsPerMap)
            Database::ClearMapRecords(this);

        Globals::ClearMyMapRecords(this);

        do {
            Meta::PluginCoroutine@ waitCoro = startnew(CoroutineFunc(Util::NandoRequestWaitCoro));
            while (waitCoro.IsRunning())
                yield();

            Net::HttpRequest@ req = NadeoServices::Get(  // sorted by position asc
                Globals::apiLive,
                NadeoServices::BaseURLLive() +
                    "/api/token/leaderboard/group/Personal_Best/map/" + mapUid +
                    "/top?onlyWorld=true&length=100&offset=" + offset
            );
            req.Start();
            while (!req.Finished())
                yield();
            Locks::requesting = false;
            offset += 100;

            Json::Value@ top;
            try {
                @top = Json::Parse(req.String())["tops"][0]["top"];
            } catch {
                Log::Write(Log::Level::Errors, logName + "error parsing top: " + getExceptionInfo());
                break;
            }

            tooManyRecords = top.Length == 100;

            for (uint i = 0; i < top.Length; i++) {
                Record record = Record(top[i]);

                record.mapId        = mapId;
                record.mapNameText  = mapNameText;
                record.mapUid       = mapUid;
                record.recordFakeId = mapId + "-" + record.accountId;

                Globals::AddAccount(Account(record));
                accountIds.InsertLast(record.accountId);

                tmpRecords.InsertLast(record);
                tmpRecordsDict.Set(record.accountId, @tmpRecords[tmpRecords.Length - 1]);
            }

        } while (
            tooManyRecords &&
            tmpRecords.Length < Settings::maxRecordsPerMap
        );

        while (accountIds.Length > 0) {
            string[] group;
            int idsToAdd = Math::Min(accountIds.Length, 206);
            for (int i = 0; i < idsToAdd; i++)
                group.InsertLast(accountIds[i]);
            accountIds.RemoveRange(0, idsToAdd);

            Meta::PluginCoroutine@ waitCoro = startnew(CoroutineFunc(Util::NandoRequestWaitCoro));
            while (waitCoro.IsRunning())
                yield();

            Net::HttpRequest@ req = NadeoServices::Get(  // sorted by timestamp asc
                Globals::apiCore,
                NadeoServices::BaseURLCore() +
                "/mapRecords/?accountIdList=" + string::Join(group, "%2C") +
                "&mapIdList=" + mapId
            );
            req.Start();
            while (!req.Finished())
                yield();
            Locks::requesting = false;

            Json::Value@ coreRecords;
            try {
                @coreRecords = Json::Parse(req.String());
            } catch {
                Log::Write(Log::Level::Errors, logName + "error parsing coreRecords: " + getExceptionInfo());
                continue;
            }

            for (uint i = 0; i < coreRecords.Length; i++) {
                Json::Value@ coreRecord = @coreRecords[i];
                Record@ tmpRecord = cast<Record@>(tmpRecordsDict[coreRecord["accountId"]]);

                tmpRecord.recordId = coreRecord["mapRecordId"];
                tmpRecord.timestampIso = coreRecord["timestamp"];
                tmpRecord.timestampUnix = Util::IsoToUnix(tmpRecord.timestampIso);
            }

            for (uint i = 0; i < tmpRecords.Length; i++)
                Globals::AddMyMapsRecord(tmpRecords[i]);
        }

        recordsTimestamp = Time::Stamp;
        Globals::recordsTimestampsJson[mapId] = recordsTimestamp;
        Files::SaveRecordsTimestamps();

        Meta::PluginCoroutine@ namesCoro = startnew(CoroutineFunc(Bulk::GetAccountNamesCoro));
        while (namesCoro.IsRunning())
            yield();

        if (Globals::singleMapRecordStatus)
            Globals::status.Delete(statusId);

        Log::TimerEnd(timerId);
        Locks::singleRecords = false;
    }

    void GetThumbnailCoro() {
        if (IO::FileExists(thumbnailFile))
            return;

        string timerId = Log::TimerBegin(logName + "getting thumbnail");
        string statusId = "get-thumb" + mapUid;
        Globals::status.Set(statusId, "getting thumbnail for " + mapNameText);

        uint maxTimeout = 3000;
        uint maxWait = 2000;

        while (true) {
            uint64 nowTimeout = Time::Now;
            bool timedOut = false;

            Net::HttpRequest@ req = Net::HttpGet(thumbnailUrl);
            while (!req.Finished()) {
                if (Time::Now - nowTimeout > maxTimeout) {
                    timedOut = true;
                    break;
                }
                yield();
            }

            if (timedOut) {
                Log::Write(Log::Level::Normal, logName + "getting thumbnail timed out, waiting " + maxWait + " ms");

                uint64 nowWait = Time::Now;
                while (Time::Now - nowWait < maxWait)
                    yield();

                continue;
            }

            req.SaveToFile(thumbnailFile);
            break;
        }

        Globals::status.Delete(statusId);
        Log::TimerEnd(timerId);
    }

    void LoadThumbnailCoro() {
        if (thumbnailTexture !is null || thumbnailLoading)
            return;

        string timerId = Log::TimerBegin(logName + "loading thumbnail");
        thumbnailLoading = true;

        Meta::PluginCoroutine@ thumbCoro = startnew(CoroutineFunc(GetThumbnailCoro));
        while (thumbCoro.IsRunning()) yield();

        IO::File file(thumbnailFile, IO::FileMode::Read);
        @thumbnailTexture = UI::LoadTexture(file.Read(file.Size()));
        file.Close();

        Log::TimerEnd(timerId);
        thumbnailLoading = false;
    }

    // courtesy of "Play Map" plugin - https://github.com/XertroV/tm-play-map
    void PlayCoro() {
        if (Locks::playMap)
            return;

        Locks::playMap = true;
        Log::Write(Log::Level::Normal, logName + "loading map for playing");

        if (!Permissions::PlayLocalMap()) {
            Util::NotifyError("Paid access required - can't load map " + mapNameText);
            Locks::playMap = false;
            return;
        }

        CTrackMania@ app = cast<CTrackMania@>(GetApp());
        app.BackToMainMenu();
        while (!app.ManiaTitleControlScriptAPI.IsReady)
            yield();
        while (app.Switcher.ModuleStack.Length == 0 || cast<CTrackManiaMenus>(app.Switcher.ModuleStack[0]) is null)
            yield();
        yield();
        app.ManiaTitleControlScriptAPI.PlayMap(downloadUrl, "TrackMania/TM_PlayMap_Local", "");

        uint64 waitToPlayAgain = 5000;
        uint64 now = Time::Now;
        while (Time::Now - now < waitToPlayAgain)
            yield();

        Locks::playMap = false;
    }

    // courtesy of "Map Info" plugin - https://github.com/MisfitMaid/tm-map-info
    void TmxCoro() {
        if (Locks::tmx)
            return;

        Locks::tmx = true;
        string timerId = Log::TimerBegin(logName + "loading TMX");

        Net::HttpRequest@ req = Net::HttpRequest();
        req.Url = "https://trackmania.exchange/api/maps/get_map_info/uid/" + mapUid;
        req.Headers['User-Agent'] = "TMTracker v3 Plugin / contact=Ezio416";
        req.Method = Net::HttpMethod::Get;
        req.Start();

        uint maxTimeout = 5000;
        uint64 nowTimeout = Time::Now;
        bool timedOut = false;

        while (!req.Finished()) {
            if (Time::Now - nowTimeout > maxTimeout && !timedOut) {
                timedOut = true;
                Util::NotifyError("TMX took longer than " + maxTimeout + " ms to respond, site is likely down", 15000);
            }
            yield();
        }

        string reqError = req.Error();

        if (req.ResponseCode() >= 400 || req.ResponseCode() < 200 || reqError.Length > 0) {
            Log::Write(
                Log::Level::Errors,
                logName + "[status:" + req.ResponseCode() + "] error getting map by UID from TMX: " + reqError
            );
            Log::TimerDelete(timerId);
            Locks::tmx = false;
            return;
        }

        try {
            OpenBrowserURL("https://trackmania.exchange/tracks/view/" + int(Json::Parse(req.String()).Get("TrackID")));
        } catch {
            Util::NotifyError(logName + "error opening TMX: " + getExceptionInfo());
        }

        Log::TimerEnd(timerId);
        Locks::tmx = false;
    }
}}