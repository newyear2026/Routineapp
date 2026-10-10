/// One real occurrence in the compact current-and-next schedule.
class WidgetTimelineItem {
  const WidgetTimelineItem({
    required this.id,
    required this.title,
    required this.time,
    required this.startEpochMs,
  });

  final String id;
  final String title;
  final String time;
  final int startEpochMs;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'time': time,
        'startEpochMs': startEpochMs,
      };
}
