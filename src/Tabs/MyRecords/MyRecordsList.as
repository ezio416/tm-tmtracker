// c 2023-10-11
// m 2023-12-26

namespace Tabs { namespace MyRecords {
    string authorSearch;
    string mapSearch;

    void Tab_MyRecordsList() {
        if (!UI::BeginTabItem(Icons::ListUl + " Records (" + Globals::myRecords.Length + ")###my-records-list"))
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
                    Time::FormatString(Globals::dateFormat, timestamp) +
                        " (" + Util::FormatSeconds(now - timestamp) + " ago)" :
                    "never"
            ));
        }

        if (Settings::myRecordsMapSearch) {
            mapSearch = UI::InputText("search maps", mapSearch, false);

            if (mapSearch != "") {
                UI::SameLine();
                if (UI::Button(Icons::Times + " Clear Search##mapSearch"))
                    mapSearch = "";
            }
        } else
            mapSearch = "";

        if (Settings::myRecordsAuthorSearch) {
            authorSearch = UI::InputText("search authors", authorSearch, false);

            if (authorSearch != "") {
                UI::SameLine();
                if (UI::Button(Icons::Times + " Clear Search##authorSearch"))
                    authorSearch = "";
            }
        } else
            authorSearch = "";

        Table_MyRecordsList(now);

        UI::EndTabItem();
    }

    void Table_MyRecordsList(int64 now) {
        Models::Record@[] records;

        if (mapSearch == "" && authorSearch == "")
            records = Globals::myRecordsSorted;
        else {
            string mapSearchLower = mapSearch.ToLower();
            string authorSearchLower = authorSearch.ToLower();

            for (uint i = 0; i < Globals::myRecordsSorted.Length; i++) {
                Models::Record@ record = Globals::myRecordsSorted[i];

                Models::Account@ account;
                if (record.mapAuthorName == "" && Globals::accounts.Length > 0 && Globals::accountsDict.Exists(record.mapAuthorId)) {
                    @account = cast<Models::Account@>(Globals::accountsDict[record.mapAuthorId]);
                    record.mapAuthorName = account.accountName;
                }

                if (
                    (mapSearchLower == "" || (mapSearchLower != "" && record.mapNameText.ToLower().Contains(mapSearchLower))) &&
                    (authorSearchLower == "" || (authorSearchLower != "" && record.mapAuthorName.ToLower().Contains(authorSearchLower)))
                )
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
            UI::TableSetupColumn("Author",       (Locks::mapInfo ? fixedNoSort : fixed), Globals::scale * 120);
            UI::TableSetupColumn("AT",           (Locks::mapInfo ? fixedNoSort : fixed), Globals::scale * 80);
            UI::TableSetupColumn("PB",           fixed,                                  Globals::scale * 80);
            UI::TableSetupColumn("\u0394 to AT", (Locks::mapInfo ? fixedNoSort : fixed), Globals::scale * 80);
            UI::TableSetupColumn("Timestamp",    fixed,                                  Globals::scale * 180);
            UI::TableSetupColumn("Recency",      fixed,                                  Globals::scale * 120);
            UI::TableHeadersRow();

            UI::TableSortSpecs@ tableSpecs = UI::TableGetSortSpecs();

            if (tableSpecs !is null && tableSpecs.Dirty) {
                UI::TableColumnSortSpecs[]@ colSpecs = tableSpecs.Specs;

                if (colSpecs !is null && colSpecs.Length > 0) {
                    bool ascending = colSpecs[0].SortDirection == UI::SortDirection::Ascending;

                    switch (colSpecs[0].ColumnIndex) {
                        case 0:  // map
                            Settings::myRecordsSortMethod = ascending ? Sort::Records::SortMethod::MapsAlpha : Sort::Records::SortMethod::MapsAlphaRev;
                            break;
                        case 1:  // author
                            for (uint i = 0; i < Globals::myRecords.Length; i++) {
                                Models::Record@ record = @Globals::myRecords[i];
                                if (record.mapAuthorName == "" && Globals::accounts.Length > 0 && Globals::accountsDict.Exists(record.mapAuthorId)) {
                                    Models::Account@ account = cast<Models::Account@>(Globals::accountsDict[record.mapAuthorId]);
                                    record.mapAuthorName = account.accountName;
                                }
                            }
                            Settings::myRecordsSortMethod = ascending ? Sort::Records::SortMethod::MapAuthorsAlpha : Sort::Records::SortMethod::MapAuthorsAlphaRev;
                            break;
                        case 2:  // AT
                            Settings::myRecordsSortMethod = ascending ? Sort::Records::SortMethod::WorstAuthorFirst : Sort::Records::SortMethod::BestAuthorFirst;
                            break;
                        case 3:  // PB
                            Settings::myRecordsSortMethod = ascending ? Sort::Records::SortMethod::BestFirst : Sort::Records::SortMethod::WorstFirst;
                            break;
                        case 4:  // delta
                            Settings::myRecordsSortMethod = ascending ? Sort::Records::SortMethod::WorstDeltaFirst : Sort::Records::SortMethod::BestDeltaFirst;
                            break;
                        case 5:  // timestamp
                            Settings::myRecordsSortMethod = ascending ? Sort::Records::SortMethod::OldFirst : Sort::Records::SortMethod::NewFirst;
                            break;
                        case 6:  // recency
                            Settings::myRecordsSortMethod = ascending ? Sort::Records::SortMethod::NewFirst : Sort::Records::SortMethod::OldFirst;
                            break;
                        default:;
                    }

                    if (Globals::myRecords.Length > 0)
                        startnew(Sort::Records::MyRecordsCoro);
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