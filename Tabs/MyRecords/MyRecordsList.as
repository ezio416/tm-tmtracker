/*
c 2023-10-11
m 2023-10-12
*/

namespace Tabs { namespace MyRecords {
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

        Globals::myRecordsMapsSearch = UI::InputText("search maps", Globals::myRecordsMapsSearch, false);

        if (Globals::myRecordsMapsSearch != "") {
            UI::SameLine();
            if (UI::Button(Icons::Times + " Clear Search"))
                Globals::myRecordsMapsSearch = "";
        }

        Table_MyRecordsList(now);

        UI::EndTabItem();
    }

    void Table_MyRecordsList(int64 now) {
        Models::Record@[] records;

        if (Globals::myRecordsMapsSearch == "")
            records = Globals::myRecordsSorted;
        else {
            for (uint i = 0; i < Globals::myRecordsSorted.Length; i++) {
                Models::Record@ record = Globals::myRecordsSorted[i];

                if (record.mapNameText.ToLower().Contains(Globals::myRecordsMapsSearch.ToLower()))
                    records.InsertLast(record);
            }
        }

        int flags = UI::TableFlags::RowBg |
                    UI::TableFlags::ScrollY;

        if (UI::BeginTable("my-records", 7, flags)) {
            UI::PushStyleColor(UI::Col::TableRowBgAlt, Globals::colorTableRowBgAlt);

            UI::TableSetupScrollFreeze(0, 1);
            UI::TableSetupColumn("Map");
            UI::TableSetupColumn("Author",                          UI::TableColumnFlags::WidthFixed, Globals::scale * 120);
            UI::TableSetupColumn("AT",                              UI::TableColumnFlags::WidthFixed, Globals::scale * 80);
            UI::TableSetupColumn("PB",                              UI::TableColumnFlags::WidthFixed, Globals::scale * 80);
            UI::TableSetupColumn("\u0394 to AT",                    UI::TableColumnFlags::WidthFixed, Globals::scale * 80);
            UI::TableSetupColumn("Timestamp " + Icons::ChevronDown, UI::TableColumnFlags::WidthFixed, Globals::scale * 180);
            UI::TableSetupColumn("Recency "   + Icons::ChevronDown, UI::TableColumnFlags::WidthFixed, Globals::scale * 120);
            UI::TableHeadersRow();

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
                    UI::Text(map is null ? "unknown" : Globals::colorMedalAuthor + Time::Format(map.authorTime));

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
                    UI::Text(map is null ? "unknown" : Util::TimeFormatColored(int(record.time) - int(map.authorTime)));

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