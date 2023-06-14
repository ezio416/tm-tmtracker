/*
c 2023-05-26
m 2023-06-13
*/

// Functions for rendering tabs in the interface
namespace Tabs {
    void Dev() {
        if (!UI::BeginTabItem(Icons::Cogs + " Dev")) return;

        UI::TextWrapped(
            "I take no responsibility if you break shit in here!" +
            "\nThis is all debug stuff and could get you banned."
        );

        UI::SameLine();
        Thing_LockDevButton();

        UI::Separator();

        if (UI::Button(Icons::FloppyO + " save records"))
            startnew(CoroutineFunc(DB::Records::SaveCoro));

        UI::SameLine();
        if (UI::Button(Icons::Upload + " load records"))
            startnew(CoroutineFunc(DB::Records::LoadCoro));

        UI::SameLine();
        if (UI::Button(Icons::Times + " clear records"))
            DB::Records::Clear();

        UI::SameLine();
        if (UI::Button(Icons::Download + " get records"))
            startnew(CoroutineFunc(Maps::GetMyMapsRecordsCoro));

        UI::SameLine();
        UI::Text("total records: " + Globals::records.Length);

        if (UI::Button(Icons::FloppyO + " save accounts"))
            startnew(CoroutineFunc(DB::AllAccounts::SaveCoro));

        UI::SameLine();
        if (UI::Button(Icons::Upload + " load accounts"))
            startnew(CoroutineFunc(DB::AllAccounts::LoadCoro));

        UI::SameLine();
        if (UI::Button(Icons::Times + " clear accounts"))
            DB::AllAccounts::Clear();

        UI::SameLine();
        if (UI::Button(Icons::Download + " get names"))
            startnew(CoroutineFunc(Accounts::GetAccountNamesCoro));

        UI::SameLine();
        UI::Text("total accounts: " + Globals::accounts.Length);

        int flags =
            UI::TableFlags::Resizable |
            UI::TableFlags::ScrollY;

        if (UI::BeginTable("table_accounts", 3, flags)) {
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

    void Thing_LockDevButton() {
        if (UI::Button(Icons::Lock + " Lock Dev Tab")) {
            Util::Trace("dev tab locked");
            Settings::devHidden = true;
            Globals::dev = false;
        }
    }
}