/*
c 2023-07-12
m 2023-07-12
*/

namespace Tabs { namespace Records {
    void Tab_MyMapsRecords() {
        if (!UI::BeginTabItem(Icons::MapO + " My Maps")) return;

        int flags =
            UI::TableFlags::Resizable |
            UI::TableFlags::ScrollY;

        // if (UI::BeginTable("records-table", 8, flags)) {
        //     UI::TableSetupScrollFreeze(0, 1);
        //     UI::TableSetupColumn("Map");
        //     UI::TableSetupColumn("Account");
        //     UI::TableSetupColumn("Time");
        //     UI::TableSetupColumn("Medals");
        //     UI::TableSetupColumn("Position");
        //     UI::TableSetupColumn("RecordId");
        //     UI::TableSetupColumn("TimestampIso");
        //     UI::TableSetupColumn("TimestampUnix");
        //     UI::TableHeadersRow();

        //     UI::ListClipper clipper(recordsSorted.Length);
        //     while (clipper.Step()) {
        //         for (int i = clipper.DisplayStart; i < clipper.DisplayEnd; i++) {
        //             auto record = @recordsSorted[i];
        //             auto account = cast<Models::Account@>(Globals::accountsIndex[record.accountId]);

        //             UI::TableNextRow();
        //             UI::TableNextColumn();
        //             UI::Text(record.mapName);
        //             UI::TableNextColumn();
        //             UI::Text((account.accountName != "") ? account.accountName : account.accountId);
        //             UI::TableNextColumn();
        //             UI::Text("" + record.time);
        //             UI::TableNextColumn();
        //             UI::Text("" + record.medals);
        //             UI::TableNextColumn();
        //             UI::Text("" + record.position);
        //             UI::TableNextColumn();
        //             UI::Text(record.recordId);
        //             UI::TableNextColumn();
        //             UI::Text(record.timestampIso);
        //             UI::TableNextColumn();
        //             UI::Text("" + record.timestampUnix);
        //         }
        //     }

        //     UI::EndTable();
        // }


        UI::EndTabItem();
    }
}}