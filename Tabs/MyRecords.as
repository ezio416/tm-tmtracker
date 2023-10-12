/*
c 2023-10-09
m 2023-10-11
*/

namespace Tabs {
    void Tab_MyRecords() {
        if (!UI::BeginTabItem(Icons::Trophy + " My Records"))
            return;

        if (Settings::myRecordsText)
            UI::TextWrapped(
                "This tab shows records you've driven on any map."
            );

        UI::BeginDisabled(Locks::myRecords || Locks::mapInfo);
        if (UI::Button(Icons::Download + " Get Records (" + Globals::myRecords.Length +")"))
            startnew(CoroutineFunc(Bulk::GetMyRecordsCoro));
        UI::EndDisabled();

        int flags = UI::TableFlags::Resizable |
                    UI::TableFlags::RowBg |
                    UI::TableFlags::ScrollY;

        if (UI::BeginTable("my-records", 5, flags)) {
            UI::PushStyleColor(UI::Col::TableRowBgAlt, Globals::tableRowBgAltColor);

            UI::TableSetupScrollFreeze(0, 1);
            UI::TableSetupColumn("map");
            UI::TableSetupColumn("time");
            UI::TableSetupColumn("AT");
            UI::TableSetupColumn("delta to AT");
            UI::TableSetupColumn("timestamp");
            UI::TableHeadersRow();

            UI::ListClipper clipper(Globals::myRecords.Length);
            while (clipper.Step()) {
                for (int i = clipper.DisplayStart; i < clipper.DisplayEnd; i++) {
                    Models::Record@ record = @Globals::myRecords[i];
                    Models::Map@ map;

                    UI::TableNextRow();
                    UI::TableNextColumn();
                    if (Globals::myRecordsMapsDict.Exists(record.mapId)) {
                        @map = cast<Models::Map@>(Globals::myRecordsMapsDict[record.mapId]);
                        UI::Text(map.mapNameText);
                    } else
                        UI::Text(record.mapId);

                    UI::TableNextColumn();
                    string color = "\\$";
                    switch (record.medals) {
                        case 1:  color += Globals::colorBronze; break;
                        case 2:  color += Globals::colorSilver; break;
                        case 3:  color += Globals::colorGold;   break;
                        case 4:  color += Globals::colorAuthor; break;
                        default: color += "G";
                    }
                    UI::Text(color + Time::Format(record.time));

                    UI::TableNextColumn();
                    if (Globals::myRecordsMapsDict.Exists(record.mapId)) {
                        UI::Text(Time::Format(map.authorTime));
                    } else
                        UI::Text("unknown");

                    UI::TableNextColumn();
                    if (Globals::myRecordsMapsDict.Exists(record.mapId)) {
                        int delta = int(map.authorTime) - int(record.time);
                        string deltaStr = (delta > 0) ? "\\$0F0-" : "\\$F00+";
                        UI::Text(deltaStr + Time::Format(Math::Abs(delta)));
                    } else
                        UI::Text("unknown");

                    UI::TableNextColumn();
                    UI::Text(record.timestampIso);
                }
            }

            UI::PopStyleColor();
            UI::EndTable();
        }

        UI::EndTabItem();
    }
}