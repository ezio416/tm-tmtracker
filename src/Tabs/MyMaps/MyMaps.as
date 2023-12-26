// c 2023-05-26
// m 2023-10-11

namespace Tabs {
    void Tab_MyMaps() {
        if (!UI::BeginTabItem(Icons::Map + " My Maps"))
            return;

        UI::BeginTabBar("MyMapsTabs");
            MyMaps::Tab_MyMapsList();
            MyMaps::Tab_MyMapsRecords();
            MyMaps::Tab_MyMapsViewing();
        UI::EndTabBar();

        UI::EndTabItem();
    }
}