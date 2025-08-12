// lib/zikr_features.dart

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui' as ui;

import 'package:app/database_helper.dart';
import 'package:app/azkar_data.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:app/app_core.dart';
import 'src/ui/widgets/quran_entry_screen.dart';

// --- Zikr Main Screen ---
class ZikrScreen extends StatelessWidget {
  const ZikrScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;

    return DefaultTabController(
      length: 3,
      child: Directionality(
        textDirection: ui.TextDirection.ltr,
        child: Scaffold(
          appBar: AppBar(
            title: Text(s.zikr),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(kToolbarHeight),
              child: TabBar(
                indicatorColor: Theme.of(context).colorScheme.secondary,
                tabs: [
                  Tab(text: s.azkar),
                  Tab(text: s.quran),
                  Tab(text: s.prayerTimes),
                ],
              ),
            ),
          ),
          body: const TabBarView(
            children: [
              AzkarSection(),
              QuranSection(),
              PrayerTimesSection(),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Azkar Section ---
class AzkarSection extends StatelessWidget {
  const AzkarSection({super.key});
  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildAzkarCard(
          context,
          title: s.morningRemembrance,
          icon: Icons.wb_sunny_outlined,
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => AzkarViewerScreen(
                title: s.morningRemembrance,
                azkarList: morningAzkar,
              ),
            ));
          },
        ),
        const SizedBox(height: 16),
        _buildAzkarCard(
          context,
          title: s.eveningRemembrance,
          icon: Icons.brightness_3_outlined,
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => AzkarViewerScreen(
                title: s.eveningRemembrance,
                azkarList: eveningAzkar,
              ),
            ));
          },
        ),
        const SizedBox(height: 16),
        _buildAzkarCard(
          context,
          title: s.myAzkarTitle,
          icon: Icons.format_list_bulleted_rounded,
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => const MyAzkarScreen(),
            ));
          },
        ),
      ],
    );
  }

  Widget _buildAzkarCard(BuildContext context,
      {required String title,
      required IconData icon,
      required VoidCallback onTap}) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.secondary),
        title: Text(title),
        trailing: Icon(Icons.arrow_forward_ios,
            color: Theme.of(context).iconTheme.color?.withOpacity(0.6)),
        onTap: onTap,
      ),
    );
  }
}

// --- Azkar Viewer ---
class AzkarViewerScreen extends StatefulWidget {
  final String title;
  final List<Zikr> azkarList;

  const AzkarViewerScreen(
      {super.key, required this.title, required this.azkarList});

  @override
  State<AzkarViewerScreen> createState() => _AzkarViewerScreenState();
}

class _AzkarViewerScreenState extends State<AzkarViewerScreen> {
  late PageController _pageController;
  int _currentPage = 0;
  late int _currentCount;
  late int _initialCount;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    if (widget.azkarList.isNotEmpty) {
      _initializeCountsForPage(0);
    }
  }

  void _initializeCountsForPage(int page) {
    if (!mounted || widget.azkarList.isEmpty) return;
    setState(() {
      _currentPage = page;
      _initialCount = widget.azkarList[page].count;
      _currentCount = _initialCount;
    });
  }

  void _onCounterTapped() {
    if (_currentCount > 0) {
      if (!mounted) return;
      setState(() {
        _currentCount--;
      });
      HapticFeedback.lightImpact();

      if (_currentCount == 0) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (!mounted) return;
          if (_currentPage < widget.azkarList.length - 1) {
            _pageController.nextPage(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
            );
          } else {
            final s = AppLocalizations.of(context)!;
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(s.azkarCompleted),
              backgroundColor: Colors.green,
            ));
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = AppLocalizations.of(context)!;

    if (widget.azkarList.isEmpty) {
      return Scaffold(
          appBar: AppBar(title: Text(widget.title)),
          body: const Center(child: Text("No Azkar in this list.")));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: theme.appBarTheme.elevation,
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: widget.azkarList.length,
                reverse: false,
                onPageChanged: (page) {
                  _initializeCountsForPage(page);
                },
                itemBuilder: (context, index) {
                  final zikr = widget.azkarList[index];
                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20.0, vertical: 24.0),
                    child: Column(
                      children: [
                        Card(
                          elevation: theme.cardTheme.elevation,
                          color: theme.cardTheme.color,
                          shape: theme.cardTheme.shape,
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Text(
                              zikr.arabicText,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 20,
                                height: 1.7,
                                fontFamily: 'Amiri',
                                color: theme.textTheme.bodyLarge?.color,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (zikr.description.isNotEmpty)
                          Card(
                            elevation: theme.cardTheme.elevation,
                            color: theme.cardTheme.color,
                            shape: theme.cardTheme.shape,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Text(
                                zikr.description,
                                textAlign: TextAlign.start,
                                style: TextStyle(
                                  fontSize: 14,
                                  height: 1.5,
                                  color: theme.textTheme.bodyMedium?.color,
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  );
                },
              ),
            ),
            _buildBottomCounterBar(theme, s),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomCounterBar(ThemeData theme, AppLocalizations s) {
    final progress = _initialCount > 0 ? _currentCount / _initialCount : 0.0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(
          top: BorderSide(
            color: theme.dividerColor.withOpacity(0.08),
            width: 1.0,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            s.azkarTime(_initialCount),
            style: TextStyle(
                color: theme.textTheme.bodyLarge?.color,
                fontSize: 16,
                fontWeight: FontWeight.w500),
          ),
          GestureDetector(
            onTap: _onCounterTapped,
            child: SizedBox(
              width: 70,
              height: 70,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(
                    value: 1.0,
                    strokeWidth: 5,
                    backgroundColor:
                        theme.colorScheme.onSurface.withOpacity(0.1),
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Colors.transparent),
                  ),
                  CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 5,
                    valueColor: AlwaysStoppedAnimation<Color>(
                        theme.colorScheme.secondary),
                    strokeCap: StrokeCap.round,
                  ),
                  Center(
                    child: Text(
                      "$_currentCount",
                      style: TextStyle(
                          color: theme.textTheme.bodyLarge?.color,
                          fontSize: 22,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Text(
            s.azkarPage(_currentPage + 1, widget.azkarList.length),
            style: TextStyle(
                color: theme.textTheme.bodyLarge?.color,
                fontSize: 16,
                fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

// --- NEW: MY AZKAR FEATURE ---

// Screen 1: The main list of saved custom Azkar
class MyAzkarScreen extends StatefulWidget {
  const MyAzkarScreen({super.key});

  @override
  _MyAzkarScreenState createState() => _MyAzkarScreenState();
}

class _MyAzkarScreenState extends State<MyAzkarScreen> {
  final dbHelper = DatabaseHelper.instance;
  List<CustomZikr> _myAzkar = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _refreshAzkarList();
  }

  void _refreshAzkarList() async {
    setState(() => _isLoading = true);
    final data = await dbHelper.getAzkar();
    setState(() {
      _myAzkar = data;
      _isLoading = false;
    });
  }

  void _navigateAndRefresh(Widget screen) {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => screen))
        .then((_) {
      _refreshAzkarList();
    });
  }

  void _handleDelete(int index) {
    final zikrToDelete = _myAzkar[index];
    setState(() {
      _myAzkar.removeAt(index);
    });

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context)
        .showSnackBar(
          SnackBar(
            content: Text("'${zikrToDelete.text}' deleted."),
            // FIX: Using default snackbar color which is less aggressive
            action: SnackBarAction(
              label: 'Undo', // Add translation key if needed
              onPressed: () {
                setState(() {
                  _myAzkar.insert(index, zikrToDelete);
                });
              },
            ),
          ),
        )
        .closed
        .then((reason) {
      if (reason != SnackBarClosedReason.action) {
        dbHelper.delete(zikrToDelete.id!);
      }
    });
  }

  void _showQuickAddSheet(AppLocalizations s) {
    final suggestions = {
      s.suggestion1: 33,
      s.suggestion2: 33,
      s.suggestion3: 33,
      s.suggestion4: 100,
    };

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor, // FIX: Opaque background
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        // FIX: Wrap with SingleChildScrollView to prevent overflow
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.quickAddTitle,
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 2.2,
                  ),
                  itemCount: suggestions.length,
                  itemBuilder: (context, index) {
                    final entry = suggestions.entries.elementAt(index);
                    return _SuggestionCard(
                      text: entry.key,
                      count: entry.value,
                      onTap: () async {
                        final newZikr = CustomZikr(
                            text: entry.key,
                            targetCount: entry.value,
                            currentCount: entry.value);
                        await dbHelper.insert(newZikr);
                        Navigator.of(context).pop();
                        _refreshAzkarList();
                      },
                    );
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final todayString =
        "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}";

    return Scaffold(
      appBar: AppBar(
        title: Text(s.myAzkarTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.lightbulb_outline),
            tooltip: s.quickAddTitle,
            onPressed: () => _showQuickAddSheet(s),
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _myAzkar.isEmpty
              ? Center(
                  child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text(
                    s.emptyAzkarList,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium,
                  ),
                ))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 80),
                  itemCount: _myAzkar.length,
                  itemBuilder: (context, index) {
                    final zikr = _myAzkar[index];
                    final isCompletedToday =
                        zikr.lastCompletedDate == todayString;

                    return Dismissible(
                      key: Key(zikr.id.toString()),
                      direction: DismissDirection.endToStart,
                      onDismissed: (direction) {
                        _handleDelete(index);
                      },
                      background: Container(
                        decoration: BoxDecoration(
                          color: Colors.red[700],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: const Icon(Icons.delete_sweep_outlined,
                            color: Colors.white),
                      ),
                      child: Card(
                        elevation: 2,
                        color: isCompletedToday
                            ? Color.lerp(theme.cardColor, Colors.green, 0.25)
                            : theme.cardColor,
                        child: ListTile(
                          onTap: () {
                            Navigator.of(context)
                                .push(MaterialPageRoute(
                                  builder: (_) =>
                                      PerformCustomZikrScreen(zikr: zikr),
                                ))
                                .then((_) => _refreshAzkarList());
                          },
                          leading: Checkbox(
                            value: isCompletedToday,
                            onChanged: null, // Make it read-only
                            activeColor: Colors.green,
                          ),
                          title: Text(zikr.text,
                              maxLines: 2, overflow: TextOverflow.ellipsis),
                          subtitle: zikr.dailyCount > 0
                              ? Text(s.dailyCountLabel(zikr.dailyCount),
                                  style: const TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold))
                              : null,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(s.azkarTime(zikr.targetCount),
                                  style: theme.textTheme.titleMedium),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.edit, size: 20),
                                onPressed: () => _navigateAndRefresh(
                                    AddEditCustomZikrScreen(zikrToEdit: zikr)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const QuickCounterScreen())),
            heroTag: 'quickCounter',
            mini: true,
            child: const Icon(Icons.flash_on),
          ),
          const SizedBox(width: 8),
          FloatingActionButton(
            onPressed: () =>
                _navigateAndRefresh(const AddEditCustomZikrScreen()),
            heroTag: 'addZikr',
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  final String text;
  final int count;
  final VoidCallback onTap;

  const _SuggestionCard(
      {required this.text, required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          // FIX: Wrap with a Flexible widget to handle text wrapping
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(
                child: Text(text,
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 2, // Allow text to wrap to 2 lines
                    overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(height: 4),
              Text(s.azkarTime(count),
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

// Screen 2: Add or Edit a custom Zikr
class AddEditCustomZikrScreen extends StatefulWidget {
  final CustomZikr? zikrToEdit;

  const AddEditCustomZikrScreen({super.key, this.zikrToEdit});

  @override
  _AddEditCustomZikrScreenState createState() =>
      _AddEditCustomZikrScreenState();
}

class _AddEditCustomZikrScreenState extends State<AddEditCustomZikrScreen> {
  final _formKey = GlobalKey<FormState>();
  final _textController = TextEditingController();
  final _countController = TextEditingController();
  final dbHelper = DatabaseHelper.instance;

  @override
  void initState() {
    super.initState();
    if (widget.zikrToEdit != null) {
      _textController.text = widget.zikrToEdit!.text;
      _countController.text = widget.zikrToEdit!.targetCount.toString();
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _countController.dispose();
    super.dispose();
  }

  void _saveZikr() async {
    if (_formKey.currentState!.validate()) {
      final zikrText = _textController.text;
      final zikrCount = int.parse(_countController.text);

      final zikr = CustomZikr(
        id: widget.zikrToEdit?.id,
        text: zikrText,
        targetCount: zikrCount,
        currentCount: widget.zikrToEdit?.currentCount ?? zikrCount,
        dailyCount: widget.zikrToEdit?.dailyCount ?? 0,
        lastCompletedDate: widget.zikrToEdit?.lastCompletedDate,
      );

      if (widget.zikrToEdit == null) {
        await dbHelper.insert(zikr);
      } else {
        await dbHelper.update(zikr);
      }

      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isEditing = widget.zikrToEdit != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? s.editZikrTitle : s.addZikrTitle),
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () {
                showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                          title: Text(s.deleteConfirmationTitle),
                          content: Text(s.deleteConfirmationContent),
                          // FIX: Wrap actions to prevent overflow in any language
                          actions: <Widget>[
                            Wrap(
                              alignment: WrapAlignment.end,
                              spacing: 8.0,
                              children: [
                                TextButton(
                                  child: Text(s.cancel),
                                  onPressed: () => Navigator.of(context).pop(),
                                ),
                                TextButton(
                                  child: Text(s.delete,
                                      style:
                                          const TextStyle(color: Colors.red)),
                                  onPressed: () async {
                                    await dbHelper
                                        .delete(widget.zikrToEdit!.id!);
                                    if (mounted) {
                                      Navigator.of(context).pop();
                                      Navigator.of(context).pop();
                                    }
                                  },
                                ),
                              ],
                            )
                          ],
                        ));
              },
            )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(s.writeYourZikr, style: theme.textTheme.titleLarge),
              const SizedBox(height: 16),
              TextFormField(
                controller: _textController,
                maxLines: 5,
                style: const TextStyle(fontFamily: 'Amiri', fontSize: 20),
                decoration: InputDecoration(
                  hintText: s.zikrHint,
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return s.errorZikrEmpty;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              Text(s.setRepetitions, style: theme.textTheme.titleLarge),
              const SizedBox(height: 16),
              TextFormField(
                controller: _countController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineMedium,
                decoration: InputDecoration(
                  hintText: '33',
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return s.errorCountEmpty;
                  }
                  if ((int.tryParse(value) ?? 0) <= 0) {
                    return s.errorCountZero;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _saveZikr,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: theme.colorScheme.secondary,
                  foregroundColor: theme.colorScheme.onSecondary,
                ),
                child: Text(s.save, style: const TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Screen 3: The counter screen for a custom Zikr
class PerformCustomZikrScreen extends StatefulWidget {
  final CustomZikr zikr;

  const PerformCustomZikrScreen({super.key, required this.zikr});

  @override
  _PerformCustomZikrScreenState createState() =>
      _PerformCustomZikrScreenState();
}

class _PerformCustomZikrScreenState extends State<PerformCustomZikrScreen> {
  late int _currentCount;
  final dbHelper = DatabaseHelper.instance;

  @override
  void initState() {
    super.initState();
    _currentCount = widget.zikr.currentCount;
  }

  void _onCounterTapped() {
    if (_currentCount > 0) {
      HapticFeedback.lightImpact();
      setState(() {
        _currentCount--;
      });

      // Instantly save the new progress
      dbHelper.updateCurrentCount(widget.zikr.id!, _currentCount);

      if (_currentCount == 0) {
        dbHelper.completeZikr(widget.zikr.id!);

        final s = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(s.azkarCompleted),
          backgroundColor: Colors.green,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(s.myAzkarTitle),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20.0),
                  child: Card(
                    elevation: 3,
                    color: theme.cardTheme.color,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15.0),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        widget.zikr.text,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          height: 1.8,
                          fontFamily: 'Amiri',
                          color: theme.textTheme.bodyLarge?.color,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            _buildBottomCounterBar(theme, s),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomCounterBar(ThemeData theme, AppLocalizations s) {
    final progress = widget.zikr.targetCount > 0
        ? _currentCount / widget.zikr.targetCount
        : 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(
          top: BorderSide(
            color: theme.dividerColor.withOpacity(0.08),
            width: 1.0,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Text(
            s.azkarTime(widget.zikr.targetCount),
            style: TextStyle(
              color: theme.textTheme.bodyLarge?.color,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          GestureDetector(
            onTap: _onCounterTapped,
            child: SizedBox(
              width: 70,
              height: 70,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(
                    value: 1.0,
                    strokeWidth: 5,
                    backgroundColor:
                        theme.colorScheme.onSurface.withOpacity(0.1),
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Colors.transparent),
                  ),
                  CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 5,
                    valueColor: AlwaysStoppedAnimation<Color>(
                        theme.colorScheme.secondary),
                    strokeCap: StrokeCap.round,
                  ),
                  Center(
                    child: Text(
                      "$_currentCount",
                      style: TextStyle(
                        color: theme.textTheme.bodyLarge?.color,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// NEW: Quick Counter Screen
class QuickCounterScreen extends StatefulWidget {
  const QuickCounterScreen({super.key});

  @override
  State<QuickCounterScreen> createState() => _QuickCounterScreenState();
}

class _QuickCounterScreenState extends State<QuickCounterScreen> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
    HapticFeedback.lightImpact();
  }

  void _resetCounter() {
    setState(() {
      _counter = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(s.quickCounterTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetCounter,
            tooltip: s.reset,
          )
        ],
      ),
      body: GestureDetector(
        onTap: _incrementCounter,
        child: Container(
          color: Colors.transparent,
          child: Center(
            child: Text(
              '$_counter',
              style: theme.textTheme.displayLarge?.copyWith(
                fontSize: 180,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.secondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// --- 2. Quran Section (Placeholder) ---
class QuranSection extends StatelessWidget {
  const QuranSection({super.key});
  @override
  Widget build(BuildContext context) {
    return const QuranEntryScreen();
  }
}

// --- 3. Prayer Times Section (Existing Code) ---
class PrayerTimesSection extends StatefulWidget {
  const PrayerTimesSection({super.key});
  @override
  State<PrayerTimesSection> createState() => _PrayerTimesSectionState();
}

class _PrayerTimesSectionState extends State<PrayerTimesSection> {
  bool _isLoading = true;
  String? _errorMessage;
  PrayerData? _prayerData;
  Timer? _countdownTimer;
  Duration? _timeUntilNextPrayer;
  String? _nextPrayerName;
  Locale? _dataLocale;
  DateTime? _lastPrayerDay;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_prayerData == null) {
      _initializePrayerTimes();
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializePrayerTimes() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final langProvider = Provider.of<LanguageProvider>(context, listen: false);
    final currentLocale = langProvider.locale;
    final langCode = currentLocale.languageCode;

    final cachedData = await PrayerTimesCache.load();
    if (cachedData != null) {
      if (mounted) {
        setState(() {
          _prayerData = cachedData;
          _isLoading = false;
          _dataLocale = currentLocale;
          _calculateNextPrayer();
        });
        return;
      }
    }

    try {
      final position = await _determinePosition();
      final placemarks =
          await placemarkFromCoordinates(position.latitude, position.longitude);
      final locationName = placemarks.isNotEmpty
          ? '${placemarks.first.locality}, ${placemarks.first.administrativeArea}'
          : 'Unknown Location';

      final tune = '0,0,0,0,0,0,0,0';
      final uri = Uri.parse(
          'https://api.aladhan.com/v1/timings?latitude=${position.latitude}&longitude=${position.longitude}&method=5&tune=$tune');

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body)['data'];
        final newPrayerData = PrayerData.fromJson(data, locationName, langCode);
        if (mounted) {
          setState(() {
            _prayerData = newPrayerData;
            _isLoading = false;
            _dataLocale = currentLocale;
          });
          await PrayerTimesCache.save(newPrayerData);
          _calculateNextPrayer();
        }
      } else {
        throw Exception(AppLocalizations.of(context)!.failedToLoadPrayerTimes);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _calculateNextPrayer() {
    if (_prayerData == null) return;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    PrayerTime? nextPrayer;

    final prayerDateTimes = _prayerData!.timings.entries.map((entry) {
      final timeParts = entry.value.split(':');
      final prayerTime = DateTime(today.year, today.month, today.day,
          int.parse(timeParts[0]), int.parse(timeParts[1]));
      return MapEntry(entry.key, prayerTime);
    }).toList();

    for (var prayer in prayerDateTimes) {
      if (prayer.value.isAfter(now)) {
        nextPrayer = PrayerTime(name: prayer.key, time: prayer.value);
        break;
      }
    }

    if (nextPrayer == null) {
      final fajrEntry = prayerDateTimes.first;
      final tomorrowFajrTime = fajrEntry.value.add(const Duration(days: 1));
      nextPrayer = PrayerTime(name: fajrEntry.key, time: tomorrowFajrTime);
    }

    _startCountdown(nextPrayer);
  }

  void _startCountdown(PrayerTime nextPrayer) {
    _countdownTimer?.cancel();
    _nextPrayerName = nextPrayer.name;
    _lastPrayerDay = DateTime.now();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      final now = DateTime.now();
      final difference = nextPrayer.time.difference(now);
      if (_lastPrayerDay != null &&
          (now.year != _lastPrayerDay!.year ||
              now.month != _lastPrayerDay!.month ||
              now.day != _lastPrayerDay!.day)) {
        timer.cancel();
        _initializePrayerTimes();
        return;
      }
      if (difference.isNegative) {
        timer.cancel();
        _calculateNextPrayer();
      } else {
        setState(() {
          _timeUntilNextPrayer = difference;
        });
      }
    });
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    return await Geolocator.getCurrentPosition();
  }

  String _getLocalizedPrayerName(String prayerKey, AppLocalizations s) {
    if (prayerKey == 'Dhuhr') {
      final now = DateTime.now();
      if (now.weekday == DateTime.friday) {
        return s.prayerNameJumah;
      }
    }
    switch (prayerKey) {
      case 'Fajr':
        return s.prayerNameFajr;
      case 'Sunrise':
        return s.prayerNameSunrise;
      case 'Dhuhr':
        return s.prayerNameDhuhr;
      case 'Asr':
        return s.prayerNameAsr;
      case 'Maghrib':
        return s.prayerNameMaghrib;
      case 'Isha':
        return s.prayerNameIsha;
      default:
        return prayerKey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentLocale = Provider.of<LanguageProvider>(context).locale;
    final s = AppLocalizations.of(context)!;

    if (!_isLoading && _dataLocale != null && _dataLocale != currentLocale) {
      Future.microtask(() => _initializePrayerTimes());
    }

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(_errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.redAccent)),
        ),
      );
    }
    if (_prayerData == null) {
      return Center(child: Text(s.failedToLoadPrayerTimes));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _PrayerTimesHeader(prayerData: _prayerData!),
          const SizedBox(height: 24),
          ..._prayerData!.timings.entries.map((entry) {
            bool isNext = entry.key == _nextPrayerName;
            return _PrayerCard(
              prayerKey: entry.key,
              prayerTime: entry.value,
              isNext: isNext,
            );
          }).toList(),
          const SizedBox(height: 32),
          if (_timeUntilNextPrayer != null)
            _CountdownDisplay(
              duration: _timeUntilNextPrayer!,
              nextPrayerName: _getLocalizedPrayerName(_nextPrayerName ?? '', s),
            )
        ],
      ),
    );
  }
}

class PrayerData {
  final Map<String, String> timings;
  final String hijriDate;
  final String location;
  final String gregorianDate;
  final String langCode;

  PrayerData({
    required this.timings,
    required this.hijriDate,
    required this.location,
    required this.gregorianDate,
    required this.langCode,
  });

  factory PrayerData.fromJson(
      Map<String, dynamic> json, String location, String langCode) {
    final Map<String, dynamic> rawTimings = json['timings'];
    final Map<String, String> timings = {
      'Fajr': rawTimings['Fajr'].split(' ')[0],
      'Sunrise': rawTimings['Sunrise'].split(' ')[0],
      'Dhuhr': rawTimings['Dhuhr'].split(' ')[0],
      'Asr': rawTimings['Asr'].split(' ')[0],
      'Maghrib': rawTimings['Maghrib'].split(' ')[0],
      'Isha': rawTimings['Isha'].split(' ')[0],
    };

    final hijriData = json['date']['hijri'];
    final monthName =
        langCode == 'ar' ? hijriData['month']['ar'] : hijriData['month']['en'];
    final hijriDate = '${hijriData['day']} $monthName ${hijriData['year']}';
    final gregorianData = json['date']['gregorian'];
    final gregorianDate = gregorianData['date'];

    return PrayerData(
      timings: timings,
      hijriDate: hijriDate,
      location: location,
      gregorianDate: gregorianDate,
      langCode: langCode,
    );
  }

  Map<String, dynamic> toJson() => {
        'timings': timings,
        'hijriDate': hijriDate,
        'location': location,
        'gregorianDate': gregorianDate,
        'langCode': langCode,
      };

  factory PrayerData.fromJsonString(String jsonString) {
    final Map<String, dynamic> jsonMap = json.decode(jsonString);
    return PrayerData(
      timings: Map<String, String>.from(jsonMap['timings']),
      hijriDate: jsonMap['hijriDate'],
      location: jsonMap['location'],
      gregorianDate: jsonMap['gregorianDate'],
      langCode: jsonMap['langCode'] ?? 'en',
    );
  }
}

class PrayerTime {
  final String name;
  final DateTime time;
  PrayerTime({required this.name, required this.time});
}

class PrayerTimesCache {
  static const _kPrayerDataKey = 'prayerData';

  static Future<void> save(PrayerData data) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = json.encode(data.toJson());
    await prefs.setString(_kPrayerDataKey, jsonString);
  }

  static Future<PrayerData?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_kPrayerDataKey);
    if (jsonString == null) {
      return null;
    }
    final data = PrayerData.fromJsonString(jsonString);
    final today = DateFormat('dd-MM-yyyy').format(DateTime.now());
    if (data.gregorianDate == today) {
      return data;
    }
    return null;
  }
}

class _PrayerTimesHeader extends StatelessWidget {
  final PrayerData prayerData;
  const _PrayerTimesHeader({required this.prayerData});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(Icons.location_on,
            color: theme.textTheme.bodyLarge?.color, size: 20),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            prayerData.location,
            style: theme.textTheme.bodyLarge,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const Spacer(),
        Text(prayerData.hijriDate, style: theme.textTheme.bodyMedium),
      ],
    );
  }
}

class _PrayerCard extends StatelessWidget {
  final String prayerKey;
  final String prayerTime;
  final bool isNext;

  const _PrayerCard(
      {required this.prayerKey,
      required this.prayerTime,
      required this.isNext});

  String _getLocalizedPrayerName(String prayerKey, AppLocalizations s) {
    if (prayerKey == 'Dhuhr') {
      final now = DateTime.now();
      if (now.weekday == DateTime.friday) {
        return s.prayerNameJumah;
      }
    }
    switch (prayerKey) {
      case 'Fajr':
        return s.prayerNameFajr;
      case 'Sunrise':
        return s.prayerNameSunrise;
      case 'Dhuhr':
        return s.prayerNameDhuhr;
      case 'Asr':
        return s.prayerNameAsr;
      case 'Maghrib':
        return s.prayerNameMaghrib;
      case 'Isha':
        return s.prayerNameIsha;
      default:
        return prayerKey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final time24 = DateFormat('HH:mm').parse(prayerTime);
    final time12 = DateFormat.jm(Localizations.localeOf(context).languageCode)
        .format(time24);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      color: isNext ? theme.colorScheme.secondary.withOpacity(0.3) : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _getLocalizedPrayerName(prayerKey, s),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: isNext ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            Text(
              time12,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: isNext ? FontWeight.bold : FontWeight.normal,
                color: isNext ? theme.colorScheme.secondary : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CountdownDisplay extends StatelessWidget {
  final Duration duration;
  final String nextPrayerName;

  const _CountdownDisplay(
      {required this.duration, required this.nextPrayerName});

  String _formatDuration(Duration d) {
    final hours = d.inHours.toString().padLeft(2, '0');
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
          decoration: BoxDecoration(
            color: theme.cardTheme.color?.withOpacity(0.5),
            borderRadius: BorderRadius.circular(50),
          ),
          child: Text(
            _formatDuration(duration),
            style: theme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.bold,
              fontFeatures: [const FontFeature.tabularFigures()],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          s.untilNextPrayer(nextPrayerName),
          style: theme.textTheme.bodyLarge,
        )
      ],
    );
  }
}
