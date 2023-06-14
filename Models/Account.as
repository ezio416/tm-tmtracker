/*
c 2023-05-16
m 2023-06-14
*/

// Classes for holding data gathered during plugin operation
namespace Models {
    // Data on a player profile
    class Account {
        string accountId;
        string accountName = "";
        uint64 nameExpire = 0;
        string zoneId;

        Account() { }
        Account(const string &in id) { accountId = id; }
        Account(SQLite::Statement@ s) {
            accountId   = s.GetColumnString("accountId");
            accountName = s.GetColumnString("accountName");
            nameExpire  = s.GetColumnInt("nameExpire");
            zoneId      = s.GetColumnString("zoneId");
        }

        string get_zoneName() {
            return Zones::Get(zoneId);
        }

        bool IsNameExpired() {
            return (nameExpire - Time::Stamp < 0);
        }

        string NameExpireFormatted() {
            if (IsNameExpired()) return "expired";
            return Time::FormatString(Settings::dateFormat + "Local\\$Z", nameExpire);
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