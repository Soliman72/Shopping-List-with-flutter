
class ShoppingItem {
  String name;
  bool isCompleted;
  bool isScheduled;
  bool isToday;
  DateTime? scheduledDate;

  ShoppingItem({
    required this.name,
    this.isCompleted = false,
    this.isScheduled = false,
    this.isToday = false,
    this.scheduledDate,
  });
}
