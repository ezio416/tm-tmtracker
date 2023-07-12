/*
c 2023-05-26
m 2023-07-11
*/

namespace Tabs { namespace Maps {
    void Tab_MyMapsList() {
        if (!UI::BeginTabItem(Icons::MapO + " My Maps")) return;

        Globals::clickedMapId = "";
        bool firstMapExcluded = false;

        Globals::mapSearch = UI::InputText("search", Globals::mapSearch, false).ToLower();

        UI::SameLine();
        if (UI::Button(Icons::Times + " Clear Search"))
            Globals::mapSearch = "";

        if (UI::BeginChild("MyMapsList")) {
            uint curX = 0;
            auto size = UI::GetWindowSize();

            for (uint i = 0; i < Globals::maps.Length; i++) {
                auto map = @Globals::maps[i];

                if (map.hidden && !Globals::showHidden) continue;
                if (!map.mapNameText.ToLower().Contains(Globals::mapSearch)) {
                    if (i == 0) firstMapExcluded = true;
                    continue;
                }

                curX += Settings::myMapsListThumbnailWidth;
                if (i > 0) {
                    if (curX < uint(size.x) && !firstMapExcluded)
                        UI::SameLine();
                    else
                        firstMapExcluded = false;
                }

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