// c 2023-05-26
// m 2023-12-26

namespace Tabs { namespace MyMaps {
    string mapSearch;

    void Tab_MyMapsList() {
        if (!UI::BeginTabItem(Icons::ListUl + " Maps (" + Globals::shownMaps + ")###my-maps-list"))
            return;

        if (Settings::myMapsListText)
            UI::TextWrapped(
                "Map upload times are unreliable, so the order is just how they come from Nadeo (roughly newest-oldest)." +
                "\nIf you upload a map again or add it to a club campaign, it's moved to the top of the list." +
                "\nClick on a map to add it to the \"Viewing Maps\" tab above."
            );

        UI::BeginDisabled(Locks::myMaps);
        if (UI::Button(Icons::Refresh + " Refresh Maps"))
            startnew(CoroutineFunc(Bulk::GetMyMapsCoro));
        UI::EndDisabled();

        UI::SameLine();
        int hiddenMapCount = Globals::hiddenMapsJson.GetKeys().Length;
        if (Globals::showHidden) {
            if (UI::Button(Icons::EyeSlash + " Hide Hidden (" + hiddenMapCount + ")"))
                Globals::showHidden = false;
        } else {
            UI::BeginDisabled(Globals::myMaps.Length == 0);
            if (UI::Button(Icons::Eye + " Show Hidden (" + hiddenMapCount + ")"))
                Globals::showHidden = true;
            UI::EndDisabled();
        }

        if (Settings::myMapsSearch) {
            mapSearch = UI::InputText("search maps", mapSearch, false);

            if (mapSearch != "") {
                UI::SameLine();
                if (UI::Button(Icons::Times + " Clear Search"))
                    mapSearch = "";
            }
        } else
            mapSearch = "";

        Table_MyMapsList();

        UI::EndTabItem();
    }

    void Table_MyMapsList() {
        int64 now = Time::Stamp;
        Models::Map@[] maps;

        string mapSearchLower = mapSearch.ToLower();

        for (uint i = 0; i < Globals::myMaps.Length; i++) {
            Models::Map@ map = @Globals::myMaps[i];

            if (map is null || (map.hidden && !Globals::showHidden))
                continue;

            if (mapSearchLower == "" || (mapSearchLower != "" && map.mapNameText.ToLower().Contains(mapSearchLower)))
                maps.InsertLast(map);
        }

        int colCount = 1;
        if (Settings::myMapsListColRecords)     colCount++;
        if (Settings::myMapsListColRecordsTime) colCount++;
        if (Settings::myMapsListColUpload)      colCount++;

        int flags = UI::TableFlags::Resizable |
                    UI::TableFlags::RowBg |
                    UI::TableFlags::ScrollY;

        if (UI::BeginTable("my-maps-table", colCount, flags)) {
            UI::PushStyleColor(UI::Col::TableRowBgAlt, Globals::colorTableRowBgAlt);

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
                    if (UI::Selectable((Settings::mapNameColors ? map.mapNameColor : map.mapNameText) + "##" + map.mapUid, false, UI::SelectableFlags::SpanAllColumns))
                        Globals::AddMyMapViewing(map);

                    if (Settings::myMapsListColRecords) {
                        UI::TableNextColumn();
                        UI::Text(tostring(map.records.Length));
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