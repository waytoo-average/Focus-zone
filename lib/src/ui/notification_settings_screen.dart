import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:app/notification_manager.dart';

// --- Notification Settings Logic ---
enum TaskNotificationTimeOption {
  atDeadline,
  min5,
  min15,
  min30,
  hr1,
  hr2,
  hr3,
}

class NotificationSettingsState extends ChangeNotifier {
  bool prayerEnabled = true;
  bool prayerVibration = true;
  bool todoEnabled = true;
  bool quranEnabled = true;
  bool todoVibration = true;
  bool quranVibration = true;
  TaskNotificationTimeOption taskTime = TaskNotificationTimeOption.atDeadline;
  TaskNotificationTimeOption prayerTime = TaskNotificationTimeOption.atDeadline;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    prayerEnabled = prefs.getBool('notif_prayer_enabled') ?? true;
    prayerVibration = prefs.getBool('notif_prayer_vibration') ?? true;
    todoEnabled = prefs.getBool('notif_todo_enabled') ?? true;
    quranEnabled = prefs.getBool('notif_quran_enabled') ?? true;
    todoVibration = prefs.getBool('notif_todo_vibration') ?? true;
    quranVibration = prefs.getBool('notif_quran_vibration') ?? true;
    final idx = prefs.getInt('notif_task_time') ?? 0;
    taskTime = TaskNotificationTimeOption.values[idx];
    final prayerIdx = prefs.getInt('notif_prayer_time') ?? 0;
    prayerTime = TaskNotificationTimeOption.values[prayerIdx];
    notifyListeners();
  }

  Future<void> setTodoEnabled(bool v) async {
    todoEnabled = v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notif_todo_enabled', v);
    notifyListeners();
  }
  Future<void> setQuranEnabled(bool v) async {
    quranEnabled = v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notif_quran_enabled', v);
    notifyListeners();
  }
  Future<void> setQuranVibration(bool v) async {
    quranVibration = v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notif_quran_vibration', v);
    notifyListeners();
  }
  Future<void> setPrayerEnabled(bool v, BuildContext context, AppLocalizations s) async {
    prayerEnabled = v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notif_prayer_enabled', v);
    notifyListeners();
    if (v) {
      await NotificationManager.schedulePrayerNotifications(context, s);
    } else {
      await NotificationManager.cancelAllPrayerNotifications(context);
    }
  }

  Future<void> setTaskTime(TaskNotificationTimeOption t, BuildContext context, AppLocalizations s) async {
    taskTime = t;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('notif_task_time', t.index);
    notifyListeners();
    
    // Reschedule all existing todo notifications with new timing
    if (todoEnabled) {
      await NotificationManager.rescheduleAllTodoNotifications(context, s);
    }
  }

  Future<void> setTodoVibration(bool v) async {
    todoVibration = v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notif_todo_vibration', v);
    notifyListeners();
  }

  Future<void> setPrayerVibration(bool v) async {
    prayerVibration = v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notif_prayer_vibration', v);
    notifyListeners();
  }

  Future<void> setPrayerTime(TaskNotificationTimeOption t, BuildContext context, AppLocalizations s) async {
    prayerTime = t;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('notif_prayer_time', t.index);
    notifyListeners();
    
    // Reschedule prayer notifications with new timing
    if (prayerEnabled) {
      await NotificationManager.schedulePrayerNotifications(context, s);
    }
  }
}

// --- Notification Settings Screen ---
class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  late NotificationSettingsState state;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    state = NotificationSettingsState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    await state.load();
    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(s.notificationSettingsTitle),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return ChangeNotifierProvider.value(
      value: state,
      child: Scaffold(
        appBar: AppBar(
          title: Text(s.notificationSettingsTitle),
        ),
        body: Consumer<NotificationSettingsState>(
          builder: (context, state, child) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Todo Notifications Card ---
                  Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        children: [
                          SwitchListTile(
                            value: state.todoEnabled,
                            onChanged: state.setTodoEnabled,
                            title: Text(s.todoNotifications),
                            secondary: const Icon(Icons.check_circle_outline),
                          ),
                          SwitchListTile(
                            value: state.todoVibration,
                            onChanged: state.todoEnabled ? state.setTodoVibration : null,
                            title: Text(s.todoVibration),
                            secondary: const Icon(Icons.vibration),
                            subtitle: Text(s.todoVibrationSubtitle),
                          ),
                          ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                            leading: const Icon(Icons.schedule_outlined),
                            title: Text(s.taskReminderTime),
                            trailing: Text(_getTimeOptionLabel(state.taskTime, s)),
                            onTap: () async {
                              final selected = await showModalBottomSheet<TaskNotificationTimeOption>(
                                context: context,
                                builder: (ctx) => _TaskTimeSelector(
                                  selected: state.taskTime,
                                  s: s,
                                ),
                              );
                              if (selected != null) {
                                await state.setTaskTime(selected, context, s);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  // --- Prayer Notifications Card ---
                  Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        children: [
                          SwitchListTile(
                            value: state.prayerEnabled,
                            onChanged: (v) => state.setPrayerEnabled(v, context, s),
                            title: Text(s.prayerNotifications),
                            secondary: const Icon(Icons.notifications_active_outlined),
                          ),
                          SwitchListTile(
                            value: state.prayerVibration,
                            onChanged: state.prayerEnabled ? state.setPrayerVibration : null,
                            title: Text(s.prayerVibration),
                            secondary: const Icon(Icons.vibration),
                            subtitle: Text(s.prayerVibrationSubtitle),
                          ),
                          ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                            leading: const Icon(Icons.schedule_outlined),
                            title: Text(s.prayerReminderTime),
                            trailing: Text(state.prayerTime == TaskNotificationTimeOption.atDeadline ? s.atPrayerTime : _getTimeOptionLabel(state.prayerTime, s)),
                            onTap: () async {
                              final selected = await showModalBottomSheet<TaskNotificationTimeOption>(
                                context: context,
                                builder: (ctx) => _PrayerTimeSelector(
                                  selected: state.prayerTime,
                                  s: s,
                                ),
                              );
                              if (selected != null) {
                                await state.setPrayerTime(selected, context, s);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  // --- Quran Notifications Card ---
                  Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        children: [
                          SwitchListTile(
                            value: state.quranEnabled,
                            onChanged: state.setQuranEnabled,
                            title: Text(s.quranDownloadNotifications),
                            secondary: const Icon(Icons.bookmark_added_outlined),
                          ),
                          SwitchListTile(
                            value: state.quranVibration,
                            onChanged: state.quranEnabled ? state.setQuranVibration : null,
                            title: Text(s.quranVibration),
                            secondary: const Icon(Icons.vibration),
                            subtitle: Text(s.quranVibrationSubtitle),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  String _getTimeOptionLabel(TaskNotificationTimeOption option, AppLocalizations s) {
    switch (option) {
      case TaskNotificationTimeOption.atDeadline:
        return s.atDeadline;
      case TaskNotificationTimeOption.min5:
        return s.min5;
      case TaskNotificationTimeOption.min15:
        return s.min15;
      case TaskNotificationTimeOption.min30:
        return s.min30;
      case TaskNotificationTimeOption.hr1:
        return s.hr1;
      case TaskNotificationTimeOption.hr2:
        return s.hr2;
      case TaskNotificationTimeOption.hr3:
        return s.hr3;
    }
  }
}

class _TaskTimeSelector extends StatelessWidget {
  final TaskNotificationTimeOption selected;
  final AppLocalizations s;
  const _TaskTimeSelector({required this.selected, required this.s});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(s.taskReminderTime,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                for (final option in TaskNotificationTimeOption.values)
                  _TimeOptionChip(
                    label: _getTimeOptionLabel(option, s),
                    selected: selected == option,
                    onTap: () => Navigator.of(context).pop(option),
                  )
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  String _getTimeOptionLabel(TaskNotificationTimeOption option, AppLocalizations s) {
    switch (option) {
      case TaskNotificationTimeOption.atDeadline:
        return s.atDeadline;
      case TaskNotificationTimeOption.min5:
        return s.min5;
      case TaskNotificationTimeOption.min15:
        return s.min15;
      case TaskNotificationTimeOption.min30:
        return s.min30;
      case TaskNotificationTimeOption.hr1:
        return s.hr1;
      case TaskNotificationTimeOption.hr2:
        return s.hr2;
      case TaskNotificationTimeOption.hr3:
        return s.hr3;
    }
  }
}

class _PrayerTimeSelector extends StatelessWidget {
  final TaskNotificationTimeOption selected;
  final AppLocalizations s;
  const _PrayerTimeSelector({required this.selected, required this.s});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(s.prayerReminderTime,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                for (final option in TaskNotificationTimeOption.values)
                  _TimeOptionChip(
                    label: _getPrayerTimeOptionLabel(option, s),
                    selected: selected == option,
                    onTap: () => Navigator.of(context).pop(option),
                  )
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  String _getPrayerTimeOptionLabel(TaskNotificationTimeOption option, AppLocalizations s) {
    switch (option) {
      case TaskNotificationTimeOption.atDeadline:
        return s.atPrayerTime;
      case TaskNotificationTimeOption.min5:
        return s.min5;
      case TaskNotificationTimeOption.min15:
        return s.min15;
      case TaskNotificationTimeOption.min30:
        return s.min30;
      case TaskNotificationTimeOption.hr1:
        return s.hr1;
      case TaskNotificationTimeOption.hr2:
        return s.hr2;
      case TaskNotificationTimeOption.hr3:
        return s.hr3;
    }
  }
}

class _TimeOptionChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _TimeOptionChip({required this.label, required this.selected, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.15),
      backgroundColor: Theme.of(context).chipTheme.backgroundColor,
      labelStyle: TextStyle(
        color: selected
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).textTheme.bodyMedium?.color,
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
}
