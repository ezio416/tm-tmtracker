/*
c 2023-07-11
m 2023-10-09
*/

namespace Tabs {
    void Tab_Records() {
        if (!UI::BeginTabItem(Icons::Trophy + " Records"))
            return;

        UI::BeginTabBar("RecordsTabs");
            Records::Tab_MyMapsRecords();
            Records::Tab_MyRecords();
        UI::EndTabBar();

        UI::EndTabItem();
    }
}