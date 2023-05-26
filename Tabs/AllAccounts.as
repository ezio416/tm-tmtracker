/*
c 2023-05-26
m 2023-05-26
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

        UI::Text("Account ID,     Name Expire Date,     Name");

        UI::Separator();

        for (uint i = 0; i < Globals::accounts.Length; i++) {
            UI::Text(
                Globals::accounts[i].accountId + "        " +
                Globals::accounts[i].NameExpireFormatted() + "        " +
                Globals::accounts[i].accountName
            );
        }

        UI::EndTabItem();
    }
}