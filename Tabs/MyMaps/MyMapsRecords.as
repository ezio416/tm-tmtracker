/*
c 2023-07-12
m 2023-10-11
*/

namespace Tabs { namespace MyMaps {
    void Tab_MyMapsRecords() {
        if (!UI::BeginTabItem(Icons::Trophy + " Records (" + Globals::records.Length + ")###my-maps-records"))
            return;

        int64 now = Time::Stamp;

        if (Settings::recordsEstimate)
            UI::TextWrapped(
                "Getting records for \\$F71" + Globals::shownMaps + " \\$Gmaps should take between \\$F71" +
                Util::FormatSeconds(uint(1.2 * Globals::shownMaps)) + " - " + Util::FormatSeconds(uint(3.6 * Globals::shownMaps)) +
                "\\$G.\nIt could be shorter, but we don't want to spam Nadeo with API requests. This action does 2+ per map." +
                "\nIt will take longer if there are lots of records, lots of unique accounts, or if you have low framerate." +
                "\nMaps with no records are faster and hidden maps are skipped." +
                "\nClick on a map name to add it to the \"Viewing\" tab above."
            );

        UI::BeginDisabled(Locks::allRecords);
        if (UI::Button(Icons::Download + " Get All Records"))
            startnew(CoroutineFunc(Bulk::GetMyMapsRecordsCoro));
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
                    Time::FormatString(Globals::dateFormat + "Local\\$G", timestamp) +
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
                    Models::Record@ record = Globals::recordsSorted[i];
                    Models::Account@ account = Globals::accounts.Length > 0 ? cast<Models::Account@>(Globals::accountsDict[record.accountId]) : Models::Account();

                    UI::TableNextRow();
                    UI::TableNextColumn();
                    if (UI::Selectable(record.mapName + "##" + i, false))
                        Globals::AddViewingMap(cast<Models::Map@>(Globals::mapsDict[record.mapId]));

                    UI::TableNextColumn();
                    UI::Text(((Settings::recordsHighlight5 && record.position < 6) ? "\\$" + Settings::recordsHighlightColor : "") + record.position);

                    UI::TableNextColumn();
                    string timeColor = "";
                    if (Settings::recordsMedalColor)
                        switch (record.medals) {
                            case 1: timeColor = Globals::colorBronze; break;
                            case 2: timeColor = Globals::colorSilver; break;
                            case 3: timeColor = Globals::colorGold;   break;
                            case 4: timeColor = Globals::colorAuthor; break;
                        }
                    UI::Text(timeColor + Time::Format(record.time));

                    UI::TableNextColumn();
                    if (UI::Selectable((account.accountName.Length > 0 ? account.accountName : account.accountId) + "##" + i, false))
                        Util::TmioPlayer(account.accountId);
                    Util::HoverTooltip("Trackmania.io profile");

                    UI::TableNextColumn();
                    UI::Text(Util::UnixToIso(record.timestampUnix));

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