/*
c 2023-05-16
m 2023-05-25
*/

// Classes for holding data gathered during plugin operation
namespace Models {
    // Data on a player profile
    class Account {
        string     accountId;
        string     accountName = "";
        uint64     nameExpire = 0;
        dictionary recordMapUids;

        Account() { }
        Account(const string &in id) { accountId = id; }

        bool IsNameExpired() {
            return (nameExpire - Time::Stamp < 0);
        }

        string NameExpireFormatted() {
            if (IsNameExpired()) return "expired";
            return Time::FormatString(Settings::dateFormat + "Local", nameExpire);
        }

        void SetNameExpire(uint64 now = 0, int64 timestamp = 0) {
            if (timestamp != 0) {
                nameExpire = timestamp;
                return;
            }
            if (now == 0) now = Time::Stamp;
            nameExpire = Settings::accountNameExpirationDays * 86400 + now;
        }
    }
}