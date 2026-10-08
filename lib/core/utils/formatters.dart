import 'package:intl/intl.dart';

String formatTime(DateTime time) => DateFormat.Hm().format(time.toLocal());

String formatDay(DateTime time) => DateFormat.MMMd().format(time.toLocal());

String initialsFrom(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.isEmpty) {
    return '?';
  }
  if (parts.length == 1) {
    final word = parts.first;
    return word.length == 1
        ? word.toUpperCase()
        : word.substring(0, 1).toUpperCase();
  }
  return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
}
