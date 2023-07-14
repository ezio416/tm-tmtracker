/*
c 2023-05-26
m 2023-07-12
*/

namespace Tabs { namespace Maps {
    void Tab_MyMapsList() {
        if (!UI::BeginTabItem(Icons::MapO + " My Maps")) return;

        Globals::clickedMapId = "";
        bool firstMapExcluded = false;

        if (Settings::welcomeText) {
            UI::TextWrapped(
                "Once you've updated your maps, click on a thumbnail to open a tab for that map. " +
                "\nClose map tabs with a middle click or the \uE997"
            );
        }

        if (UI::Button(Icons::Refresh + " Refresh Maps (" + Globals::shownMaps + ")"))
            startnew(CoroutineFunc(Bulk::GetMyMapsCoro));

        UI::SameLine();
        int hiddenMapCount = Globals::hiddenMapsIndex.GetSize();
        if (Globals::showHidden) {
            if (UI::Button(Icons::EyeSlash + " Hide Hidden (" + hiddenMapCount + ")"))
                Globals::showHidden = false;
        } else {
            if (UI::Button(Icons::Eye + " Show Hidden (" + hiddenMapCount + ")"))
                Globals::showHidden = true;
        }

        if (Globals::currentMaps.Length > 0) {
            UI::SameLine();
            if (UI::Button(Icons::Times + " Clear Current Maps (" + Globals::currentMaps.Length + ")"))
                Globals::ClearCurrentMaps();
        }

        Globals::mapSearch = UI::InputText("search", Globals::mapSearch, false).ToLower();

        if (Globals::mapSearch != "") {
            UI::SameLine();
            if (UI::Button(Icons::Times + " Clear Search"))
                Globals::mapSearch = "";
        }

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