/*
c 2023-07-11
m 2023-07-12
*/

namespace Tabs {
    void Tab_Records() {
        if (!UI::BeginTabItem(Icons::Trophy + " Records")) return;

        UI::BeginTabBar("RecordsTabs");
            Records::Tab_MyMapsRecords();
        UI::EndTabBar();

        UI::EndTabItem();
    }
}