/*
c 2023-05-26
m 2023-10-09
*/

namespace Tabs { namespace Maps {
    void Tab_MyMapsList() {
        if (!UI::BeginTabItem(Icons::MapO + " My Maps"))
            return;

        Globals::clickedMapId = "";

        if (Settings::myMapsListHint) {
            UI::TextWrapped(
                "Map upload times are unreliable, so the order is just how they come from Nadeo (roughly newest-oldest)." +
                "\nClick on a map name to open a tab for that map." +
                "\nClose map tabs with a middle click or the " + Icons::Kenney::ButtonTimes +
                "\nYou cannot get records for hidden maps."
            );
        }

        UI::BeginDisabled(Locks::myMaps);
        if (UI::Button(Icons::Refresh + " Refresh Maps (" + Globals::shownMaps + ")"))
            startnew(CoroutineFunc(Bulk::GetMyMapsCoro));
        UI::EndDisabled();

        UI::SameLine();
        int hiddenMapCount = Globals::hiddenMapsJson.GetKeys().Length;
        if (Globals::showHidden) {
            if (UI::Button(Icons::EyeSlash + " Hide Hidden (" + hiddenMapCount + ")"))
                Globals::showHidden = false;
        } else {
            UI::BeginDisabled(Globals::maps.Length == 0);
            if (UI::Button(Icons::Eye + " Show Hidden (" + hiddenMapCount + ")"))
                Globals::showHidden = true;
            UI::EndDisabled();
        }

        UI::BeginDisabled(Globals::currentMaps.Length == 0);
        UI::SameLine();
        if (UI::Button(Icons::Times + " Clear Current (" + Globals::currentMaps.Length + ")"))
            Globals::ClearCurrentMaps();
        UI::EndDisabled();

        Globals::mapSearch = UI::InputText("search", Globals::mapSearch, false);

        if (Globals::mapSearch != "") {
            UI::SameLine();
            if (UI::Button(Icons::Times + " Clear Search"))
                Globals::mapSearch = "";
        }

        Table_MyMapsList();

        UI::EndTabItem();
    }

    void Table_MyMapsList() {
        int64 now = Time::Stamp;
        Models::Map@[] maps;

        for (uint i = 0; i < Globals::maps.Length; i++) {
            Models::Map@ map = @Globals::maps[i];
            if (map is null) continue;

            if (map.hidden && !Globals::showHidden) continue;
            if (map.mapNameText.ToLower().Contains(Globals::mapSearch.ToLower()))
                maps.InsertLast(map);
        }

        int colCount = 1;
        if (Settings::myMapsListColRecords)     colCount++;
        if (Settings::myMapsListColRecordsTime) colCount++;
        if (Settings::myMapsListColUpload)      colCount++;

        int flags =
            UI::TableFlags::Resizable |
            UI::TableFlags::RowBg |
            UI::TableFlags::ScrollY;

        if (UI::BeginTable("my-maps-table", colCount, flags)) {
            UI::PushStyleColor(UI::Col::TableRowBgAlt, Globals::tableRowBgAltColor);

            UI::TableSetupScrollFreeze(0, 1);
            UI::TableSetupColumn("Name");
            if (Settings::myMapsListColRecords)
                UI::TableSetupColumn("# of Records");
            if (Settings::myMapsListColRecordsTime)
                UI::TableSetupColumn("Records Recency");
            if (Settings::myMapsListColUpload)
                UI::TableSetupColumn("Latest Upload");
            UI::TableHeadersRow();

            UI::ListClipper clipper(maps.Length);
            while (clipper.Step()) {
                for (int i = clipper.DisplayStart; i < clipper.DisplayEnd; i++) {
                    Models::Map@ map = maps[i];

                    UI::TableNextRow();
                    UI::TableNextColumn();
                    if (UI::Selectable((Settings::myMapsListColor ? map.mapNameColor : map.mapNameText) + "##" + map.mapUid, false, UI::SelectableFlags::SpanAllColumns))
                        Globals::AddCurrentMap(map);

                    if (Settings::myMapsListColRecords) {
                        UI::TableNextColumn();
                        UI::Text("" + map.records.Length);
                    }

                    if (Settings::myMapsListColRecordsTime) {
                        UI::TableNextColumn();
                        UI::Text(map.recordsTimestamp > 0 ? Util::FormatSeconds(now - map.recordsTimestamp) : "never");
                    }

                    if (Settings::myMapsListColUpload) {
                        UI::TableNextColumn();
                        UI::Text(Util::UnixToIso(Math::Max(map.uploadTimestamp, map.updateTimestamp)));
                    }
                }
            }

            UI::PopStyleColor();
            UI::EndTable();
        }
    }
}}