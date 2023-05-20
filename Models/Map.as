/*
c 2023-05-16
m 2023-05-20
*/

namespace Models {
    class Map {
        string       authorId;
        uint         authorTime;
        bool         badUploadTime;
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
        Record[]     records;
        uint         silverTime;
        string       thumbnailFile;
        UI::Texture@ thumbnailTexture;
        string       thumbnailUrl;
        uint         timestamp;
        bool         viewing;

        Map() {}

        Map(Json::Value map) {
            mapUid        = map["uid"];
            thumbnailFile = Storage::thumbnailFolder + "/" + mapUid + ".jpg";
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
            if (map["uploadTimestamp"] < 1600000000) {
                badUploadTime = true;  // for some maps, Nadeo only provides the year
                timestamp = map["updateTimestamp"];
            } else
                timestamp = map["uploadTimestamp"];
        }

        Map(SQLite::Statement@ s) {
            authorId      = s.GetColumnString("authorId");
            authorTime    = s.GetColumnInt("authorTime");
            badUploadTime = s.GetColumnInt("badUploadTime") == 1 ? true : false;
            bronzeTime    = s.GetColumnInt("bronzeTime");
            downloadUrl   = s.GetColumnString("downloadUrl");
            goldTime      = s.GetColumnInt("goldTime");
            mapId         = s.GetColumnString("mapId");
            mapNameRaw    = s.GetColumnString("mapNameRaw");
            mapNameColor  = ColoredString(mapNameRaw);
            mapNameText   = StripFormatCodes(mapNameRaw);
            logName       = "MAP[" + mapNameText + "] - ";
            mapUid        = s.GetColumnString("mapUid");
            thumbnailFile = Storage::thumbnailFolder + "/" + mapUid + ".jpg";
            silverTime    = s.GetColumnInt("silverTime");
            thumbnailUrl  = s.GetColumnString("thumbnailUrl");
            timestamp     = s.GetColumnInt("timestamp");
        }

        int opCmp(int i) { return timestamp - i; }
        int opCmp(Map m) { return timestamp - m.timestamp; }

        void GetRecordsCoro() {
            auto now = Time::Now;
            trace(logName + "getting records...");

            uint offset = 0;
            bool tooManyRecords;
            records.RemoveRange(0, records.Length);

            do {
                auto wait = startnew(CoroutineFunc(Various::WaitToDoNadeoRequest));
                while (wait.IsRunning()) yield();

                auto req = NadeoServices::Get(
                    "NadeoLiveServices",
                    NadeoServices::BaseURL() +
                        "/api/token/leaderboard/group/Personal_Best/map/" + mapUid +
                        "/top?onlyWorld=true&length=100&offset=" + offset
                );
                offset += 100;
                req.Start();
                while (!req.Finished()) yield();

                auto top = Json::Parse(req.String())["tops"][0]["top"];
                tooManyRecords = top.Length == 100;
                for (uint i = 0; i < top.Length; i++) {
                    auto record = Record(top[i]);
                    record.mapUid = mapUid;
                    records.InsertLast(record);
                }

                Storage::requestsInProgress--;
            } while (tooManyRecords && records.Length < Settings::maxRecordsPerMap);

            if (Settings::printDurations)
                trace(logName + "getting records took " + (Time::Now - now) + " ms");
        }

        void GetThumbnailCoro() {
            auto now = Time::Now;

            if (IO::FileExists(thumbnailFile)) return;

            trace(logName + "downloading thumbnail...");
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
                    trace(logName + "timed out, waiting " + max_wait + " ms");
                    auto nowWait = Time::Now;
                    while (Time::Now - nowWait < max_wait) yield();
                    continue;
                }
                req.SaveToFile(thumbnailFile);
                break;
            }

            if (Settings::printDurations)
                trace(logName + "downloading thumbnail took " + (Time::Now - now) + " ms");
        }

        void LoadThumbnailCoro() {
            auto now = Time::Now;

            if (Storage::thumbnailTextures.Exists(mapUid)) {
                UI::Texture@ tex;
                @tex = cast<UI::Texture@>(Storage::thumbnailTextures[mapUid]);
                if (@thumbnailTexture == null)
                    @thumbnailTexture = tex;
                return;
            }

            if (!IO::FileExists(thumbnailFile)) {
                auto @coro = startnew(CoroutineFunc(GetThumbnailCoro));
                while (coro.IsRunning()) yield();
            }

            IO::File file(thumbnailFile, IO::FileMode::Read);
            @thumbnailTexture = UI::LoadTexture(file.Read(file.Size()));
            file.Close();

            Storage::thumbnailTextures.Set(mapUid, @thumbnailTexture);

            if (Settings::printDurations)
                trace(logName + "loading thumbnail took " + (Time::Now - now) + " ms");
        }
    }
}