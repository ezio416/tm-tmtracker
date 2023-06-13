/*
c 2023-05-26
m 2023-06-13
*/

// Functions for rendering tabs in the interface
namespace Tabs {
    void AllAccounts() {
        if (!UI::BeginTabItem(Icons::User + " Accounts")) return;

        if (UI::Button(Icons::Download + " Get Account Names"))
            startnew(CoroutineFunc(Accounts::GetAccountNamesCoro));

        UI::SameLine();
        UI::Text("Total accounts: " + Globals::accounts.Length);

        UI::Separator();

        int flags =
            UI::TableFlags::ScrollY |
            UI::TableFlags::Resizable;

        if (UI::BeginTable("table_accounts", 4, flags)) {
            UI::TableSetupScrollFreeze(0, 1);
            UI::TableSetupColumn("ID");
            UI::TableSetupColumn("Name");
            UI::TableSetupColumn("Zone");
            UI::TableHeadersRow();

            UI::ListClipper clipper(Globals::accounts.Length);
            while (clipper.Step()) {
                for (int i = clipper.DisplayStart; i < clipper.DisplayEnd; i++) {
                    UI::TableNextRow();
                    UI::TableNextColumn();
                    UI::Text(Globals::accounts[i].accountId);
                    UI::TableNextColumn();
                    UI::Text(Globals::accounts[i].accountName);
                    UI::TableNextColumn();
                    UI::Text(Globals::accounts[i].zoneName);
                }
            }

            UI::EndTable();
        }

        UI::EndTabItem();
    }
}