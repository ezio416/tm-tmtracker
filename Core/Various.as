/*
c 2023-05-20
m 2023-05-20
*/

// Functions that don't fit nicely in other categories
namespace Various {
    void WaitToDoNadeoRequestCoro() {
        if (Storage::latestNadeoRequest == 0) {
            Storage::latestNadeoRequest = Time::Now;
            return;
        }

        while (Storage::requestsInProgress > 0)
            yield();
        if (Storage::requestsInProgress < 0)  // hopefully won't happen
            Storage::requestsInProgress = 0;
        Storage::requestsInProgress++;

        while (Time::Now - Storage::latestNadeoRequest < Settings::timeBetweenNadeoRequests)
            yield();

        Storage::latestNadeoRequest = Time::Now;
    }
}