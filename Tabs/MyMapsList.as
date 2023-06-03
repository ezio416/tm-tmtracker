/*
c 2023-05-26
m 2023-05-29
*/

// Functions for rendering tabs in the interface
namespace Tabs {
    void MyMapsList() {
        if (!UI::BeginTabItem(Icons::Map + " Map List " + Icons::Map)) return;

        uint currentX = 0;
        auto size = UI::GetWindowSize();

        for (uint i = 0; i < Globals::myMaps.Length; i++) {
            auto map = Globals::myMaps[i];

            currentX += Settings::myMapsThumbnailWidthList;
            if (i > 0 && currentX < uint(size.x))
                UI::SameLine();

            UI::BeginGroup();
                auto pos = UI::GetCursorPos();
                auto thumbSize = vec2(Settings::myMapsThumbnailWidthList, Settings::myMapsThumbnailWidthList);
                try   { UI::Image(map.thumbnailTexture, thumbSize); }
                catch { UI::Image(Globals::defaultTexture, thumbSize); }

                UI::SetCursorPos(pos);
                if (UI::InvisibleButton("invis_" + map.mapId, thumbSize)) {
                    if (!Globals::currentMapIds.Exists(map.mapId)) {
                        Globals::currentMapIds.Set(map.mapId, "");
                        Globals::currentMaps.InsertLast(@Globals::myMaps[i]);
                    }
                    Globals::mapClicked = true;
                }

                currentX = uint(UI::GetCursorPos().x) + Settings::myMapsThumbnailWidthList + 44;
                UI::PushTextWrapPos(currentX - 44);  // 44 pixels for scrollbar works on 1.5x scaling at 4K
                UI::Text((Settings::myMapsListColor) ? map.mapNameColor : map.mapNameText);
                UI::PopTextWrapPos();
                UI::Text("\n");
            UI::EndGroup();
        }

        UI::EndTabItem();
    }
}