/*
c 2023-05-20
m 2023-05-25
*/

// Functions for getting/loading data on player profiles
namespace Accounts {
    void GetAccountNamesCoro() {
        string timerId = Various::LogTimerStart("getting account names");

        uint idLimit = 209;
        string[] missing;
        dictionary names;

        for (uint i = 0; i < Storage::accounts.Length; i++)
            if (Storage::accounts[i].IsNameExpired())
                Storage::accounts[i].accountName = "";

        auto ids = Storage::accountIds.GetKeys();
        for (uint i = 0; i < ids.Length; i++)
            if (string(Storage::accountIds[ids[i]]) == "")
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

        for (uint i = 0; i < Storage::accounts.Length; i++) {
            auto account = @Storage::accounts[i];
            if (account.accountName != "") continue;
            account.accountName = string(names[account.accountId]);
            account.SetNameExpire();
            Storage::accountIds.Set(account.accountId, account.accountName);
        }

        Various::LogTimerEnd(timerId);
    }
}