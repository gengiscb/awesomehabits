/// Utilities for transforming DateTime into a stable yyyy-MM-dd key
/// using the device's local time (so users see completions on the day
/// they marked them, in their locale).
class DateKey {
  /// Returns a key like 2025-09-28 for the local date.
  static String fromDateTime(DateTime dt) {
    final local = dt.toLocal();
    final y = local.year.toString().padLeft(4, '0');
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    return "$y-$m-$d";
  }

  /// Returns today's key using the current local time.
  static String today() => fromDateTime(DateTime.now());
}
