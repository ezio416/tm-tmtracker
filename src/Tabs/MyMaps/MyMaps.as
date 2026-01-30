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
