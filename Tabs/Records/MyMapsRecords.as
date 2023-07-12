/*
c 2023-07-12
m 2023-07-12
*/

namespace Tabs { namespace Records {
    void Tab_MyMapsRecords() {
        if (!UI::BeginTabItem(Icons::MapO + " My Maps")) return;

        auto now = Time::Stamp;

        if (UI::Button(Icons::Download + " Get All Records"))
            startnew(CoroutineFunc(Bulk::GetMyMapsRecordsCoro));

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
                    "not yet"
            ));
        }

        uint low = uint(0.6 * Globals::shownMaps);
        uint lowMin = low / 60;
        uint lowSec = low % 60;
        uint high = uint(1.5 * Globals::shownMaps);
        uint highMin = high / 60;
        uint highSec = high % 60;
        UI::TextWrapped(
            "Getting records for \\$2F2" + Globals::shownMaps + " \\$Gmaps should take between \\$2F2" +
            lowMin + "m" + lowSec + "s - " + highMin + "m" + highSec +
            "s\\$G.\nIt could be faster, but each map takes 2+ API requests and we don't want to spam." +
            "\nTask will take longer if:\n - your maps have lots of records\n - there are lots of unique accounts\n - you have low framerate"
        );

        int flags =
            // UI::TableFlags::Resizable |
            UI::TableFlags::ScrollY;

        if (UI::BeginTable("records-table", 5, flags)) {

            UI::TableSetupScrollFreeze(0, 1);
            UI::TableSetupColumn("Pos", UI::TableColumnFlags::WidthFixed, 30);
            UI::TableSetupColumn("Map");
            UI::TableSetupColumn("Account");
            UI::TableSetupColumn("Timestamp " + Icons::ChevronDown);
            UI::TableSetupColumn("Recency " + Icons::ChevronDown);
            UI::TableHeadersRow();

            UI::ListClipper clipper(Globals::recordsSorted.Length);
            while (clipper.Step()) {
                for (int i = clipper.DisplayStart; i < clipper.DisplayEnd; i++) {
                    auto record = Globals::recordsSorted[i];
                    auto account = Globals::accounts.Length > 0 ? cast<Models::Account@>(Globals::accountsIndex[record.accountId]) : Models::Account();

                    UI::TableNextRow();
                    UI::TableNextColumn();
                    UI::Text(((Settings::recordsHighlight5 && record.position < 6) ? "\\$1D4" : "") + record.position);
                    UI::TableNextColumn();
                    UI::Text(record.mapName);
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