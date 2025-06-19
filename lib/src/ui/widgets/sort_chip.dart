// lib/src/ui/widgets/sort_chip.dart
import 'package:flutter/material.dart';
import 'package:app/src/models/task_filter_sort.dart'; // Make sure this path is correct
import 'package:app/l10n/app_localizations.dart'; // For AppLocalizations

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
