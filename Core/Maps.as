/*
c 2023-05-16
m 2023-07-06
*/

namespace Maps {
    void GetMyMapsThumbnailsCoro() {
        string timerId = Util::LogTimerBegin("getting my map thumbnails");

        for (uint i = 0; i < Globals::myMaps.Length; i++) {
            auto coro = startnew(CoroutineFunc(Globals::myMaps[i].GetThumbnailCoro));
            while (coro.IsRunning()) yield();
        }

        Util::LogTimerEnd(timerId);
    }

    void LoadMyMapsThumbnailsCoro() {
        string timerId = Util::LogTimerBegin("loading my map thumbnails");

        for (uint i = 0; i < Globals::myMaps.Length; i++) {
            Globals::status.Set("load-thumbs", "loading thumbnails... (" + i + "/" + Globals::myMaps.Length + ")");
            auto coro = startnew(CoroutineFunc(Globals::myMaps[i].LoadThumbnailCoro));
            while (coro.IsRunning()) yield();
        }

        Globals::status.Delete("load-thumbs");
        Util::LogTimerEnd(timerId);
    }
}