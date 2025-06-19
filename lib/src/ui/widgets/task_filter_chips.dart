// lib/src/ui/widgets/task_filter_chips.dart
import 'package:flutter/material.dart';
import 'package:app/src/models/task_filter_sort.dart'; // Make sure this path is correct
import 'package:app/l10n/app_localizations.dart'; // For AppLocalizations

class TaskFilterChips extends StatelessWidget {
  final TaskFilter currentFilter;
  final ValueChanged<TaskFilter> onFilterChanged;

  const TaskFilterChips({
    required this.currentFilter,
    required this.onFilterChanged,
    super.key,
  });

  String getFilterText(TaskFilter filter, AppLocalizations s) {
    switch (filter) {
      case TaskFilter.all:
        return s.allTasks;
      case TaskFilter.active:
        return s.activeTasks;
      case TaskFilter.completed:
        return s.completedTasks;
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    // Use a SingleChildScrollView to prevent overflow if text labels are long
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal, // Allow horizontal scrolling for chips
      child: Row(
        mainAxisSize: MainAxisSize.min, // Make row take minimum space
        children: TaskFilter.values.map((filter) {
          final bool isSelected = filter == currentFilter;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: ChoiceChip(
              label: Text(
                getFilterText(filter, s),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isSelected
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSurface,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  onFilterChanged(filter);
                }
              },
              selectedColor: theme.colorScheme.primary,
              backgroundColor: theme.colorScheme.surfaceVariant,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outline,
                  width: 0.8,
                ),
              ),
              showCheckmark: false,
            ),
          );
        }).toList(),
      ),
    );
  }
}
