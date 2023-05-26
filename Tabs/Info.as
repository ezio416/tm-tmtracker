/*
c 2023-05-26
m 2023-05-26
*/

// Functions for rendering tabs in the interface
namespace Tabs {
    void Info() {
        if (!UI::BeginTabItem(Icons::Info + " Info")) return;

        UI::TextWrapped(
            "TMTracker is a project I started back in December of 2022.\nIt has moved from Python "    +
            "\uF061 C# \uF061 Angelscript, which will probably be the final version.\nThere are "      +
            "more features planned, like:\n\n - adding other maps and campaigns, such as the current " +
            "map or from TMX\n - tracking personal records on maps and campaigns\n - tracking recent " +
            "records for all maps \n - more, please suggest what you'd like!\n\nThis is by far my "    +
            "largest coding project with hundreds of hours put in, so I hope you find it useful! "     +
            "\n\nAlso check the Openplanet settings, there's quite a lot you can customize \uF118\n\n"
        );

        UI::Separator();

        UI::TextWrapped(
            "If you do have suggestions or problems, please submit an issue below.\n" +
            "It's very easy to add a setting, and probably easy to add a small feature."
        );
        string ghLink = "https://github.com/ezio416/TMTracker-Openplanet/issues";
        if (UI::Button(Icons::Github + " Issues")) OpenBrowserURL(ghLink);

        UI::Separator();

        UI::TextWrapped(
            "Files are kept at " + Globals::storageFolder +
            "\n\nIf you want to look in the database, I recommend DB Browser:"
        );
        string sqlLink = "sqlitebrowser.org";
        if (UI::Button(Icons::Database + " " + sqlLink)) OpenBrowserURL("https://" + sqlLink);

        UI::Separator();

        if (Globals::dev) {
            if (UI::Button("Lock Dev Tab")) {
                Various::Trace("dev tab locked");
                Globals::dev = false;
            }
        } else {
            if (UI::InputText("Unlock Dev Tab", "") == "balls") {
                Various::Trace("dev tab unlocked");
                Globals::dev = true;
            }
        }

        UI::EndTabItem();
    }
}