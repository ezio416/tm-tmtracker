// c 2023-05-26
// m 2023-12-27

namespace Tabs { namespace MyMaps {
    string mapSearch;
    uint myMapsResults = 0;

    void Tab_MyMapsList() {
        if (!UI::BeginTabItem(Icons::ListUl + " Maps (" + Globals::shownMaps + ")###my-maps-list"))
            return;

        if (Settings::myMapsListText)
            UI::TextWrapped(
                "Unfortunately, it's impossible to know the original upload date of any map." +
                "\nIf you upload a map again or add it to a club campaign, the upload date changes, so keep that in mind." +
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

                UI::SameLine();
                UI::Text(myMapsResults + " results");
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

        for (uint i = 0; i < Globals::myMapsSorted.Length; i++) {
            Models::Map@ map = Globals::myMapsSorted[i];

            if (map is null || (map.hidden && !Globals::showHidden))
                continue;

            if (mapSearchLower == "" || (mapSearchLower != "" && map.mapNameText.ToLower().Contains(mapSearchLower)))
                maps.InsertLast(map);
        }

        myMapsResults = maps.Length;

        int colCount = 1;
        if (Settings::myMapsListColNumber)      colCount++;
        if (Settings::myMapsListColRecords)     colCount++;
        if (Settings::myMapsListColRecordsTime) colCount++;
        if (Settings::myMapsListColUpload)      colCount++;

        int flags = UI::TableFlags::RowBg |
                    UI::TableFlags::ScrollY |
                    UI::TableFlags::Sortable;

        if (UI::BeginTable("my-maps-table", colCount, flags)) {
            UI::PushStyleColor(UI::Col::TableRowBgAlt, Globals::colorTableRowBgAlt);

            int fixed = UI::TableColumnFlags::WidthFixed;

            UI::TableSetupScrollFreeze(0, 1);
            if (Settings::myMapsListColNumber)      UI::TableSetupColumn("#",               fixed, Globals::scale * 35);
                                                    UI::TableSetupColumn("Name");
            if (Settings::myMapsListColRecords)     UI::TableSetupColumn("Records",         fixed, Globals::scale * 65);
            if (Settings::myMapsListColRecordsTime) UI::TableSetupColumn("Records Recency", fixed, Globals::scale * 125);
            if (Settings::myMapsListColUpload)      UI::TableSetupColumn("Latest Upload",   fixed, Globals::scale * 185);
            UI::TableHeadersRow();

            UI::TableSortSpecs@ tableSpecs = UI::TableGetSortSpecs();

            if (tableSpecs !is null && tableSpecs.Dirty) {
                UI::TableColumnSortSpecs[]@ colSpecs = tableSpecs.Specs;

                if (colSpecs !is null && colSpecs.Length > 0) {
                    bool ascending = colSpecs[0].SortDirection == UI::SortDirection::Ascending;

                    switch (colSpecs[0].ColumnIndex) {
                        case 0:  // number
                            Settings::myMapsSortMethod = ascending ? Sort::Maps::SortMethod::LowestFirst : Sort::Maps::SortMethod::HighestFirst;
                            break;
                        case 1:  // name
                            Settings::myMapsSortMethod = ascending ? Sort::Maps::SortMethod::NameAlpha : Sort::Maps::SortMethod::NameAlphaRev;
                            break;
                        case 2:  // # records
                            Settings::myMapsSortMethod = ascending ? Sort::Maps::SortMethod::LeastRecordsFirst : Sort::Maps::SortMethod::MostRecordsFirst;
                            break;
                        case 3:  // recency
                            Settings::myMapsSortMethod = ascending ? Sort::Maps::SortMethod::LatestRecordsRecencyFirst : Sort::Maps::SortMethod::EarliestRecordsRecencyFirst;
                            break;
                        case 4:  // upload
                            Settings::myMapsSortMethod = ascending ? Sort::Maps::SortMethod::EarliestUploadFirst : Sort::Maps::SortMethod::LatestUploadFirst;
                            break;
                        default:;
                    }

                    startnew(Sort::Maps::MyMapsCoro);
                }

                tableSpecs.Dirty = false;
            }

            UI::ListClipper clipper(maps.Length);
            while (clipper.Step()) {
                for (int i = clipper.DisplayStart; i < clipper.DisplayEnd; i++) {
                    Models::Map@ map = maps[i];

                    UI::TableNextRow();

                    if (Settings::myMapsListColNumber) {
                        UI::TableNextColumn();
                        UI::Text(tostring(map.number));
                    }

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