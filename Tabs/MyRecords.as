/*
c 2023-05-26
m 2023-05-26
*/

// Functions for rendering tabs in the interface
namespace Tabs {
    void MyRecords() {
        if (!UI::BeginTabItem(Icons::Trophy + " My Records")) return;



        UI::EndTabItem();
    }
}