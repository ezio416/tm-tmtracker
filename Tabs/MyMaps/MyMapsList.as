/*
c 2023-05-26
m 2023-07-10
*/

namespace Tabs { namespace MyMaps {
    void Tab_List() {
        if (!UI::BeginTabItem(Icons::MapO + " My Maps")) return;

        Globals::clickedMapId = "";

        if (UI::BeginChild("MyMapsList")) {
            uint curX = 0;
            auto size = UI::GetWindowSize();

            for (uint i = 0; i < Globals::maps.Length; i++) {
                auto map = @Globals::maps[i];

                if (map.hidden && !Globals::showHidden) continue;

                curX += Settings::myMapsListThumbnailWidth;
                if (i > 0 && curX < uint(size.x))
                    UI::SameLine();

                UI::BeginGroup();
                    auto pos = UI::GetCursorPos();
                    auto thumbSize = vec2(Settings::myMapsListThumbnailWidth, Settings::myMapsListThumbnailWidth);
                    try   { UI::Image(map.thumbnailTexture, thumbSize); }
                    catch { UI::Image(Globals::defaultTexture, thumbSize); }

                    UI::SetCursorPos(pos);
                    if (UI::InvisibleButton("invis_" + map.mapId, thumbSize)) {
                        Globals::AddCurrentMap(map);
                        Globals::clickedMapId = map.mapId;
                    }

                    uint scrollbarPixels = 44;  // works on 4K, 1.5x scaling
                    curX = uint(UI::GetCursorPos().x) + Settings::myMapsListThumbnailWidth + scrollbarPixels;
                    UI::PushTextWrapPos(curX - scrollbarPixels);
                    UI::Text((Settings::myMapsListColor) ? map.mapNameColor : map.mapNameText);
                    UI::PopTextWrapPos();
                    UI::Text("\n");
                UI::EndGroup();
            }
        }
        UI::EndChild();

        UI::EndTabItem();
    }
}}