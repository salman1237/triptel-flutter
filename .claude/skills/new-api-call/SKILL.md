---
name: new-api-call
description: Add a Triptel backend endpoint call (model, API method, provider, tests) consistent with docs/API.md. Use whenever the app needs data from or sends data to the backend.
---
# New API call

1. Find the endpoint in `docs/API.md`. Out-of-scope (admin/merchant/agent/partner)
   → stop. If it isn't documented, verify it against
   `https://beta.triptel.co/openapi.json` and the backend router in
   `D:\eSim\backend\app\api\v1\`, then add it to `docs/API.md` first.
2. Capture a **real** beta response (public endpoints: `curl -s`; authed: a beta test
   account) and save it as a fixture in `test/fixtures/<name>.json`. Don't invent fields.
3. Model in `lib/features/<feature>/data/models/`: `fromJson` tolerant of nulls;
   money parsed into the money type (EUR), dates parsed as UTC when naive.
4. Method in `<feature>_api.dart` using the shared `ApiClient` (it adds auth and maps
   `{"detail"}` errors to `ApiException`). Map flow-changing errors from API.md §0.1.
5. Provider in `application/`. Business rules (e.g. wallet covers price) as pure
   functions with unit tests.
6. Tests: model parses the fixture; API method hits a mocked `Dio` with the right
   path/body; error mapping for at least one 4xx.
