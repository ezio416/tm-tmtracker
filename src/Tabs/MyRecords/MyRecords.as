namespace Tabs {
    void Tab_MyRecords() {
        if (!UI::BeginTabItem(Icons::Trophy + " My Records"))
            return;

        UI::BeginTabBar("MyRecordsTabs");
            MyRecords::Tab_MyRecordsList();
            MyRecords::Tab_MyRecordsMapsViewing();
        UI::EndTabBar();

        UI::EndTabItem();
    }
}
