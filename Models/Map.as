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
            if (hidden) return;

            string timerId = Util::LogTimerBegin(logName + "getting records");

            string statusId = "map-records-" + mapId;
            if (Globals::singleMapRecordStatus)
                Globals::status.Set(statusId, "getting records for " + mapNameText + " ...");

            uint offset = 0;
            bool tooManyRecords;
            Models::Record[] tmpRecords;
            dictionary tmpRecordsIndex;

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
                    tmpRecords.InsertLast(record);
                    tmpRecordsIndex.Set(record.accountId, @tmpRecords[tmpRecords.Length - 1]);
                }

            } while (tooManyRecords && recordsIndex.GetSize() < Settings::maxRecordsPerMap);

            int maxAccounts = 206;
            string[] accountIds;
            for (uint i = 0; i < tmpRecords.Length; i++) {
                accountIds.InsertLast(tmpRecords[i].accountId);
            }
            string[][] accountIdGroups;
            while (accountIds.Length > 0) {
                string[] group;
                int idsToAdd = Math::Min(accountIds.Length, maxAccounts);
                for (int i = 0; i < idsToAdd; i++) {
                    group.InsertLast(accountIds[i]);
                }
                accountIds.RemoveRange(0, idsToAdd);
                accountIdGroups.InsertLast(group);
            }
            string[] accountIdReqGroups;
            for (uint i = 0; i < accountIdGroups.Length; i++) {
                accountIdReqGroups.InsertLast(string::Join(accountIdGroups[i], "%2C"));
            }
            for (uint i = 0; i < accountIdReqGroups.Length; i++) {
                auto waitCoro = startnew(CoroutineFunc(Util::WaitToDoNadeoRequestCoro));
                while (waitCoro.IsRunning()) yield();

                auto req = NadeoServices::Get(  // sorted by timestamp asc
                    "NadeoServices",
                    NadeoServices::BaseURLCore() +
                    "/mapRecords/?accountIdList=" + accountIdReqGroups[i] +
                    "&mapIdList=" + mapId
                );
                req.Start();
                while (!req.Finished()) yield();
                Globals::requesting = false;

                auto coreRecords = Json::Parse(req.String());
                for (uint j = 0; j < coreRecords.Length; j++) {
                    auto coreRecord = @coreRecords[j];
                    auto tmpRecord = cast<Models::Record@>(tmpRecordsIndex[coreRecord["accountId"]]);

                    tmpRecord.recordId = coreRecord["mapRecordId"];
                    tmpRecord.timestampIso = coreRecord["timestamp"];
                    tmpRecord.timestampUnix = Util::IsoToUnix(tmpRecord.timestampIso);

                    Globals::AddRecord(tmpRecord);
                }
            }

            recordsTimestamp = Time::Stamp;

            auto namesCoro = startnew(CoroutineFunc(API::GetAccountNamesCoro));
            while (namesCoro.IsRunning()) yield();

            if (Globals::singleMapRecordStatus)
                Globals::status.Delete(statusId);

            Util::LogTimerEnd(timerId);
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
    }
}