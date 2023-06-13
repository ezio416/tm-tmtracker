/*
c 2023-05-20
m 2023-06-13
*/

// Functions for getting/loading data on player profiles
namespace Accounts {
    void GetAccountNamesCoro() {
        string timerId = Util::LogTimerBegin("getting account names");

        uint idLimit = 209;
        string[] missing;
        dictionary names;

        for (uint i = 0; i < Globals::accounts.Length; i++)
            if (Globals::accounts[i].IsNameExpired())
                Globals::accounts[i].accountName = "";

        auto ids = Globals::accountIds.GetKeys();
        for (uint i = 0; i < ids.Length; i++)
            if (string(Globals::accountIds[ids[i]]) == "")
                missing.InsertLast(ids[i]);

        if (missing.Length > 0) {
            while (true) {
                string[] reqIds;
                uint idsToAdd = Math::Min(missing.Length, idLimit);
                for (uint i = 0; i < idsToAdd; i++) reqIds.InsertLast(missing[i]);

                auto ret = NadeoServices::GetDisplayNamesAsync(reqIds);
                for (uint i = 0; i < idsToAdd; i++) {
                    string id = missing[i];
                    names.Set(id, string(ret[id]));
                }

                if (missing.Length <= idLimit) break;
                missing.RemoveRange(0, idLimit);
            }
        }

        for (uint i = 0; i < Globals::accounts.Length; i++) {
            auto account = @Globals::accounts[i];
            if (account.accountName != "") continue;
            account.accountName = string(names[account.accountId]);
            account.SetNameExpire();
            Globals::accountIds.Set(account.accountId, account.accountName);
        }

        // DB::AllAccounts::Save();
        // DB::AllAccounts::Load();

        Util::LogTimerEnd(timerId);
    }
}