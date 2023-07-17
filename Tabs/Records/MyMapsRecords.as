/*
c 2023-07-12
m 2023-07-16
*/

namespace Tabs { namespace Records {
    void Tab_MyMapsRecords() {
        if (!UI::BeginTabItem(Icons::MapO + " My Maps")) return;

        auto now = Time::Stamp;

        if (Settings::recordsEstimate)
            UI::TextWrapped(
                "Getting records for \\$F71" + Globals::shownMaps + " \\$Gmaps should take between \\$F71" +
                Util::FormatSeconds(uint(0.6 * Globals::shownMaps)) + " - " + Util::FormatSeconds(uint(1.8 * Globals::shownMaps)) +
                "\\$G.\nIt could be faster, but each map takes 2+ API requests and we don't want to spam." +
                "\nMaps with no records only take 1 request, and are therefore faster." +
                "\nIt will take longer if there are lots of records, lots of unique accounts, or if you have low framerate."
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
            UI::SameLine();
            UI::Text("Last Updated: " + (
                Globals::recordsTimestamp > 0 ?
                    Time::FormatString(Settings::dateFormat + "Local\\$G", Globals::recordsTimestamp) +
                        " (" + Util::FormatSeconds(now - Globals::recordsTimestamp) + " ago)" :
                    "never"
            ));
        }

        // Globals::recordsMapSearch = UI::InputText("search maps", Globals::recordsMapSearch, false);

        // Globals::recordsAccountSearch = UI::InputText("search accounts", Globals::recordsAccountSearch, false);

        if (UI::BeginTable("records-table", 6, UI::TableFlags::ScrollY)) {
            UI::TableSetupScrollFreeze(0, 1);
            UI::TableSetupColumn("Map");
            UI::TableSetupColumn("Pos", UI::TableColumnFlags::WidthFixed, 50);
            UI::TableSetupColumn("Time", UI::TableColumnFlags::WidthFixed, 100);
            UI::TableSetupColumn("Name", UI::TableColumnFlags::WidthFixed, 200);
            UI::TableSetupColumn("Timestamp " + Icons::ChevronDown, UI::TableColumnFlags::WidthFixed, 300);
            UI::TableSetupColumn("Recency " + Icons::ChevronDown, UI::TableColumnFlags::WidthFixed, 200);
            UI::TableHeadersRow();

            UI::ListClipper clipper(Globals::recordsSorted.Length);
            while (clipper.Step()) {
                for (int i = clipper.DisplayStart; i < clipper.DisplayEnd; i++) {
                    auto record = Globals::recordsSorted[i];
                    auto account = Globals::accounts.Length > 0 ? cast<Models::Account@>(Globals::accountsIndex[record.accountId]) : Models::Account();

                    // if (!record.mapName.ToLower().Contains(Globals::recordsMapSearch.ToLower())) continue;
                    // if (!account.accountName.ToLower().Contains(Globals::recordsAccountSearch.ToLower())) continue;

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
            UI::EndTable();
        }
        UI::EndTabItem();
    }
}}