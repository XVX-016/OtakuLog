class Activity {
  final int id;
  final DateTime date;
  final int minutesWatched;
  final int minutesRead;

  Activity({
    required this.id,
    required this.date,
    required this.minutesWatched,
    required this.minutesRead,
  });

  int get totalMinutes => minutesWatched + minutesRead;
}
