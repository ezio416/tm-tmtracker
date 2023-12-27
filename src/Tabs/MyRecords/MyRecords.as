// c 2023-10-09
// m 2023-12-27

namespace Tabs {
    void Tab_MyRecords() {
        if (!Settings::myRecordsTab || !UI::BeginTabItem(Icons::Trophy + " My Records"))
            return;

        UI::BeginTabBar("MyRecordsTabs");
            MyRecords::Tab_MyRecordsList();
            MyRecords::Tab_MyRecordsMapsViewing();
        UI::EndTabBar();

        UI::EndTabItem();
    }
}