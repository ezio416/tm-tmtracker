/*
c 2023-05-26
m 2023-09-19
*/

namespace Tabs { namespace Maps {
    void Tab_MyMapsList() {
        if (!UI::BeginTabItem(Icons::MapO + " My Maps")) return;

        Globals::clickedMapId = "";
        // bool firstMapExcluded = false;

        if (Settings::myMapsListHint) {
            UI::TextWrapped(
                "Map upload times are unreliable, so the order is just how they come from Nadeo (roughly newest-oldest)." +
                "\nClick on a thumbnail to open a tab for that map." +
                "\nClose map tabs with a middle click or the \uE997" +
                "\nYou cannot get records for hidden maps."
            );
        }

        UI::BeginDisabled(Locks::myMaps);
        if (UI::Button(Icons::Refresh + " Refresh Maps (" + Globals::shownMaps + ")"))
            startnew(CoroutineFunc(Bulk::GetMyMapsCoro));
        UI::EndDisabled();

        UI::SameLine();
        int hiddenMapCount = Globals::hiddenMapsIndex.GetKeys().Length;
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

        Globals::mapSearch = UI::InputText("search", Globals::mapSearch, false);

        if (Globals::mapSearch != "") {
            UI::SameLine();
            if (UI::Button(Icons::Times + " Clear Search"))
                Globals::mapSearch = "";
        }

        Table_MyMapsList();

        // if (UI::BeginChild("MyMapsList")) {
            // uint curX = 0;
            // vec2 size = UI::GetWindowSize();

            // for (uint i = 0; i < Globals::maps.Length; i++) {
            //     auto map = @Globals::maps[i];

            //     if (map.hidden && !Globals::showHidden) continue;
            //     if (!map.mapNameText.ToLower().Contains(Globals::mapSearch)) {
            //         if (i == 0) firstMapExcluded = true;
            //         continue;
            //     }

            //     curX += Settings::myMapsListThumbWidth;
            //     if (i > 0) {
            //         if (curX < uint(size.x) && !firstMapExcluded)
            //             UI::SameLine();
            //         else
            //             firstMapExcluded = false;
            //     }

            //     UI::BeginGroup();
            //         vec2 pos = UI::GetCursorPos();
            //         vec2 thumbSize = vec2(Settings::myMapsListThumbWidth, Settings::myMapsListThumbWidth);
            //         try   { UI::Image(map.thumbnailTexture, thumbSize); }
            //         catch { UI::Dummy(thumbSize); }

            //         if (map.hidden) {
            //             UI::SetCursorPos(pos);
            //             UI::Image(Globals::eyeTexture, thumbSize);
            //         }

            //         UI::SetCursorPos(pos);
            //         if (UI::InvisibleButton("invis_" + map.mapId, thumbSize)) {
            //             Globals::AddCurrentMap(map);
            //             Globals::clickedMapId = map.mapId;
            //         }

            //         int scrollbarPixels = int(Globals::scale * 30);
            //         curX = int(UI::GetCursorPos().x) + Settings::myMapsListThumbWidth + scrollbarPixels;
            //         UI::PushTextWrapPos(curX - scrollbarPixels);
            //         UI::Text((Settings::myMapsListColor) ? map.mapNameColor : map.mapNameText);
            //         UI::PopTextWrapPos();
            //         UI::Text("\n");
            //     UI::EndGroup();
            // }
        // }
        // UI::EndChild();

        UI::EndTabItem();
    }

    void Table_MyMapsList() {
        Models::Map@[] maps;

        for (uint i = 0; i < Globals::maps.Length; i++) {
            auto map = @Globals::maps[i];
            if (map.mapNameText.ToLower().Contains(Globals::mapSearch.ToLower()))
                maps.InsertLast(map);
        }

        int flags =
            UI::TableFlags::Resizable |
            UI::TableFlags::ScrollY;

        if (UI::BeginTable("my-maps-table", 2, flags)) {
            UI::TableSetupScrollFreeze(0, 1);
            UI::TableSetupColumn("Name");
            UI::TableSetupColumn("Record Count");
            UI::TableHeadersRow();

            UI::ListClipper clipper(maps.Length);
            while (clipper.Step()) {
                for (int i = clipper.DisplayStart; i < clipper.DisplayEnd; i++) {
                    auto map = maps[i];

                    UI::TableNextRow();
                    UI::TableNextColumn();
                    if (UI::Selectable((Settings::myMapsListColor ? map.mapNameColor : map.mapNameText) + "##" + map.mapUid, false)) {
                        Globals::AddCurrentMap(map);
                        Globals::clickedMapId = map.mapId;
                    }

                    UI::TableNextColumn();
                    UI::Text("" + map.records.Length);
                }
            }
            UI::EndTable();
        }
    }
}}