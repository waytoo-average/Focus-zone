// lib/zikr_features.dart

import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:app/azkar_data.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:app/app_core.dart'; // Import app_core for LanguageProvider

class ZikrScreen extends StatelessWidget {
  const ZikrScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(s.zikr),
          bottom: TabBar(
            indicatorColor: Theme.of(context).colorScheme.secondary,
            tabs: [
              Tab(text: s.azkar),
              Tab(text: s.quran),
              Tab(text: s.prayerTimes),
            ],
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
    );
  }
}

// --- 1. Azkar Section ---
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
          title: s.customZikr,
          icon: Icons.add_circle_outline,
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => const ZikrCounterScreen(),
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
    _initializeCountsForPage(0);
  }

  void _initializeCountsForPage(int page) {
    setState(() {
      _currentPage = page;
      _initialCount = widget.azkarList[page].count;
      _currentCount = _initialCount;
    });
  }

  void _onCounterTapped() {
    if (_currentCount > 0) {
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
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.azkarList.length,
              onPageChanged: (page) {
                _initializeCountsForPage(page);
              },
              itemBuilder: (context, index) {
                final zikr = widget.azkarList[index];
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        zikr.arabicText,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          height: 1.8,
                          fontFamily: 'Amiri',
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (zikr.description.isNotEmpty)
                        Text(
                          zikr.description,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            height: 1.5,
                            color:
                            Theme.of(context).textTheme.bodyMedium?.color,
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
          _buildBottomCounterBar(),
        ],
      ),
    );
  }

  Widget _buildBottomCounterBar() {
    final s = AppLocalizations.of(context)!;
    final progress = _initialCount > 0 ? _currentCount / _initialCount : 0.0;
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        color: theme.cardTheme.color?.withOpacity(0.5),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            s.azkarTime(_initialCount),
            style:
            TextStyle(color: theme.textTheme.bodyLarge?.color, fontSize: 18),
          ),
          GestureDetector(
            onTap: _onCounterTapped,
            child: SizedBox(
              width: 80,
              height: 80,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(
                    value: 1.0,
                    strokeWidth: 6,
                    backgroundColor:
                    theme.colorScheme.onSurface.withOpacity(0.2),
                    valueColor:
                    const AlwaysStoppedAnimation<Color>(Colors.transparent),
                  ),
                  CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 6,
                    valueColor:
                    AlwaysStoppedAnimation<Color>(theme.colorScheme.secondary),
                  ),
                  Center(
                    child: Text(
                      "$_currentCount",
                      style: TextStyle(
                          color: theme.textTheme.bodyLarge?.color,
                          fontSize: 24,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Text(
            s.azkarPage(_currentPage + 1, widget.azkarList.length),
            style:
            TextStyle(color: theme.textTheme.bodyLarge?.color, fontSize: 18),
          ),
        ],
      ),
    );
  }
}

class ZikrCounterScreen extends StatefulWidget {
  const ZikrCounterScreen({super.key});
  @override
  State<ZikrCounterScreen> createState() => _ZikrCounterScreenState();
}

class _ZikrCounterScreenState extends State<ZikrCounterScreen> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  void _resetCounter() {
    setState(() {
      _counter = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(s.zikrCounter),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetCounter,
            tooltip: 'Reset',
          )
        ],
      ),
      body: GestureDetector(
        onTap: _incrementCounter,
        child: Container(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$_counter',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    fontSize: 150,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  s.tapToCount,
                  style: const TextStyle(fontSize: 20),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --- 2. Quran Section ---
class QuranSection extends StatefulWidget {
  const QuranSection({super.key});
  @override
  State<QuranSection> createState() => _QuranSectionState();
}

class _QuranSectionState extends State<QuranSection> {
  Future<List<Surah>>? _surahsFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _surahsFuture = _fetchSurahs();
  }

  Future<List<Surah>> _fetchSurahs() async {
    try {
      final response =
      await http.get(Uri.parse('https://api.alquran.cloud/v1/surah'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body)['data'] as List;
        return data.map((surahJson) => Surah.fromJson(surahJson)).toList();
      } else {
        throw Exception(AppLocalizations.of(context)!.failedToLoadSurahs);
      }
    } catch (e) {
      developer.log('Error fetching surahs: $e', name: 'QuranSection');
      throw Exception(AppLocalizations.of(context)!.failedToLoadSurahs);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    return FutureBuilder<List<Surah>>(
      future: _surahsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (snapshot.hasData) {
          final surahs = snapshot.data!;
          return ListView.builder(
            itemCount: surahs.length,
            itemBuilder: (context, index) {
              final surah = surahs[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).primaryColor,
                    child: Text(
                      '${surah.number}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(surah.englishName),
                  subtitle: Text(surah.englishNameTranslation),
                  trailing: Text(
                    surah.name,
                    style: const TextStyle(fontFamily: 'Amiri', fontSize: 18),
                  ),
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => SurahDetailScreen(surah: surah),
                    ));
                  },
                ),
              );
            },
          );
        } else {
          return Center(child: Text(s.noSurahsFound));
        }
      },
    );
  }
}

class SurahDetailScreen extends StatefulWidget {
  final Surah surah;
  const SurahDetailScreen({super.key, required this.surah});
  @override
  State<SurahDetailScreen> createState() => _SurahDetailScreenState();
}

class _SurahDetailScreenState extends State<SurahDetailScreen> {
  Future<List<Ayah>>? _ayahsFuture;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _ayahsFuture = _fetchAyahs(widget.surah.number);
  }

  Future<List<Ayah>> _fetchAyahs(int surahNumber) async {
    try {
      final response = await http
          .get(Uri.parse('https://api.alquran.cloud/v1/surah/$surahNumber'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body)['data']['ayahs'] as List;
        return data.map((ayahJson) => Ayah.fromJson(ayahJson)).toList();
      } else {
        throw Exception(AppLocalizations.of(context)!.failedToLoadAyahs);
      }
    } catch (e) {
      developer.log('Error fetching ayahs: $e', name: 'QuranSection');
      throw Exception(AppLocalizations.of(context)!.failedToLoadAyahs);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.surah.englishName)),
      body: FutureBuilder<List<Ayah>>(
        future: _ayahsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData) {
            final ayahs = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: ayahs.length,
              itemBuilder: (context, index) {
                final ayah = ayahs[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      '${ayah.text} (${ayah.numberInSurah})',
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                          fontFamily: 'Amiri', fontSize: 22, height: 1.8),
                    ),
                  ),
                );
              },
            );
          } else {
            return const Center(child: Text('No Ayahs found.'));
          }
        },
      ),
    );
  }
}

class Surah {
  final int number;
  final String name;
  final String englishName;
  final String englishNameTranslation;

  Surah({
    required this.number,
    required this.name,
    required this.englishName,
    required this.englishNameTranslation,
  });

  factory Surah.fromJson(Map<String, dynamic> json) {
    return Surah(
      number: json['number'],
      name: json['name'],
      englishName: json['englishName'],
      englishNameTranslation: json['englishNameTranslation'],
    );
  }
}

class Ayah {
  final String text;
  final int numberInSurah;

  Ayah({required this.text, required this.numberInSurah});

  factory Ayah.fromJson(Map<String, dynamic> json) {
    return Ayah(
      text: json['text'],
      numberInSurah: json['numberInSurah'],
    );
  }
}

// --- 3. Prayer Times Section ---
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
  Locale? _dataLocale; // To track the locale of the current data

  @override
  void initState() {
    super.initState();
    // No initial data fetch here, it will be handled by didChangeDependencies
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Fetch data when the widget is first built or when dependencies change
    // This ensures it runs when the screen is first displayed.
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

    // First, try to load from cache
    final cachedData = await _PrayerTimesCache.load();
    if (cachedData != null) {
      if (mounted) {
        setState(() {
          _prayerData = cachedData;
          _isLoading = false;
          _dataLocale = currentLocale; // Assume cached data matches current locale for now
          _calculateNextPrayer();
        });
        // Even with cache, if locale is different, we might need to re-fetch for date format
        // This logic can be enhanced later if needed, but for now cache is simple
        return;
      }
    }

    // If no cache or stale, fetch from network
    try {
      final position = await _determinePosition();
      final placemarks =
      await placemarkFromCoordinates(position.latitude, position.longitude);
      final locationName = placemarks.isNotEmpty
          ? '${placemarks.first.locality}, ${placemarks.first.administrativeArea}'
          : 'Unknown Location';

      final tune = '0,0,3,0,2,0,2,0';
      final uri = Uri.parse(
          'https://api.aladhan.com/v1/timingsByCity?city=Cairo&country=Egypt&method=5&tune=$tune');

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body)['data'];
        final newPrayerData = PrayerData.fromJson(data, locationName, langCode);
        if (mounted) {
          setState(() {
            _prayerData = newPrayerData;
            _isLoading = false;
            _dataLocale = currentLocale; // Set the locale for the freshly fetched data
          });
          await _PrayerTimesCache.save(newPrayerData);
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
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      final now = DateTime.now();
      final difference = nextPrayer.time.difference(now);
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
    // FIX: Actively watch the language provider. If the locale changes,
    // this will trigger a rebuild and the check below will re-fetch the data.
    final currentLocale = Provider.of<LanguageProvider>(context).locale;
    final s = AppLocalizations.of(context)!;

    // If the widget is already loaded but the data's locale doesn't match the current locale,
    // it means the user changed the language. We need to re-fetch.
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
          child:
          Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.redAccent)),
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
              nextPrayerName:
              _getLocalizedPrayerName(_nextPrayerName ?? '', s),
            )
        ],
      ),
    );
  }
}

// Data Models & Cache
class PrayerData {
  final Map<String, String> timings;
  final String hijriDate;
  final String location;
  final String gregorianDate;
  final String langCode; // Store the language of this data

  PrayerData(
      {required this.timings,
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
      langCode: jsonMap['langCode'] ?? 'en', // default to en if not found
    );
  }
}

class PrayerTime {
  final String name;
  final DateTime time;
  PrayerTime({required this.name, required this.time});
}

class _PrayerTimesCache {
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

// UI Components
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