// --- SortChip & TaskFilterChips Widgets ---
import 'package:flutter/material.dart';
import 'package:app/src/utils/app_utilities.dart';
import 'package:app/l10n/app_localizations.dart';

class SortChip extends StatelessWidget {
  final TaskSort currentSort;
  final ValueChanged<TaskSort> onSortChanged;

  const SortChip({
    required this.currentSort,
    required this.onSortChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    String getSortText(TaskSort sort) {
      switch (sort) {
        case TaskSort.dueDateAsc:
          return s.sortByDueDateAsc;
        case TaskSort.dueDateDesc:
          return s.sortByDueDateDesc;
        case TaskSort.titleAsc:
          return s.sortByTitleAsc;
        case TaskSort.titleDesc:
          return s.sortByTitleDesc;
      }
    }

    return GestureDetector(
      onTap: () {
        showMenu(
          context: context,
          position: RelativeRect.fromLTRB(
            MediaQuery.of(context).size.width,
            kToolbarHeight + 60,
            0,
            0,
          ),
          items: TaskSort.values.map((sort) {
            return PopupMenuItem<TaskSort>(
              value: sort,
              child: Text(getSortText(sort)),
            );
          }).toList(),
          elevation: 8.0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          color: theme.cardColor,
        ).then((newValue) {
          if (newValue != null && newValue != currentSort) {
            onSortChanged(newValue);
          }
        });
      },
      child: Chip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.sort, size: 18, color: theme.colorScheme.onSurface),
            const SizedBox(width: 4),
            Text(
              getSortText(currentSort),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        backgroundColor: theme.colorScheme.surfaceVariant,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

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

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
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
