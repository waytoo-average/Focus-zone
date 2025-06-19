// lib/src/ui/widgets/deadline_tile.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:app/src/utils/app_padding.dart'; // Make sure this path is correct
import 'package:app/todo_features.dart'; // Import your TodoItem
import 'package:app/l10n/app_localizations.dart'; // Import for AppLocalizations

class DeadlineTile extends StatelessWidget {
  final TodoItem todoItem; // Changed from Task to TodoItem
  const DeadlineTile({required this.todoItem, super.key});

  String getCountdownText(BuildContext context) {
    final s = AppLocalizations.of(context)!;

    if (todoItem.dueDate == null) return s.notSet; // Handle null due date

    final now = DateTime.now();
    final taskDate = DateTime(
        todoItem.dueDate!.year, todoItem.dueDate!.month, todoItem.dueDate!.day);
    Duration difference = taskDate.difference(
        DateTime(now.year, now.month, now.day)); // Only compare days

    int totalDays = difference.inDays;
    final absDays = totalDays.abs();

    if (totalDays == 0) return s.dueToday;

    // Calculate years, months, weeks, days for a more accurate countdown
    int years = absDays ~/ 365;
    int remainingDaysAfterYears = absDays % 365;
    int months = remainingDaysAfterYears ~/ 30; // Approximate months
    int remainingDaysAfterMonths = remainingDaysAfterYears % 30;
    int weeks = remainingDaysAfterMonths ~/ 7;
    int days = remainingDaysAfterMonths % 7;

    List<String> parts = [];
    if (years > 0) parts.add('$years ${s.year(years)}');
    if (months > 0) parts.add('$months ${s.month(months)}');
    if (weeks > 0) parts.add('$weeks ${s.week(weeks)}');
    if (days > 0) parts.add('$days ${s.day(days)}');

    final timeString = parts.isNotEmpty
        ? parts.join(', ')
        : s.lessThanOneDay; // Handle cases less than a day

    return totalDays > 0 ? s.dueIn(timeString) : s.overdueBy(timeString);
  }

  Color getTileBackgroundColor(ThemeData theme) {
    if (todoItem.isCompleted)
      return theme.colorScheme.onSurface
          .withOpacity(0.1); // Lighter for completed

    if (todoItem.dueDate == null)
      return theme.cardColor; // Default for no due date

    final now = DateTime.now();
    final diffDays = todoItem.dueDate!.difference(now).inDays;

    if (todoItem.isOverdue) {
      return Colors.red.shade900.withAlpha(38); // Red for overdue
    } else if (diffDays == 0) {
      // Due Today
      return Colors.orange.shade800.withAlpha(38);
    } else if (diffDays <= 3) {
      // Due in 1-3 days
      return Colors.yellow.shade700.withAlpha(31);
    } else {
      // Due in more than 3 days
      return Colors.green.shade700.withAlpha(20);
    }
  }

  Color getCountdownColor(ThemeData theme) {
    if (todoItem.isCompleted) return theme.disabledColor; // Muted for completed

    if (todoItem.dueDate == null)
      return theme.colorScheme.onSurface.withOpacity(0.7); // Default color

    final now = DateTime.now();
    final difference = todoItem.dueDate!.difference(now).inDays;

    if (todoItem.isOverdue) {
      return Colors.red.shade300; // Bright red for overdue
    } else if (difference == 0) {
      // Due Today
      return Colors.orange.shade300;
    } else if (difference > 0) {
      // Due in future
      return Colors.green.shade300;
    }
    return theme.colorScheme.onSurface.withOpacity(0.7); // Fallback
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = AppLocalizations.of(context)!;

    String formattedDate = s.notSet;
    if (todoItem.dueDate != null) {
      formattedDate = DateFormat(
              'd MMMM y', Localizations.localeOf(context).toLanguageTag())
          .format(todoItem.dueDate!);
    }

    String formattedTime = '';
    if (todoItem.dueTime != null) {
      formattedTime = MaterialLocalizations.of(context).formatTimeOfDay(
          todoItem.dueTime!,
          alwaysUse24HourFormat: MediaQuery.of(context).alwaysUse24HourFormat);
    }

    String fullDateTimeString = formattedDate;
    if (formattedTime.isNotEmpty) {
      fullDateTimeString += ', $formattedTime';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppPadding.horizontal,
        vertical: AppPadding.vertical,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: getTileBackgroundColor(theme),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(AppPadding.all),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    todoItem.title,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: todoItem.isCompleted
                          ? theme.disabledColor
                          : theme.colorScheme.onSurface,
                      decoration: todoItem.isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: todoItem.isCompleted
                        ? Colors.tealAccent.shade700.withAlpha(77)
                        : theme.colorScheme.secondary.withAlpha(102),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: todoItem.isCompleted
                            ? Colors.tealAccent.shade100
                            : theme.colorScheme.onSecondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        todoItem.isCompleted ? s.completed : fullDateTimeString,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: todoItem.isCompleted
                              ? Colors.tealAccent.shade100
                              : theme.colorScheme.onSecondary.withOpacity(0.8),
                          fontWeight: FontWeight.w500,
                          fontStyle: todoItem.isCompleted
                              ? FontStyle.italic
                              : FontStyle.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Only show countdown if not completed and has a due date
            if (!todoItem.isCompleted && todoItem.dueDate != null)
              Text(
                getCountdownText(context),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: getCountdownColor(theme),
                  fontWeight: FontWeight.w600,
                ),
              ),
            if (todoItem.isRepeating &&
                !todoItem.isCompleted) // Show repeat icon
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Row(
                  children: [
                    Icon(Icons.repeat,
                        size: 16,
                        color: theme.colorScheme.onSurface.withOpacity(0.6)),
                    const SizedBox(width: 4),
                    Text(
                      s.repeats(todoItem.repeatInterval ??
                          s.notSet), // Show repeat interval
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
