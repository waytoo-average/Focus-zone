// lib/todo_features.dart

import 'package:app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:app/app_core.dart';
import 'package:app/src/utils/app_utilities.dart';
import 'package:app/src/ui/widgets/deadline_tile.dart';
import 'package:app/src/ui/widgets/task_controls.dart';
import 'package:app/notification_manager.dart';

// --- Todo Data Model ---
class TodoItem {
  String title;
  bool isCompleted;
  DateTime? dueDate;
  TimeOfDay? dueTime;
  bool isRepeating;
  String? repeatInterval;
  String? listName;
  DateTime creationDate;

  TodoItem({
    required this.title,
    this.isCompleted = false,
    this.dueDate,
    this.dueTime,
    this.isRepeating = false,
    this.repeatInterval,
    this.listName,
    DateTime? creationDate,
  }) : creationDate = creationDate ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'title': title,
        'isCompleted': isCompleted,
        'dueDate': dueDate?.toIso8601String(),
        'dueTimeHour': dueTime?.hour,
        'dueTimeMinute': dueTime?.minute,
        'isRepeating': isRepeating,
        'repeatInterval': repeatInterval,
        'listName': listName,
        'creationDate': creationDate.toIso8601String(),
      };

  factory TodoItem.fromJson(Map<String, dynamic> json) {
    return TodoItem(
      title: json['title'] as String,
      isCompleted: json['isCompleted'] as bool,
      dueDate: json['dueDate'] != null
          ? DateTime.parse(json['dueDate'] as String)
          : null,
      dueTime: (json['dueTimeHour'] != null && json['dueTimeMinute'] != null)
          ? TimeOfDay(
              hour: json['dueTimeHour'] as int,
              minute: json['dueTimeMinute'] as int)
          : null,
      isRepeating: json['isRepeating'] as bool? ?? false,
      repeatInterval: json['repeatInterval'] as String?,
      listName: json['listName'] as String?,
      creationDate: json['creationDate'] != null
          ? DateTime.parse(json['creationDate'] as String)
          : DateTime.now(),
    );
  }

  bool get isOverdue {
    if (dueDate == null || isCompleted) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final taskDate = DateTime(dueDate!.year, dueDate!.month, dueDate!.day);

    if (taskDate.isBefore(today)) return true;

    if (taskDate.isAtSameMomentAs(today) && dueTime != null) {
      final taskDateTime = DateTime(
          now.year, now.month, now.day, dueTime!.hour, dueTime!.minute);
      return taskDateTime.isBefore(now);
    }
    return false;
  }

  String formatDueDate(BuildContext context, AppLocalizations s) {
    if (dueDate == null) return s.notSet;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final taskDate = DateTime(dueDate!.year, dueDate!.month, dueDate!.day);

    String dateText;
    if (taskDate.isAtSameMomentAs(today)) {
      dateText = s.todayTasks;
    } else if (taskDate.isAtSameMomentAs(tomorrow)) {
      dateText = s.tomorrowTasks;
    } else {
      dateText =
          DateFormat.yMMMd(Localizations.localeOf(context).toLanguageTag())
              .format(dueDate!);
    }

    String timeText = '';
    if (dueTime != null) {
      timeText = MaterialLocalizations.of(context).formatTimeOfDay(dueTime!);
    }

    return timeText.isNotEmpty ? '$dateText, $timeText' : dateText;
  }
}

// --- Todo List Screen ---
class TodoListScreen extends StatefulWidget {
  const TodoListScreen({super.key});

  @override
  State<TodoListScreen> createState() => _TodoListScreenState();
}

class _TodoListScreenState extends State<TodoListScreen> {
  List<TodoItem> _rawTodos = [];
  String _currentList = 'INITIAL_PLACEHOLDER';
  TaskFilter _currentFilter = TaskFilter.all;
  TaskSort _currentSort = TaskSort.dueDateAsc;
  late TodoSummaryProvider _todoSummaryProvider;

  @override
  void initState() {
    super.initState();
    _todoSummaryProvider =
        Provider.of<TodoSummaryProvider>(context, listen: false);
    _todoSummaryProvider.addListener(_onTodosChanged);
    _loadTodos();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final s = AppLocalizations.of(context)!;
    final availableLists = [
      s.allListsTitle,
      s.personal,
      s.work,
      s.shopping,
      s.defaultList
    ];
    // If the current value is not in the new locale's list, reset to default
    if (!availableLists.contains(_currentList)) {
      setState(() {
        _currentList = s.allListsTitle;
      });
    }
    // If first time, set to default
    if (_currentList == 'INITIAL_PLACEHOLDER') {
      setState(() {
        _currentList = s.allListsTitle;
      });
    }
  }

  @override
  void dispose() {
    _todoSummaryProvider.removeListener(_onTodosChanged);
    super.dispose();
  }

  void _onTodosChanged() {
    if (mounted) _loadTodos();
  }

  Future<void> _loadTodos() async {
    final todoProvider =
        Provider.of<TodoSummaryProvider>(context, listen: false);
    if (mounted) {
      setState(() {
        _rawTodos = todoProvider.allTodos;
      });
    }
  }

  void _editTodo(TodoItem todoItem) async {
    final s = AppLocalizations.of(context)!;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TodoDetailScreen(todoItem: todoItem),
      ),
    );
    if (mounted) {
      final updatedItem =
          Provider.of<TodoSummaryProvider>(context, listen: false)
              .allTodos
              .firstWhere((t) => t.creationDate == todoItem.creationDate,
                  orElse: () => todoItem);
      await NotificationManager.scheduleTodoNotification(
          context, updatedItem, s);
    }
  }

  void _markAsDone(TodoItem itemToToggle) async {
    final s = AppLocalizations.of(context)!;
    final updatedItem = TodoItem(
      title: itemToToggle.title,
      isCompleted: !itemToToggle.isCompleted,
      dueDate: itemToToggle.dueDate,
      dueTime: itemToToggle.dueTime,
      isRepeating: itemToToggle.isRepeating,
      repeatInterval: itemToToggle.repeatInterval,
      listName: itemToToggle.listName,
      creationDate: itemToToggle.creationDate,
    );

    await Provider.of<TodoSummaryProvider>(context, listen: false)
        .saveTodo(updatedItem);
    HapticFeedback.lightImpact();

    if (!mounted) return;

    if (updatedItem.isCompleted) {
      showAppSnackBar(context, s.taskCompleted,
          icon: Icons.check_circle_outline, iconColor: Colors.green);
      await NotificationManager.cancelTodoNotification(context, updatedItem);
    } else {
      showAppSnackBar(context, s.taskReactivated,
          icon: Icons.refresh, iconColor: Colors.blue);
      await NotificationManager.scheduleTodoNotification(
          context, updatedItem, s);
    }
  }

  void _deleteTodo(TodoItem itemToDelete) async {
    final s = AppLocalizations.of(context)!;
    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.confirmAction),
        content: Text(s.deleteTaskConfirmation),
        actions: [
          TextButton(
              child: Text(s.cancel),
              onPressed: () => Navigator.of(ctx).pop(false)),
          TextButton(
              child: Text(s.clear, style: const TextStyle(color: Colors.red)),
              onPressed: () => Navigator.of(ctx).pop(true)),
        ],
      ),
    );

    if (shouldDelete != true) return;
    await Provider.of<TodoSummaryProvider>(context, listen: false)
        .deleteTodo(itemToDelete);
    HapticFeedback.lightImpact();

    if (mounted) {
      showAppSnackBar(context, s.taskDeleted,
          icon: Icons.delete_outline, iconColor: Colors.red);
      await NotificationManager.cancelTodoNotification(context, itemToDelete);
    }
  }

  List<TodoItem> _getFilteredAndSortedTodos() {
    final s = AppLocalizations.of(context)!;
    List<TodoItem> currentTodos = List.from(_rawTodos);

    currentTodos = currentTodos.where((todo) {
      if (_currentList == s.allListsTitle) return true;
      if (_currentList == s.defaultList)
        return todo.listName == null || todo.listName == s.defaultList;
      return todo.listName == _currentList;
    }).toList();

    currentTodos = currentTodos.where((todo) {
      switch (_currentFilter) {
        case TaskFilter.active:
          return !todo.isCompleted;
        case TaskFilter.completed:
          return todo.isCompleted;
        case TaskFilter.all:
          return true;
      }
    }).toList();

    currentTodos.sort((a, b) {
      if (a.isCompleted != b.isCompleted) return a.isCompleted ? 1 : -1;
      if (!a.isCompleted) {
        if (a.dueDate == null && b.dueDate == null)
          return b.creationDate.compareTo(a.creationDate);
        if (a.dueDate == null) return 1;
        if (b.dueDate == null) return -1;
      }
      switch (_currentSort) {
        case TaskSort.dueDateAsc:
          return a.dueDate!.compareTo(b.dueDate!);
        case TaskSort.dueDateDesc:
          return b.dueDate!.compareTo(a.dueDate!);
        case TaskSort.titleAsc:
          return a.title.toLowerCase().compareTo(b.title.toLowerCase());
        case TaskSort.titleDesc:
          return b.title.toLowerCase().compareTo(a.title.toLowerCase());
      }
    });
    return currentTodos;
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    final displayedTodos = _getFilteredAndSortedTodos();
    final availableLists = [
      s.allListsTitle,
      s.personal,
      s.work,
      s.shopping,
      s.defaultList
    ];

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: _currentList,
            dropdownColor: Theme.of(context).appBarTheme.backgroundColor,
            style: Theme.of(context).appBarTheme.titleTextStyle,
            icon: Icon(Icons.arrow_drop_down,
                color: Theme.of(context).colorScheme.onPrimary),
            onChanged: (v) => setState(() => _currentList = v!),
            items: availableLists
                .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                .toList(),
          ),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                SortChip(
                  currentSort: _currentSort,
                  onSortChanged: (sort) => setState(() => _currentSort = sort),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TaskFilterChips(
                    currentFilter: _currentFilter,
                    onFilterChanged: (filter) =>
                        setState(() => _currentFilter = filter),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _rawTodos.isEmpty
                ? _buildEmptyState(
                    Icons.checklist_rtl, s.noTasksIllustrationText)
                : displayedTodos.isEmpty
                    ? _buildEmptyState(
                        Icons.task_alt_outlined, s.noMatchingTasks)
                    : ListView.builder(
                        itemCount: displayedTodos.length,
                        itemBuilder: (context, index) {
                          final todo = displayedTodos[index];
                          final uniqueKey = ValueKey(
                              todo.creationDate.toIso8601String() + todo.title);
                          return Dismissible(
                            key: uniqueKey,
                            confirmDismiss: (dir) {
                              if (dir == DismissDirection.startToEnd)
                                _editTodo(todo);
                              else
                                _markAsDone(todo);
                              return Future.value(false);
                            },
                            background: _buildDismissibleBackground(
                                s.edit,
                                Icons.edit,
                                Alignment.centerLeft,
                                Theme.of(context).primaryColor),
                            secondaryBackground: _buildDismissibleBackground(
                                todo.isCompleted ? s.undo : s.done,
                                todo.isCompleted ? Icons.undo : Icons.check,
                                Alignment.centerRight,
                                Colors.green),
                            child: GestureDetector(
                              onLongPress: () {
                                HapticFeedback.mediumImpact();
                                _showTaskOptions(todo);
                              },
                              child: DeadlineTile(todoItem: todo),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          HapticFeedback.lightImpact();
          Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => const TodoDetailScreen()));
        },
        backgroundColor: Theme.of(context).colorScheme.secondary,
        foregroundColor: Theme.of(context).colorScheme.onSecondary,
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }

  Widget _buildDismissibleBackground(
      String text, IconData icon, Alignment alignment, Color color) {
    return Container(
      color: color,
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: alignment == Alignment.centerLeft
            ? [
                Icon(icon, color: Colors.white),
                const SizedBox(width: 8),
                Text(text,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold))
              ]
            : [
                Text(text,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                Icon(icon, color: Colors.white)
              ],
      ),
    );
  }

  void _showTaskOptions(TodoItem todo) {
    final s = AppLocalizations.of(context)!;
    showDialog(
        context: context,
        builder: (context) => SimpleDialog(
              title: Text(s.taskOptions,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              children: [
                SimpleDialogOption(
                    onPressed: () {
                      Navigator.pop(context);
                      _editTodo(todo);
                    },
                    child: Row(children: [
                      const Icon(Icons.edit),
                      const SizedBox(width: 8),
                      Text(s.editTask)
                    ])),
                SimpleDialogOption(
                    onPressed: () {
                      Navigator.pop(context);
                      _markAsDone(todo);
                    },
                    child: Row(children: [
                      Icon(todo.isCompleted ? Icons.undo : Icons.check),
                      const SizedBox(width: 8),
                      Text(todo.isCompleted ? s.markAsNotDone : s.markAsDone)
                    ])),
                SimpleDialogOption(
                    onPressed: () {
                      Navigator.pop(context);
                      _deleteTodo(todo);
                    },
                    child: Row(children: [
                      const Icon(Icons.delete, color: Colors.redAccent),
                      const SizedBox(width: 8),
                      Text(s.deleteTask,
                          style: const TextStyle(color: Colors.redAccent))
                    ])),
              ],
            ));
  }

  Widget _buildEmptyState(IconData icon, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon,
              size: 80,
              color:
                  Theme.of(context).colorScheme.onBackground.withOpacity(0.4)),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onBackground
                        .withOpacity(0.7),
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class TodoDetailScreen extends StatefulWidget {
  final TodoItem? todoItem;
  const TodoDetailScreen({super.key, this.todoItem});

  @override
  State<TodoDetailScreen> createState() => _TodoDetailScreenState();
}

class _TodoDetailScreenState extends State<TodoDetailScreen> {
  final TextEditingController _titleController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String? _selectedRepeatInterval;
  String? _selectedListName;
  bool _isEditing = false;
  late DateTime _creationDate;
  bool _notificationsEnabled = true;
  bool _globalTodoNotificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadGlobalNotificationSetting();
    if (widget.todoItem != null) {
      _isEditing = true;
      _titleController.text = widget.todoItem!.title;
      _selectedDate = widget.todoItem!.dueDate;
      _selectedTime = widget.todoItem!.dueTime;
      _selectedRepeatInterval = widget.todoItem!.repeatInterval;
      _selectedListName = widget.todoItem!.listName;
      _creationDate = widget.todoItem!.creationDate;
      _notificationsEnabled = (widget.todoItem!.dueDate != null ||
          widget.todoItem!.dueTime != null);
    } else {
      _creationDate = DateTime.now();
      _notificationsEnabled = false;
    }
  }

  Future<void> _loadGlobalNotificationSetting() async {
    final prefs = await SharedPreferences.getInstance();
    final globalEnabled = prefs.getBool('notif_todo_enabled') ?? true;
    if (mounted) {
      setState(() {
        _globalTodoNotificationsEnabled = globalEnabled;
        // If global notifications are disabled, disable per-task notifications
        if (!globalEnabled) {
          _notificationsEnabled = false;
        }
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    FocusScope.of(context).unfocus();
    HapticFeedback.lightImpact();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 5)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
      locale: Localizations.localeOf(context),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _notificationsEnabled = true;
      });
    }
  }

  Future<void> _pickTime() async {
    FocusScope.of(context).unfocus();
    HapticFeedback.lightImpact();
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
        _notificationsEnabled = true;
      });
    }
  }

  void _saveTask() async {
    final s = AppLocalizations.of(context)!;
    final String title = _titleController.text.trim();
    if (title.isEmpty) {
      showAppSnackBar(context, s.emptyTaskError,
          icon: Icons.warning_amber_outlined, iconColor: Colors.orange);
      return;
    }
    HapticFeedback.lightImpact();

    final TodoItem todoToSave = TodoItem(
      title: title,
      isCompleted: widget.todoItem?.isCompleted ?? false,
      dueDate: _notificationsEnabled ? _selectedDate : null,
      dueTime: _notificationsEnabled ? _selectedTime : null,
      isRepeating: _notificationsEnabled &&
          _selectedRepeatInterval != null &&
          _selectedRepeatInterval != s.noRepeat,
      repeatInterval:
          _notificationsEnabled && _selectedRepeatInterval != s.noRepeat
              ? _selectedRepeatInterval
              : null,
      listName: _selectedListName == s.defaultList ? null : _selectedListName,
      creationDate: _creationDate,
    );

    await Provider.of<TodoSummaryProvider>(context, listen: false)
        .saveTodo(todoToSave);
    await NotificationManager.scheduleTodoNotification(context, todoToSave, s);

    if (mounted) {
      showAppSnackBar(context, s.taskSaved,
          icon: Icons.check, iconColor: Colors.green);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    final repeatOptions = [s.noRepeat, s.daily, s.weekly, s.monthly];
    final listOptions = [s.defaultList, s.personal, s.work, s.shopping];

    _selectedRepeatInterval ??= (widget.todoItem?.isRepeating == true
        ? widget.todoItem!.repeatInterval
        : s.noRepeat);
    _selectedListName ??= widget.todoItem?.listName ?? s.defaultList;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? s.editTaskTitle : s.newTaskTitle),
        actions: [
          IconButton(icon: const Icon(Icons.check), onPressed: _saveTask)
        ],
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSectionHeader(s.whatIsToBeDone),
              const SizedBox(height: 8),
              TextField(
                controller: _titleController,
                decoration: InputDecoration(hintText: s.enterYourTaskHere),
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              _buildSectionHeader(s.dueDate),
              _buildDateTimePicker(
                icon: Icons.calendar_today_outlined,
                text: _selectedDate == null
                    ? s.notSet
                    : DateFormat.yMMMd(
                            Localizations.localeOf(context).toLanguageTag())
                        .format(_selectedDate!),
                onTap: _pickDate,
                onClear: () => setState(() {
                  _selectedDate = null;
                  if (_selectedTime == null) _notificationsEnabled = false;
                }),
              ),
              const SizedBox(height: 10),
              _buildSectionHeader(s.dueTime),
              _buildDateTimePicker(
                icon: Icons.access_time,
                text: _selectedTime == null
                    ? s.notSet
                    : MaterialLocalizations.of(context)
                        .formatTimeOfDay(_selectedTime!),
                onTap: _pickTime,
                onClear: () => setState(() {
                  _selectedTime = null;
                  if (_selectedDate == null) _notificationsEnabled = false;
                }),
              ),
              const SizedBox(height: 20),
              _buildSectionHeader(s.notifications),
              SwitchListTile(
                title: Text(s.enableNotifications),
                subtitle: !_globalTodoNotificationsEnabled 
                    ? Text(s.globalNotificationsDisabled ?? 'Global todo notifications are disabled')
                    : null,
                value: _notificationsEnabled,
                onChanged: _globalTodoNotificationsEnabled
                    ? (value) => setState(() {
                          _notificationsEnabled = value;
                        })
                    : null,
                tileColor: Theme.of(context).cardTheme.color,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              const SizedBox(height: 20),
              _buildSectionHeader(s.repeat),
              _buildDropdown(repeatOptions, _selectedRepeatInterval,
                  (v) => setState(() => _selectedRepeatInterval = v)),
              const SizedBox(height: 20),
              _buildSectionHeader(s.addToLlist),
              _buildDropdown(listOptions, _selectedListName,
                  (v) => setState(() => _selectedListName = v)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Text(title, style: Theme.of(context).textTheme.titleMedium));
  }

  Widget _buildDateTimePicker(
      {required IconData icon,
      required String text,
      required VoidCallback onTap,
      required VoidCallback onClear}) {
    return ListTile(
      leading: Icon(icon),
      title: Text(text),
      trailing: IconButton(icon: const Icon(Icons.close), onPressed: onClear),
      onTap: onTap,
      tileColor: Theme.of(context).cardTheme.color,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  Widget _buildDropdown(
      List<String> options, String? value, ValueChanged<String?> onChanged,
      {bool enabled = true}) {
    return DropdownButtonFormField<String>(
      value: value,
      items: options
          .map((v) => DropdownMenuItem(value: v, child: Text(v)))
          .toList(),
      onChanged: enabled ? onChanged : null,
      decoration: InputDecoration(
          filled: true,
          fillColor: enabled
              ? Theme.of(context).cardTheme.color
              : Theme.of(context).disabledColor.withOpacity(0.1),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0)),
    );
  }
}
