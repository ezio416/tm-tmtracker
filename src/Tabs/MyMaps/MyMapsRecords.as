// c 2023-07-12
// m 2024-01-19

namespace Tabs { namespace MyMaps {
    string accountSearch;
    string myMapsRecordsMapSearch;
    uint   myMapsRecordsResults = 0;

    void Tab_MyMapsRecords() {
        if (!UI::BeginTabItem(Icons::Trophy + " Records (" + Globals::myMapsRecords.Length + ")###my-maps-records"))
            return;

        int64 now = Time::Stamp;

        if (Settings::recordsEstimate)
            UI::TextWrapped(
                "Getting records for \\$F71" + Globals::shownMaps + " \\$Gmaps should take between \\$F71" +
                Util::FormatSeconds(uint(1.2 * Globals::shownMaps)) + " - " + Util::FormatSeconds(uint(3.6 * Globals::shownMaps)) +
                "\\$G.\nIt could be shorter, but we don't want to spam Nadeo with API requests. This action does 2+ per map." +
                "\nIt will take longer if there are lots of records, lots of unique accounts, or if you have low framerate." +
                "\nMaps with no records are faster and hidden maps are skipped." +
                "\nClick on a map name to add it to the \"Viewing Maps\" tab above." +
                "\nClick on an account name to open their Trackmania.io page."
            );

        UI::BeginDisabled(Locks::allRecords);
        if (UI::Button(Icons::Download + " Get My Maps' Records"))
            startnew(Bulk::GetMyMapsRecordsCoro);
        UI::EndDisabled();

        UI::BeginDisabled(!Locks::allRecords || Globals::cancelAllRecords);
        UI::SameLine();
        if (UI::Button(Icons::Times + " Cancel"))
            Globals::cancelAllRecords = true;
        UI::EndDisabled();

        if (!Locks::allRecords) {
            uint timestamp;
            try {
                timestamp = uint(Globals::recordsTimestampsJson.Get("myMaps"));
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

        if (Settings::myMapsRecordsMapSearch) {
            myMapsRecordsMapSearch = UI::InputText("search maps", myMapsRecordsMapSearch, false);

            if (myMapsRecordsMapSearch != "") {
                UI::SameLine();
                if (UI::Button(Icons::Times + " Clear Search##mapSearch"))
                    myMapsRecordsMapSearch = "";

                UI::SameLine();
                UI::Text(myMapsRecordsResults + " results");
            }
        } else
            myMapsRecordsMapSearch = "";

        if (Settings::myMapsRecordsAccountSearch) {
            accountSearch = UI::InputText("search accounts", accountSearch, false);

            if (accountSearch != "") {
                UI::SameLine();
                if (UI::Button(Icons::Times + " Clear Search##accountSearch"))
                    accountSearch = "";

                UI::SameLine();
                UI::Text(myMapsRecordsResults + " results");
            }
        } else
            accountSearch = "";

        Table_MyMapsRecords(now);

        UI::EndTabItem();
    }

    void Table_MyMapsRecords(int64 now) {
        Models::Record@[] records;

        if (myMapsRecordsMapSearch == "" && accountSearch == "")
            records = Globals::myMapsRecordsSorted;
        else {
            string mapSearchLower = myMapsRecordsMapSearch.ToLower();
            string accountSearchLower = accountSearch.ToLower();

            for (uint i = 0; i < Globals::myMapsRecordsSorted.Length; i++) {
                Models::Record@ record = Globals::myMapsRecordsSorted[i];

                Models::Account@ account;
                if (record.accountName == "" && Globals::accounts.Length > 0 && Globals::accountsDict.Exists(record.accountId)) {
                    @account = cast<Models::Account@>(Globals::accountsDict[record.accountId]);
                    record.accountName = account.accountName;
                }

                if (
                    (mapSearchLower == "" || (mapSearchLower != "" && record.mapNameText.ToLower().Contains(mapSearchLower))) &&
                    (accountSearchLower == "" || (accountSearchLower != "" && record.accountName.ToLower().Contains(accountSearchLower)))
                )
                    records.InsertLast(record);
            }
        }

        myMapsRecordsResults = records.Length;

        int colCount = 2;
        if (Settings::myMapsRecordsColPos)       colCount++;
        if (Settings::myMapsRecordsColTime)      colCount++;
        if (Settings::myMapsRecordsColTimestamp) colCount++;
        if (Settings::myMapsRecordsColRecency)   colCount++;

        int flags = UI::TableFlags::RowBg |
                    UI::TableFlags::ScrollY |
                    UI::TableFlags::Sortable;

        if (UI::BeginTable("my-maps-records", colCount, flags)) {
            UI::PushStyleColor(UI::Col::TableRowBgAlt, Globals::colorTableRowBgAlt);

            int fixed = UI::TableColumnFlags::WidthFixed;
            int noSort = UI::TableColumnFlags::NoSort;
            int fixedNoSort = fixed | noSort;

            UI::TableSetupScrollFreeze(0, 1);
                                                     UI::TableSetupColumn("Map");
            if (Settings::myMapsRecordsColPos)       UI::TableSetupColumn("Pos",       fixed,                                                            Globals::scale * 35);
            if (Settings::myMapsRecordsColTime)      UI::TableSetupColumn("Time",      fixed,                                                            Globals::scale * 75);
                                                     UI::TableSetupColumn("Account",   (Locks::accountNames || Locks::allRecords ? fixedNoSort : fixed), Globals::scale * 150);
            if (Settings::myMapsRecordsColTimestamp) UI::TableSetupColumn("Timestamp", fixed,                                                            Globals::scale * 185);
            if (Settings::myMapsRecordsColRecency)   UI::TableSetupColumn("Recency",   fixed,                                                            Globals::scale * 125);
            UI::TableHeadersRow();

            UI::TableSortSpecs@ tableSpecs = UI::TableGetSortSpecs();

            if (tableSpecs !is null && tableSpecs.Dirty) {
                UI::TableColumnSortSpecs[]@ colSpecs = tableSpecs.Specs;

                if (colSpecs !is null && colSpecs.Length > 0) {
                    bool ascending = colSpecs[0].SortDirection == UI::SortDirection::Ascending;

                    int colTime = 1;
                    int colAccount = 1;
                    int colTimestamp = 2;
                    int colRecency = 2;

                    if (Settings::myMapsRecordsColPos) {
                        colTime++;
                        colAccount++;
                        colTimestamp++;
                        colRecency++;
                    }

                    if (Settings::myMapsRecordsColTime) {
                        colAccount++;
                        colTimestamp++;
                        colRecency++;
                    }

                    if (Settings::myMapsRecordsColTimestamp)
                        colRecency++;

                    if (colSpecs[0].ColumnIndex == 0)
                        Settings::myMapsRecordsSortMethod = ascending ? Sort::Records::SortMethod::MapsAlpha : Sort::Records::SortMethod::MapsAlphaRev;
                    else if (Settings::myMapsRecordsColPos && colSpecs[0].ColumnIndex == 1)
                        Settings::myMapsRecordsSortMethod = ascending ? Sort::Records::SortMethod::WorstPosFirst : Sort::Records::SortMethod::BestPosFirst;
                    else if (Settings::myMapsRecordsColTime && colSpecs[0].ColumnIndex == colTime)
                        Settings::myMapsRecordsSortMethod = ascending ? Sort::Records::SortMethod::BestFirst : Sort::Records::SortMethod::WorstFirst;
                    else if (colSpecs[0].ColumnIndex == colAccount) {
                        for (uint i = 0; i < records.Length; i++) {
                            Models::Record@ record = records[i];
                            if (record.accountName == "" && Globals::accounts.Length > 0 && Globals::accountsDict.Exists(record.accountId)) {
                                Models::Account@ account = cast<Models::Account@>(Globals::accountsDict[record.accountId]);
                                record.accountName = account.accountName;
                            }
                        }
                        Settings::myMapsRecordsSortMethod = ascending ? Sort::Records::SortMethod::AccountsAlpha : Sort::Records::SortMethod::AccountsAlphaRev;
                    } else if (Settings::myMapsRecordsColTimestamp && colSpecs[0].ColumnIndex == colTimestamp)
                        Settings::myMapsRecordsSortMethod = ascending ? Sort::Records::SortMethod::OldFirst : Sort::Records::SortMethod::NewFirst;
                    else if (Settings::myMapsRecordsColRecency && colSpecs[0].ColumnIndex == colRecency)
                        Settings::myMapsRecordsSortMethod = ascending ? Sort::Records::SortMethod::NewFirst : Sort::Records::SortMethod::OldFirst;

                    Sort::Records::dbSave = false;
                    startnew(Sort::Records::MyMapsRecordsCoro);
                }

                tableSpecs.Dirty = false;
            }

            UI::ListClipper clipper(records.Length);
            while (clipper.Step()) {
                for (int i = clipper.DisplayStart; i < clipper.DisplayEnd; i++) {
                    Models::Record@ record = records[i];
                    Models::Account@ account = Globals::accounts.Length > 0 ? cast<Models::Account@>(Globals::accountsDict[record.accountId]) : Models::Account();

                    UI::TableNextRow();
                    UI::TableNextColumn();
                    if (UI::Selectable((Settings::mapNameColors ? record.mapNameColor : record.mapNameText) + "##" + i, false))
                        Globals::AddMyMapViewing(cast<Models::Map@>(Globals::myMapsDict[record.mapId]));

                    if (Settings::myMapsRecordsColPos) {
                        UI::TableNextColumn();
                        UI::Text(((Settings::highlightTop5 && record.position < 6) ? Globals::colorTop5 : "") + record.position);
                    }

                    if (Settings::myMapsRecordsColTime) {
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
                    }

                    UI::TableNextColumn();
                    if (UI::Selectable((account.accountName.Length > 0 ? account.accountName : "\\$888" + account.accountId) + "##" + i, false))
                        Util::TmioPlayer(account.accountId);

                    if (Settings::myMapsRecordsColTimestamp) {
                        UI::TableNextColumn();
                        UI::Text(Util::UnixToIso(record.timestampUnix));
                    }

                    if (Settings::myMapsRecordsColRecency) {
                        UI::TableNextColumn();
                        UI::Text(Util::FormatSeconds(now - record.timestampUnix));
                    }
                }
            }

            UI::PopStyleColor();
            UI::EndTable();
        }
    }
}}
