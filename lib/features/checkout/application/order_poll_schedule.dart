/// FR-306's poll schedule (API.md §6): every 2s for ~12s, then every 5s up
/// to ~170s total. Pure list of delays so the orchestration loop (which
/// actually waits and calls the API) and this timing can be tested
/// separately -- Architecture.md: business rules in plain Dart.
List<Duration> orderPollSchedule() {
  const fastInterval = Duration(seconds: 2);
  const fastPhaseEnd = Duration(seconds: 12);
  const slowInterval = Duration(seconds: 5);
  const totalEnd = Duration(seconds: 170);

  final delays = <Duration>[];
  var elapsed = Duration.zero;
  while (elapsed < fastPhaseEnd) {
    delays.add(fastInterval);
    elapsed += fastInterval;
  }
  while (elapsed < totalEnd) {
    delays.add(slowInterval);
    elapsed += slowInterval;
  }
  return delays;
}
