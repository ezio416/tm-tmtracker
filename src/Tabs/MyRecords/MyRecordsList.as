// c 2023-10-11
// m 2023-12-26

namespace Tabs { namespace MyRecords {
    string mapSearch;

    void Tab_MyRecordsList() {
        if (!UI::BeginTabItem(Icons::ListUl + " Record List (" + Globals::myRecords.Length + ")###my-records-list"))
            return;

        if (Settings::myRecordsText)
            UI::TextWrapped(
                "This tab shows records you've driven on any map, sorted by when you drove them." +
                "\nClick on a record to add it to the \"Viewing Maps\" tab above."
            );

        UI::BeginDisabled(Locks::myRecords || Locks::mapInfo);
        if (UI::Button(Icons::Download + " Get My Records"))
            startnew(CoroutineFunc(Bulk::GetMyRecordsCoro));
        UI::EndDisabled();

        int64 now = Time::Stamp;

        if (!Locks::myRecords) {
            uint timestamp;

            if (Globals::myRecordsMaps.Length == 0)
                timestamp = 0;
            else
                try {
                    timestamp = uint(Globals::recordsTimestampsJson.Get("myRecords"));
                } catch {
                    timestamp = 0;
                }

            UI::SameLine();
            UI::Text("Last Updated: " + (
                timestamp > 0 ?
                    Time::FormatString(Globals::dateFormat + "Local\\$G", timestamp) +
                        " (" + Util::FormatSeconds(now - timestamp) + " ago)" :
                    "never"
            ));
        }

        if (Settings::myRecordsSearch) {
            mapSearch = UI::InputText("search maps", mapSearch, false);

            if (mapSearch != "") {
                UI::SameLine();
                if (UI::Button(Icons::Times + " Clear Search"))
                    mapSearch = "";
            }
        } else
            mapSearch = "";

        Table_MyRecordsList(now);

        UI::EndTabItem();
    }

    void Table_MyRecordsList(int64 now) {
        Models::Record@[] records;

        if (mapSearch == "")
            records = Globals::myRecordsSorted;
        else {
            string mapSearchLower = mapSearch.ToLower();

            for (uint i = 0; i < Globals::myRecordsSorted.Length; i++) {
                Models::Record@ record = Globals::myRecordsSorted[i];

                if (record.mapNameText.ToLower().Contains(mapSearchLower))
                    records.InsertLast(record);
            }
        }

        int flags = UI::TableFlags::RowBg |
                    UI::TableFlags::ScrollY |
                    UI::TableFlags::Sortable;

        if (UI::BeginTable("my-records", 7, flags)) {
            UI::PushStyleColor(UI::Col::TableRowBgAlt, Globals::colorTableRowBgAlt);

            int fixed = UI::TableColumnFlags::WidthFixed;
            int noSort = UI::TableColumnFlags::NoSort;
            int fixedNoSort = fixed | noSort;

            UI::TableSetupScrollFreeze(0, 1);
            UI::TableSetupColumn("Map",          (Locks::mapInfo ? noSort : 0));
            UI::TableSetupColumn("Author",       fixedNoSort,                            Globals::scale * 120);
            UI::TableSetupColumn("AT",           (Locks::mapInfo ? fixedNoSort : fixed), Globals::scale * 80);
            UI::TableSetupColumn("PB",           fixed,                                  Globals::scale * 80);
            UI::TableSetupColumn("\u0394 to AT", (Locks::mapInfo ? fixedNoSort : fixed), Globals::scale * 80);
            UI::TableSetupColumn("Timestamp",    fixed,                                  Globals::scale * 180);
            UI::TableSetupColumn("Recency",      fixedNoSort,                            Globals::scale * 120);
            UI::TableHeadersRow();

            UI::TableSortSpecs@ tableSpecs = UI::TableGetSortSpecs();

            if (tableSpecs !is null && tableSpecs.Dirty) {
                UI::TableColumnSortSpecs[]@ colSpecs = tableSpecs.Specs;

                if (colSpecs !is null && colSpecs.Length > 0) {
                    switch (colSpecs[0].ColumnIndex) {
                        case 0:  // map
                            switch (colSpecs[0].SortDirection) {
                                case UI::SortDirection::Ascending:  Settings::myRecordsSortMethod = Sort::SortMethod::RecordsMapsAlpha;    break;
                                case UI::SortDirection::Descending: Settings::myRecordsSortMethod = Sort::SortMethod::RecordsMapsAlphaRev; break;
                                default:;
                            }
                            break;
                        case 2:  // AT
                            switch (colSpecs[0].SortDirection) {
                                case UI::SortDirection::Ascending:  Settings::myRecordsSortMethod = Sort::SortMethod::RecordsWorstAuthorFirst; break;
                                case UI::SortDirection::Descending: Settings::myRecordsSortMethod = Sort::SortMethod::RecordsBestAuthorFirst;  break;
                                default:;
                            }
                            break;
                        case 3:  // PB
                            switch (colSpecs[0].SortDirection) {
                                case UI::SortDirection::Ascending:  Settings::myRecordsSortMethod = Sort::SortMethod::RecordsBestFirst;  break;
                                case UI::SortDirection::Descending: Settings::myRecordsSortMethod = Sort::SortMethod::RecordsWorstFirst; break;
                                default:;
                            }
                            break;
                        case 4:  // delta
                            switch (colSpecs[0].SortDirection) {
                                case UI::SortDirection::Ascending:  Settings::myRecordsSortMethod = Sort::SortMethod::RecordsWorstDeltaFirst; break;
                                case UI::SortDirection::Descending: Settings::myRecordsSortMethod = Sort::SortMethod::RecordsBestDeltaFirst;  break;
                                default:;
                            }
                            break;
                        case 5:  // timestamp
                            switch (colSpecs[0].SortDirection) {
                                case UI::SortDirection::Ascending:  Settings::myRecordsSortMethod = Sort::SortMethod::RecordsOldFirst; break;
                                case UI::SortDirection::Descending: Settings::myRecordsSortMethod = Sort::SortMethod::RecordsNewFirst; break;
                                default:;
                            }
                            break;
                        default:;
                    }

                    startnew(Sort::MyRecordsCoro);
                }

                tableSpecs.Dirty = false;
            }

            UI::ListClipper clipper(records.Length);
            while (clipper.Step()) {
                for (int i = clipper.DisplayStart; i < clipper.DisplayEnd; i++) {
                    Models::Record@ record = records[i];
                    Models::Map@ map;

                    UI::TableNextRow();
                    UI::TableNextColumn();
                    if (Globals::myRecordsMapsDict.Exists(record.mapId)) {
                        @map = cast<Models::Map@>(Globals::myRecordsMapsDict[record.mapId]);
                        if (UI::Selectable((Settings::mapNameColors ? map.mapNameColor : map.mapNameText), false, UI::SelectableFlags::SpanAllColumns))
                            Globals::AddMyRecordsMapViewing(map);
                    } else
                        UI::Text(record.mapId);

                    UI::TableNextColumn();
                    if (map !is null && Globals::accountsDict.Exists(map.authorId)) {
                        Models::Account@ account = cast<Models::Account@>(Globals::accountsDict[map.authorId]);
                        UI::Text(account.accountName == "" ? account.accountId : account.accountName);
                    } else
                        UI::Text("unknown");

                    UI::TableNextColumn();
                    UI::Text(map is null ? "unknown" : Globals::colorMedalAuthor + Time::Format(record.mapAuthorTime));

                    UI::TableNextColumn();
                    string color;
                    if (Settings::medalColors)
                        switch (record.medals) {
                            case 1:  color = Globals::colorMedalBronze; break;
                            case 2:  color = Globals::colorMedalSilver; break;
                            case 3:  color = Globals::colorMedalGold;   break;
                            case 4:  color = Globals::colorMedalAuthor; break;
                            default: color = Globals::colorMedalNone;
                        }
                    UI::Text(color + Time::Format(record.time));

                    UI::TableNextColumn();
                    UI::Text(map is null ? "unknown" : Util::TimeFormatColored(record.mapAuthorDelta));

                    UI::TableNextColumn();
                    UI::Text(Util::UnixToIso(record.timestampUnix));

                    UI::TableNextColumn();
                    UI::Text(Util::FormatSeconds(now - record.timestampUnix));
                }
            }

            UI::PopStyleColor();
            UI::EndTable();
        }
    }
}}