/*
c 2023-05-16
m 2023-07-10
*/

namespace Maps {
    void LoadMyMapsThumbnailsCoro() {
        string timerId = Util::LogTimerBegin("loading my map thumbnails");

        for (uint i = 0; i < Globals::maps.Length; i++) {
            Globals::status.Set("load-thumbs", "loading thumbnails... (" + (i + 1) + "/" + Globals::maps.Length + ")");
            auto map = @Globals::maps[i];
            auto coro = startnew(CoroutineFunc(map.LoadThumbnailCoro));
            while (coro.IsRunning()) yield();
        }

        Globals::status.Delete("load-thumbs");
        Util::LogTimerEnd(timerId);
    }
}