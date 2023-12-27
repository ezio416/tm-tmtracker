// c 2023-12-25
// m 2023-12-27

// most things here are courtesy of "BetterTOTD" plugin - https://github.com/XertroV/tm-better-totd
namespace Sort {
    uint64 maxFrameTime = 10;

    namespace Maps {
        uint64 sortLastYield = 0;

        funcdef int MapSortFunc(Models::Map@ m1, Models::Map@ m2);

        int LowestFirst(Models::Map@ m1, Models::Map@ m2) {
            return Math::Clamp(m1.number - m2.number, -1, 1);
        }

        int HighestFirst(Models::Map@ m1, Models::Map@ m2) {
            return Math::Clamp(m2.number - m1.number, -1, 1);
        }

        int NameAlpha(Models::Map@ m1, Models::Map@ m2) {
            string n1 = m1.mapNameText.Trim().ToLower();
            string n2 = m2.mapNameText.Trim().ToLower();

            if (n1 < n2)
                return -1;
            if (n1 > n2)
                return 1;
            return 0;
        }

        int NameAlphaRev(Models::Map@ m1, Models::Map@ m2) {
            string n1 = m1.mapNameText.Trim().ToLower();
            string n2 = m2.mapNameText.Trim().ToLower();

            if (n1 < n2)
                return 1;
            if (n1 > n2)
                return -1;
            return 0;
        }

        int MostRecordsFirst(Models::Map@ m1, Models::Map@ m2) {
            return Math::Clamp(m2.records.Length - m1.records.Length, -1, 1);
        }

        int LeastRecordsFirst(Models::Map@ m1, Models::Map@ m2) {
            return Math::Clamp(m1.records.Length - m2.records.Length, -1, 1);
        }

        int EarliestRecordsRecencyFirst(Models::Map@ m1, Models::Map@ m2) {
            return Math::Clamp(m1.recordsTimestamp - m2.recordsTimestamp, -1, 1);
        }

        int LatestRecordsRecencyFirst(Models::Map@ m1, Models::Map@ m2) {
            return Math::Clamp(m2.recordsTimestamp - m1.recordsTimestamp, -1, 1);
        }

        int EarliestUploadFirst(Models::Map@ m1, Models::Map@ m2) {
            return Math::Clamp(Math::Max(m1.updateTimestamp, m1.uploadTimestamp) - Math::Max(m2.updateTimestamp, m2.uploadTimestamp), -1, 1);
        }

        int LatestUploadFirst(Models::Map@ m1, Models::Map@ m2) {
            return Math::Clamp(Math::Max(m2.updateTimestamp, m2.uploadTimestamp) - Math::Max(m1.updateTimestamp, m1.uploadTimestamp), -1, 1);
        }

        enum SortMethod {
            LowestFirst,
            HighestFirst,
            NameAlpha,
            NameAlphaRev,
            MostRecordsFirst,
            LeastRecordsFirst,
            EarliestRecordsRecencyFirst,
            LatestRecordsRecencyFirst,
            EarliestUploadFirst,
            LatestUploadFirst
        }

        MapSortFunc@[] sortFunctions = {
            LowestFirst,
            HighestFirst,
            NameAlpha,
            NameAlphaRev,
            MostRecordsFirst,
            LeastRecordsFirst,
            EarliestRecordsRecencyFirst,
            LatestRecordsRecencyFirst,
            EarliestUploadFirst,
            LatestUploadFirst
        };

        Models::Map@[]@ QuickSort(Models::Map@[]@ arr, MapSortFunc@ f, int left = 0, int right = -1) {
            uint64 now = Time::Now;
            if (now - sortLastYield > maxFrameTime) {
                sortLastYield = now;
                yield();
            }

            if (right < 0)
                right = arr.Length - 1;

            if (arr.Length == 0)
                return arr;

            int i = left;
            int j = right;
            Models::Map@ pivot = arr[(left + right) / 2];

            while (i <= j) {
                while (f(arr[i], pivot) < 0)
                    i++;

                while (f(arr[j], pivot) > 0)
                    j--;

                if (i <= j) {
                    Models::Map@ temp = arr[i];
                    @arr[i] = arr[j];
                    @arr[j] = temp;
                    i++;
                    j--;
                }
            }

            if (left < j)
                arr = QuickSort(arr, f, left, j);

            if (i < right)
                arr = QuickSort(arr, f, i, right);

            return arr;
        }

        void MyMapsCoro() {
            while (Locks::sortMyMaps)
                yield();
            Locks::sortMyMaps = true;
            string timerId = Log::TimerBegin("sorting my maps");
            string statusId = "sort-maps";

            Globals::myMapsSorted.RemoveRange(0, Globals::myMapsSorted.Length);

            for (uint i = 0; i < Globals::myMaps.Length; i++)
                Globals::myMapsSorted.InsertLast(@Globals::myMaps[i]);

            sortLastYield = Time::Now;

            Globals::myMapsSorted = QuickSort(Globals::myMapsSorted, sortFunctions[Settings::myMapsSortMethod]);

            Globals::status.Delete(statusId);
            Log::TimerEnd(timerId);
            Locks::sortMyMaps = false;
        }
    }

    namespace Records {
        bool allMaps = true;
        bool dbSave = false;
        uint64 sortLastYield = 0;

        funcdef int RecordSortFunc(Models::Record@ r1, Models::Record@ r2);

        int MapsAlpha(Models::Record@ r1, Models::Record@ r2) {
            string n1 = r1.mapNameText.Trim().ToLower();
            string n2 = r2.mapNameText.Trim().ToLower();

            if (n1 < n2)
                return -1;
            if (n1 > n2)
                return 1;
            return 0;
        }

        int MapsAlphaRev(Models::Record@ r1, Models::Record@ r2) {
            string n1 = r1.mapNameText.Trim().ToLower();
            string n2 = r2.mapNameText.Trim().ToLower();

            if (n1 < n2)
                return 1;
            if (n1 > n2)
                return -1;
            return 0;
        }

        int MapAuthorsAlpha(Models::Record@ r1, Models::Record@ r2) {
            string n1 = r1.mapAuthorName.ToLower();
            string n2 = r2.mapAuthorName.ToLower();

            if (n1 < n2)
                return -1;
            if (n1 > n2)
                return 1;
            return 0;
        }

        int MapAuthorsAlphaRev(Models::Record@ r1, Models::Record@ r2) {
            string n1 = r1.mapAuthorName.ToLower();
            string n2 = r2.mapAuthorName.ToLower();

            if (n1 < n2)
                return 1;
            if (n1 > n2)
                return -1;
            return 0;
        }

        int AccountsAlpha(Models::Record@ r1, Models::Record@ r2) {
            string n1 = r1.accountName.ToLower();
            string n2 = r2.accountName.ToLower();

            if (n1 < n2)
                return -1;
            if (n1 > n2)
                return 1;
            return 0;
        }

        int AccountsAlphaRev(Models::Record@ r1, Models::Record@ r2) {
            string n1 = r1.accountName.ToLower();
            string n2 = r2.accountName.ToLower();

            if (n1 < n2)
                return 1;
            if (n1 > n2)
                return -1;
            return 0;
        }

        int BestPosFirst(Models::Record@ r1, Models::Record@ r2) {
            return Math::Clamp(r2.position - r1.position, -1, 1);
        }

        int WorstPosFirst(Models::Record@ r1, Models::Record@ r2) {
            return Math::Clamp(r1.position - r2.position, -1, 1);
        }

        int BestAuthorFirst(Models::Record@ r1, Models::Record@ r2) {
            return Math::Clamp(r2.mapAuthorTime - r1.mapAuthorTime, -1, 1);
        }

        int WorstAuthorFirst(Models::Record@ r1, Models::Record@ r2) {
            return Math::Clamp(r1.mapAuthorTime - r2.mapAuthorTime, -1, 1);
        }

        int BestFirst(Models::Record@ r1, Models::Record@ r2) {
            return Math::Clamp(r1.time - r2.time, -1, 1);
        }

        int WorstFirst(Models::Record@ r1, Models::Record@ r2) {
            return Math::Clamp(r2.time - r1.time, -1, 1);
        }

        int BestDeltaFirst(Models::Record@ r1, Models::Record@ r2) {
            return Math::Clamp(r2.mapAuthorDelta - r1.mapAuthorDelta, -1, 1);
        }

        int WorstDeltaFirst(Models::Record@ r1, Models::Record@ r2) {
            return Math::Clamp(r1.mapAuthorDelta - r2.mapAuthorDelta, -1, 1);
        }

        int NewFirst(Models::Record@ r1, Models::Record@ r2) {
            return Math::Clamp(r2.timestampUnix - r1.timestampUnix, -1, 1);
        }

        int OldFirst(Models::Record@ r1, Models::Record@ r2) {
            return Math::Clamp(r1.timestampUnix - r2.timestampUnix, -1, 1);
        }

        enum SortMethod {
            MapsAlpha,
            MapsAlphaRev,
            MapAuthorsAlpha,
            MapAuthorsAlphaRev,
            AccountsAlpha,
            AccountsAlphaRev,
            BestPosFirst,
            WorstPosFirst,
            BestAuthorFirst,
            WorstAuthorFirst,
            BestFirst,
            WorstFirst,
            BestDeltaFirst,
            WorstDeltaFirst,
            NewFirst,
            OldFirst
        }

        RecordSortFunc@[] sortFunctions = {
            MapsAlpha,
            MapsAlphaRev,
            MapAuthorsAlpha,
            MapAuthorsAlphaRev,
            AccountsAlpha,
            AccountsAlphaRev,
            BestPosFirst,
            WorstPosFirst,
            BestAuthorFirst,
            WorstAuthorFirst,
            BestFirst,
            WorstFirst,
            BestDeltaFirst,
            WorstDeltaFirst,
            NewFirst,
            OldFirst
        };

        Models::Record@[]@ QuickSort(Models::Record@[]@ arr, RecordSortFunc@ f, int left = 0, int right = -1) {
            uint64 now = Time::Now;
            if (now - sortLastYield > maxFrameTime) {
                sortLastYield = now;
                yield();
            }

            if (right < 0)
                right = arr.Length - 1;

            if (arr.Length == 0)
                return arr;

            int i = left;
            int j = right;
            Models::Record@ pivot = arr[(left + right) / 2];

            while (i <= j) {
                while (f(arr[i], pivot) < 0)
                    i++;

                while (f(arr[j], pivot) > 0)
                    j--;

                if (i <= j) {
                    Models::Record@ temp = arr[i];
                    @arr[i] = arr[j];
                    @arr[j] = temp;
                    i++;
                    j--;
                }
            }

            if (left < j)
                arr = QuickSort(arr, f, left, j);

            if (i < right)
                arr = QuickSort(arr, f, i, right);

            return arr;
        }

        void MyMapsRecordsCoro() {
            while (Locks::sortMyMapsRecords)
                yield();
            Locks::sortMyMapsRecords = true;
            string timerId = Log::TimerBegin("sorting my maps' records");
            string statusId = "sort-records";

            Globals::myMapsRecordsSorted.RemoveRange(0, Globals::myMapsRecordsSorted.Length);

            for (uint i = 0; i < Globals::myMapsRecords.Length; i++)
                Globals::myMapsRecordsSorted.InsertLast(@Globals::myMapsRecords[i]);

            sortLastYield = Time::Now;

            Globals::myMapsRecordsSorted = QuickSort(Globals::myMapsRecordsSorted, sortFunctions[Settings::myMapsRecordsSortMethod]);

            Globals::status.Delete(statusId);
            Log::TimerEnd(timerId);
            Locks::sortMyMapsRecords = false;

            if (dbSave)
                startnew(Database::SaveCoro);

            dbSave = false;
            allMaps = false;
        }

        void MyRecordsCoro() {
            while (Locks::sortMyRecords)
                yield();
            Locks::sortMyRecords = true;
            string timerId = Log::TimerBegin("sorting my records");
            string statusId = "sort-my-records";

            Globals::myRecordsSorted.RemoveRange(0, Globals::myRecordsSorted.Length);

            for (uint i = 0; i < Globals::myRecords.Length; i++)
                Globals::myRecordsSorted.InsertLast(@Globals::myRecords[i]);

            sortLastYield = Time::Now;

            Globals::myRecordsSorted = QuickSort(Globals::myRecordsSorted, sortFunctions[Settings::myRecordsSortMethod]);

            Globals::status.Delete(statusId);
            Log::TimerEnd(timerId);
            Locks::sortMyRecords = false;
        }
    }
}