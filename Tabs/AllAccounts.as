/*
c 2023-05-26
m 2023-05-26
*/

// Functions for rendering tabs in the interface
namespace Tabs {
    void AllAccounts() {
        if (!UI::BeginTabItem(Icons::User + " Accounts")) return;



        UI::EndTabItem();
    }
}