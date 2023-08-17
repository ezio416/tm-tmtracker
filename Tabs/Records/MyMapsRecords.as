/*
c 2023-07-12
m 2023-08-16
*/

namespace Tabs { namespace Records {
    void Tab_MyMapsRecords() {
        if (!UI::BeginTabItem(Icons::MapO + " My Maps")) return;

        int64 now = Time::Stamp;

        if (Settings::recordsEstimate)
            UI::TextWrapped(
                "Getting records for \\$F71" + Globals::shownMaps + " \\$Gmaps should take between \\$F71" +
                Util::FormatSeconds(uint(1.2 * Globals::shownMaps)) + " - " + Util::FormatSeconds(uint(3.6 * Globals::shownMaps)) +
                "\\$G.\nIt could be shorter, but we don't want to spam Nadeo with API requests. This action does 2+ per map." +
                "\nIt will take longer if there are lots of records, lots of unique accounts, or if you have low framerate." +
                "\nMaps with no records are faster and hidden maps are skipped."
            );

        UI::BeginDisabled(Locks::allRecords);
        if (UI::Button(Icons::Download + " Get Records (" + Globals::records.Length + ")"))
            startnew(CoroutineFunc(Bulk::GetMyMapsRecordsCoro));
        UI::EndDisabled();

        if (Locks::allRecords && !Globals::cancelAllRecords) {
            UI::SameLine();
            if (UI::Button(Icons::Times + " Cancel"))
                Globals::cancelAllRecords = true;
        }

        if (!Locks::allRecords) {
            uint timestamp;
            try { timestamp = uint(Globals::recordsTimestampsIndex.Get("all")); } catch { timestamp = 0; }

            UI::SameLine();
            UI::Text("Last Updated: " + (
                timestamp > 0 ?
                    Time::FormatString(Settings::dateFormat + "Local\\$G", timestamp) +
                        " (" + Util::FormatSeconds(now - timestamp) + " ago)" :
                    "never"
            ));
        }

        if (UI::BeginTable("records-table", 6, UI::TableFlags::ScrollY | UI::TableFlags::RowBg)) {
            UI::PushStyleColor(UI::Col::TableRowBgAlt, Globals::tableRowBgAltColor);

            UI::TableSetupScrollFreeze(0, 1);
            UI::TableSetupColumn("Map");
            UI::TableSetupColumn("Pos",                             UI::TableColumnFlags::WidthFixed, Globals::scale * 35);
            UI::TableSetupColumn("Time",                            UI::TableColumnFlags::WidthFixed, Globals::scale * 80);
            UI::TableSetupColumn("Name",                            UI::TableColumnFlags::WidthFixed, Globals::scale * 150);
            UI::TableSetupColumn("Timestamp " + Icons::ChevronDown, UI::TableColumnFlags::WidthFixed, Globals::scale * 180);
            UI::TableSetupColumn("Recency "   + Icons::ChevronDown, UI::TableColumnFlags::WidthFixed, Globals::scale * 120);
            UI::TableHeadersRow();

            UI::ListClipper clipper(Globals::recordsSorted.Length);
            while (clipper.Step()) {
                for (int i = clipper.DisplayStart; i < clipper.DisplayEnd; i++) {
                    auto record = Globals::recordsSorted[i];
                    auto account = Globals::accounts.Length > 0 ? cast<Models::Account@>(Globals::accountsIndex[record.accountId]) : Models::Account();

                    UI::TableNextRow();
                    UI::TableNextColumn();
                    UI::Text(record.mapName);

                    UI::TableNextColumn();
                    UI::Text(((Settings::recordsHighlight5 && record.position < 6) ? "\\$" + Settings::recordsHighlightColor : "") + record.position);

                    UI::TableNextColumn();
                    string timeColor = "";
                    if (Settings::recordsMedalColors)
                        switch (record.medals) {
                            case 1: timeColor = "\\$C80"; break;
                            case 2: timeColor = "\\$AAA"; break;
                            case 3: timeColor = "\\$DD1"; break;
                            case 4: timeColor = "\\$4B0"; break;
                        }
                    UI::Text(timeColor + Time::Format(record.time));

                    UI::TableNextColumn();
                    UI::Text((account.accountName != "") ? account.accountName : account.accountId);

                    UI::TableNextColumn();
                    UI::Text(Time::FormatString("%Y-%m-%d %H:%M:%S \\$AAA(%a)", record.timestampUnix));

                    UI::TableNextColumn();
                    UI::Text(Util::FormatSeconds(now - record.timestampUnix));
                }
            }
            UI::PopStyleColor();
            UI::EndTable();
        }
        UI::EndTabItem();
    }
}}