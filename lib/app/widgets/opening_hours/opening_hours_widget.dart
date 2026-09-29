import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';

/// Model for a single day's opening hours
class OpeningHoursEntry {
  final String day;
  final RxBool isOpen;
  final Rx<TimeOfDay> openTime;
  final Rx<TimeOfDay> closeTime;

  OpeningHoursEntry({
    required this.day,
    bool isOpen = true,
    TimeOfDay? openTime,
    TimeOfDay? closeTime,
  }) : isOpen = isOpen.obs,
       openTime = (openTime ?? const TimeOfDay(hour: 9, minute: 0)).obs,
       closeTime = (closeTime ?? const TimeOfDay(hour: 18, minute: 0)).obs;

  /// Convert to display string
  String toDisplayString() {
    if (!isOpen.value) return 'Closed';
    return '${_formatTime(openTime.value)} - ${_formatTime(closeTime.value)}';
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }
}

/// Widget for managing opening hours with time pickers
class OpeningHoursWidget extends StatelessWidget {
  final List<OpeningHoursEntry> entries;
  final VoidCallback? onChanged;

  const OpeningHoursWidget({super.key, required this.entries, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Opening Hours',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.darkGray,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.lightGray),
          ),
          child: Column(
            children: entries.asMap().entries.map((mapEntry) {
              final index = mapEntry.key;
              final entry = mapEntry.value;
              return Column(
                children: [
                  _buildDayRow(context, entry),
                  if (index < entries.length - 1)
                    const Divider(height: 1, color: AppColors.lightGray),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildDayRow(BuildContext context, OpeningHoursEntry entry) {
    return Obx(
      () => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Day name
            SizedBox(
              width: 60,
              child: Text(
                entry.day,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: entry.isOpen.value
                      ? AppColors.darkGray
                      : AppColors.mediumGray,
                ),
              ),
            ),
            // Open/Closed toggle
            GestureDetector(
              onTap: () {
                entry.isOpen.value = !entry.isOpen.value;
                onChanged?.call();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: entry.isOpen.value
                      ? AppColors.jadeGreen.withOpacity(0.1)
                      : AppColors.mediumGray.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  entry.isOpen.value ? 'Open' : 'Closed',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: entry.isOpen.value
                        ? AppColors.jadeGreen
                        : AppColors.mediumGray,
                  ),
                ),
              ),
            ),
            const Spacer(),
            // Time pickers (only show if open)
            if (entry.isOpen.value) ...[
              _buildTimePicker(
                context,
                time: entry.openTime.value,
                label: 'Open',
                onTap: () async {
                  final time = await _showTimePicker(
                    context,
                    entry.openTime.value,
                  );
                  if (time != null) {
                    entry.openTime.value = time;
                    onChanged?.call();
                  }
                },
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  '-',
                  style: TextStyle(
                    color: AppColors.mediumGray,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              _buildTimePicker(
                context,
                time: entry.closeTime.value,
                label: 'Close',
                onTap: () async {
                  final time = await _showTimePicker(
                    context,
                    entry.closeTime.value,
                  );
                  if (time != null) {
                    entry.closeTime.value = time;
                    onChanged?.call();
                  }
                },
              ),
            ] else
              Text(
                'Closed',
                style: TextStyle(
                  color: AppColors.mediumGray,
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimePicker(
    BuildContext context, {
    required TimeOfDay time,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.chineseRed.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.chineseRed.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.access_time, size: 16, color: AppColors.chineseRed),
            const SizedBox(width: 6),
            Text(
              _formatTime(time),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.darkGray,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  Future<TimeOfDay?> _showTimePicker(
    BuildContext context,
    TimeOfDay initialTime,
  ) async {
    return showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.chineseRed,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.darkGray,
            ),
            timePickerTheme: TimePickerThemeData(
              backgroundColor: Colors.white,
              hourMinuteShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              dayPeriodShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          child: child!,
        );
      },
    );
  }
}

/// Helper class for parsing and formatting opening hours
class OpeningHoursHelper {
  static const List<String> dayNames = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  /// Create default opening hours entries (all days open 9AM-6PM)
  static List<OpeningHoursEntry> createDefault() {
    return dayNames.map((day) => OpeningHoursEntry(day: day)).toList();
  }

  /// Parse opening hours string to entries
  static List<OpeningHoursEntry> parseFromString(String? hoursString) {
    if (hoursString == null || hoursString.isEmpty) {
      return createDefault();
    }

    final entries = createDefault();

    // Try to parse the string format
    // Expected formats:
    // - "Mon-Fri: 9:00 AM - 6:00 PM, Sat-Sun: Closed"
    // - "Mon: 9:00 AM - 6:00 PM\nTue: 9:00 AM - 6:00 PM..." etc.
    // - Simple format: each line is "Day: time - time" or "Day: Closed"

    final lines = hoursString.split(RegExp(r'[,\n]'));
    for (var line in lines) {
      line = line.trim();
      if (line.isEmpty) continue;

      // Check for range like "Mon-Fri"
      final rangeMatch = RegExp(r'^(\w+)-(\w+):\s*(.+)$').firstMatch(line);
      if (rangeMatch != null) {
        final startDay = rangeMatch.group(1)!;
        final endDay = rangeMatch.group(2)!;
        final timeStr = rangeMatch.group(3)!;

        final startIdx = dayNames.indexWhere(
          (d) => d.toLowerCase().startsWith(startDay.toLowerCase()),
        );
        final endIdx = dayNames.indexWhere(
          (d) => d.toLowerCase().startsWith(endDay.toLowerCase()),
        );

        if (startIdx != -1 && endIdx != -1) {
          for (int i = startIdx; i <= endIdx; i++) {
            _parseTimeString(entries[i], timeStr);
          }
        }
        continue;
      }

      // Check for single day format "Mon: time"
      final singleMatch = RegExp(r'^(\w+):\s*(.+)$').firstMatch(line);
      if (singleMatch != null) {
        final day = singleMatch.group(1)!;
        final timeStr = singleMatch.group(2)!;

        final dayIdx = dayNames.indexWhere(
          (d) => d.toLowerCase().startsWith(day.toLowerCase()),
        );

        if (dayIdx != -1) {
          _parseTimeString(entries[dayIdx], timeStr);
        }
      }
    }

    return entries;
  }

  static void _parseTimeString(OpeningHoursEntry entry, String timeStr) {
    final trimmed = timeStr.trim().toLowerCase();

    if (trimmed == 'closed' || trimmed == 'close') {
      entry.isOpen.value = false;
      return;
    }

    // Try to parse time range like "9:00 AM - 6:00 PM" or "9AM-6PM"
    final timeMatch = RegExp(
      r'(\d{1,2}):?(\d{0,2})\s*(am|pm)?\s*[-–]\s*(\d{1,2}):?(\d{0,2})\s*(am|pm)?',
      caseSensitive: false,
    ).firstMatch(timeStr);

    if (timeMatch != null) {
      entry.isOpen.value = true;

      final openHour = int.parse(timeMatch.group(1)!);
      final openMin = int.tryParse(timeMatch.group(2) ?? '0') ?? 0;
      final openPeriod = timeMatch.group(3)?.toLowerCase();

      final closeHour = int.parse(timeMatch.group(4)!);
      final closeMin = int.tryParse(timeMatch.group(5) ?? '0') ?? 0;
      final closePeriod = timeMatch.group(6)?.toLowerCase();

      entry.openTime.value = _convertTo24Hour(openHour, openMin, openPeriod);
      entry.closeTime.value = _convertTo24Hour(
        closeHour,
        closeMin,
        closePeriod,
      );
    }
  }

  static TimeOfDay _convertTo24Hour(int hour, int minute, String? period) {
    if (period == null) {
      // Assume AM for hour < 12, PM otherwise
      return TimeOfDay(hour: hour, minute: minute);
    }

    if (period == 'am') {
      return TimeOfDay(hour: hour == 12 ? 0 : hour, minute: minute);
    } else {
      return TimeOfDay(hour: hour == 12 ? 12 : hour + 12, minute: minute);
    }
  }

  /// Convert entries to string format for storage
  static String entriesToString(List<OpeningHoursEntry> entries) {
    final result = <String>[];

    int i = 0;
    while (i < entries.length) {
      final currentEntry = entries[i];
      int rangeEnd = i;

      // Find consecutive days with same hours
      while (rangeEnd < entries.length - 1) {
        final next = entries[rangeEnd + 1];
        if (_sameHours(currentEntry, next)) {
          rangeEnd++;
        } else {
          break;
        }
      }

      // Format the range
      if (rangeEnd > i) {
        // Multiple consecutive days with same hours
        final startDay = entries[i].day;
        final endDay = entries[rangeEnd].day;
        result.add('$startDay-$endDay: ${currentEntry.toDisplayString()}');
      } else {
        // Single day
        result.add('${currentEntry.day}: ${currentEntry.toDisplayString()}');
      }

      i = rangeEnd + 1;
    }

    return result.join(', ');
  }

  static bool _sameHours(OpeningHoursEntry a, OpeningHoursEntry b) {
    if (a.isOpen.value != b.isOpen.value) return false;
    if (!a.isOpen.value) return true; // Both closed
    return a.openTime.value.hour == b.openTime.value.hour &&
        a.openTime.value.minute == b.openTime.value.minute &&
        a.closeTime.value.hour == b.closeTime.value.hour &&
        a.closeTime.value.minute == b.closeTime.value.minute;
  }
}
