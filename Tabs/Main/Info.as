/*
c 2023-05-26
m 2023-08-07
*/

namespace Tabs {
    void Tab_Info() {
        if (!UI::BeginTabItem(Icons::Info + " Info")) return;

        UI::TextWrapped(
            "TMTracker is a project I started back in December of 2022.\nIt has moved from Python "      +
            "\uF061 C# \uF061 Angelscript (this), which will probably be the final version.\nThere are " +
            "more features planned, like:\n\n - adding other maps and campaigns, such as the current "   +
            "map or from TMX\n - tracking personal records on maps and campaigns" +
            "\n - setting a custom order for personal maps" +
            "\n - more, please give me suggestions!\n\nThis is by far my " +
            "largest coding project with hundreds of hours put in, so I hope you find it useful! "
        );

        UI::Separator();

        UI::TextWrapped(
            "If you do have suggestions or problems, please submit an issue:\n" +
            "It's very easy to add a setting, and probably easy to add a small feature."
        );
        UI::SameLine();
        string linkGH = "https://github.com/ezio416/TMTracker-Openplanet/issues";
        if (UI::Button(Icons::Github + " Issues")) OpenBrowserURL(linkGH);

        UI::Separator();

        UI::TextWrapped("Files are kept in: ");

        UI::SameLine();
        if (UI::Selectable("\\$1F1" + Globals::storageFolder, false))
            IO::SetClipboard(Globals::storageFolder);
        if (UI::IsItemHovered()) {
            UI::BeginTooltip();
                UI::Text("click to copy");
            UI::EndTooltip();
        }

        UI::TextWrapped("If you want to look in the database, I recommend DB Browser:");

        UI::SameLine();
        string linkSQL = "sqlitebrowser.org";
        if (UI::Button(Icons::Database + " " + linkSQL)) OpenBrowserURL("https://" + linkSQL);

#if SIG_DEVELOPER
        UI::Separator();

        if (Globals::debug) {
            Button_LockDebug();
        } else {
            if (UI::Button(Icons::Unlock + " Unlock Debug Tab")) {
                trace("debug tab unlocked");
                Settings::debugHidden = false;
                Globals::debug = true;
            }
        }
#endif

        UI::EndTabItem();
    }
}