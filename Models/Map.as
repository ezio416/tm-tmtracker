/*
c 2023-05-16
m 2023-07-11
*/

namespace Models {
    class Map {
        string            authorId;
        uint              authorTime;
        uint              bronzeTime;
        string            downloadUrl;
        uint              goldTime;
        bool              hidden;
        string            logName;
        string            mapId;
        string            mapNameColor;
        string            mapNameRaw;
        string            mapNameText;
        string            mapUid;
        Models::Record@[] records;
        dictionary        recordsIndex;
        uint              recordsTimestamp;
        uint              silverTime;
        string            thumbnailFile;
        UI::Texture@      thumbnailTexture;
        string            thumbnailUrl;
        bool              viewing;

        Map() { }
        Map(Json::Value map) {
            mapUid        = map["uid"];
            thumbnailFile = Globals::thumbnailFolder + "/" + mapUid + ".jpg";
            mapId         = map["mapId"];
            mapNameRaw    = map["name"];
            mapNameColor  = ColoredString(mapNameRaw);
            mapNameText   = StripFormatCodes(mapNameRaw);
            logName       = "MAP[" + mapNameText + "] - ";
            authorId      = map["author"];
            authorTime    = map["authorTime"];
            goldTime      = map["goldTime"];
            silverTime    = map["silverTime"];
            bronzeTime    = map["bronzeTime"];
            downloadUrl   = string(map["downloadUrl"]).Replace("\\", "");
            thumbnailUrl  = string(map["thumbnailUrl"]).Replace("\\", "");
        }

        void GetRecordsCoro() {
            if (hidden || Locks::singleRecords) return;
            Locks::singleRecords = true;

            string timerId = Util::LogTimerBegin(logName + "getting records");

            string statusId = "map-records-" + mapId;
            if (Globals::singleMapRecordStatus)
                Globals::status.Set(statusId, "getting records for " + mapNameText + " ...");

            string[] accountIds;
            uint offset = 0;
            Models::Record[] tmpRecords;
            dictionary tmpRecordsIndex;
            bool tooManyRecords;

            Globals::ClearMapRecords(this);

            do {
                auto waitCoro = startnew(CoroutineFunc(Util::WaitToDoNadeoRequestCoro));
                while (waitCoro.IsRunning()) yield();

                auto req = NadeoServices::Get(  // sorted by position asc
                    "NadeoLiveServices",
                    NadeoServices::BaseURLLive() +
                        "/api/token/leaderboard/group/Personal_Best/map/" + mapUid +
                        "/top?onlyWorld=true&length=100&offset=" + offset
                );
                req.Start();
                while (!req.Finished()) yield();
                Globals::requesting = false;
                offset += 100;

                auto top = Json::Parse(req.String())["tops"][0]["top"];
                tooManyRecords = top.Length == 100;
                for (uint i = 0; i < top.Length; i++) {
                    auto record = Record(top[i]);
                    record.mapId        = mapId;
                    record.mapName      = mapNameText;
                    record.mapUid       = mapUid;
                    record.recordFakeId = mapId + "-" + record.accountId;

                    record.SetMedals(this);

                    Globals::AddAccount(Account(record));
                    accountIds.InsertLast(record.accountId);
                    tmpRecords.InsertLast(record);
                    tmpRecordsIndex.Set(record.accountId, @tmpRecords[tmpRecords.Length - 1]);
                }

            } while (tooManyRecords && tmpRecords.Length < Settings::maxRecordsPerMap);

            while (accountIds.Length > 0) {
                string[] group;
                int idsToAdd = Math::Min(accountIds.Length, 206);
                for (int i = 0; i < idsToAdd; i++)
                    group.InsertLast(accountIds[i]);
                accountIds.RemoveRange(0, idsToAdd);

                auto waitCoro = startnew(CoroutineFunc(Util::WaitToDoNadeoRequestCoro));
                while (waitCoro.IsRunning()) yield();

                auto req = NadeoServices::Get(  // sorted by timestamp asc
                    "NadeoServices",
                    NadeoServices::BaseURLCore() +
                    "/mapRecords/?accountIdList=" + string::Join(group, "%2C") +
                    "&mapIdList=" + mapId
                );
                req.Start();
                while (!req.Finished()) yield();
                Globals::requesting = false;

                auto coreRecords = Json::Parse(req.String());
                for (uint i = 0; i < coreRecords.Length; i++) {
                    auto coreRecord = @coreRecords[i];
                    auto tmpRecord = cast<Models::Record@>(tmpRecordsIndex[coreRecord["accountId"]]);
                    tmpRecord.recordId = coreRecord["mapRecordId"];
                    tmpRecord.timestampIso = coreRecord["timestamp"];
                    tmpRecord.timestampUnix = Util::IsoToUnix(tmpRecord.timestampIso);
                }

                for (uint i = 0; i < tmpRecords.Length; i++)
                    Globals::AddRecord(tmpRecords[i]);
            }

            recordsTimestamp = Time::Stamp;

            auto namesCoro = startnew(CoroutineFunc(Bulk::GetAccountNamesCoro));
            while (namesCoro.IsRunning()) yield();

            if (Globals::singleMapRecordStatus)
                Globals::status.Delete(statusId);

            Util::LogTimerEnd(timerId);
            Locks::singleRecords = false;
        }

        void GetThumbnailCoro() {
            if (IO::FileExists(thumbnailFile)) return;

            string timerId = Util::LogTimerBegin(logName + "downloading thumbnail");

            uint max_timeout = 3000;
            uint max_wait = 2000;
            while (true) {
                auto nowTimeout = Time::Now;
                bool timedOut = false;

                auto req = Net::HttpGet(thumbnailUrl);
                while (!req.Finished()) {
                    if (Time::Now - nowTimeout > max_timeout) {
                        timedOut = true;
                        break;
                    }
                    yield();
                }
                if (timedOut) {
                    Util::Trace(logName + "timed out, waiting " + max_wait + " ms");
                    auto nowWait = Time::Now;
                    while (Time::Now - nowWait < max_wait) yield();
                    continue;
                }
                req.SaveToFile(thumbnailFile);
                break;
            }

            Util::LogTimerEnd(timerId);
        }

        void LoadThumbnailCoro() {
            string timerId = Util::LogTimerBegin(logName + "loading thumbnail", false);

            if (Globals::thumbnailTextures.Exists(mapId)) {
                UI::Texture@ tex;
                @tex = cast<UI::Texture@>(Globals::thumbnailTextures[mapId]);
                if (@thumbnailTexture == null)
                    @thumbnailTexture = tex;
                Util::LogTimerEnd(timerId, false);
                return;
            }

            if (!IO::FileExists(thumbnailFile)) {
                auto coro = startnew(CoroutineFunc(GetThumbnailCoro));
                while (coro.IsRunning()) yield();
            }

            IO::File file(thumbnailFile, IO::FileMode::Read);
            @thumbnailTexture = UI::LoadTexture(file.Read(file.Size()));
            file.Close();

            Globals::thumbnailTextures.Set(mapId, @thumbnailTexture);

            Util::LogTimerEnd(timerId, false);
        }

        // courtesy of "Play Map" plugin - https://github.com/XertroV/tm-play-map
        void PlayCoro() {
            if (Locks::playMap) return;
            Locks::playMap = true;

            if (!Permissions::PlayLocalMap()) {
                Util::Warn("Refusing to load map because you lack the necessary permissions. Standard or Club access required.");
                return;
            }
            // change the menu page to avoid main menu bug where 3d scene not redrawn correctly (which can lead to a script error and `recovery restart...`)
            auto app = cast<CGameManiaPlanet>(GetApp());
            app.BackToMainMenu();
            while (!app.ManiaTitleControlScriptAPI.IsReady) yield();
            while (app.Switcher.ModuleStack.Length < 1 || cast<CTrackManiaMenus>(app.Switcher.ModuleStack[0]) is null) yield();
            yield();
            app.ManiaTitleControlScriptAPI.PlayMap(downloadUrl, "TrackMania/TM_PlayMap_Local", "");

            uint64 waitToPlayAgain = 5000;
            auto now = Time::Now;
            while (Time::Now - now < waitToPlayAgain) yield();

            Locks::playMap = false;
        }

        // courtesy of "Map Info" plugin - https://github.com/MisfitMaid/tm-map-info
        void TmxCoro() {
            if (Locks::tmx) return;
            Locks::tmx = true;

            auto req = Net::HttpRequest();
            req.Url = "https://trackmania.exchange/api/maps/get_map_info/uid/" + mapUid;
            req.Headers['User-Agent'] = "TMTracker v3 Plugin / contact=Ezio416";
            req.Method = Net::HttpMethod::Get;
            req.Start();
            while (!req.Finished()) yield();
            if (req.ResponseCode() >= 400 || req.ResponseCode() < 200 || req.Error().Length > 0) {
                Util::Warn("[status:" + req.ResponseCode() + "] Error getting map by UID from TMX: " + req.Error());
                return;
            }
            try {
                OpenBrowserURL("https://trackmania.exchange/tracks/view/" + int(Json::Parse(req.String()).Get("TrackID")));
            } catch {
                Util::NotifyWarn("Error opening TMX for map " + mapNameText);
            }

            Locks::tmx = false;
        }
    }
}