/*
c 2023-05-16
m 2023-05-17
*/

namespace Zones {
    void Load() {
        trace('loading zones from file...');
        Storage::zones = Json::FromFile('Resources/zones.json');
    }
}