import 'package:flutter/material.dart';
import 'package:app/app_core.dart';
import '../../../l10n/app_localizations.dart';

class SurahListScreen extends StatelessWidget {
  final void Function(Surah surah) onSurahSelected;
  const SurahListScreen({Key? key, required this.onSurahSelected})
      : super(key: key);

  Future<List<Surah>> _loadSurahs() => SurahLoader.loadSurahs();

  Widget _buildTypeIcon(String type) {
    // Use Kaaba for Makki, Green Dome for Madani
    return type.contains('مكية')
        ? Image.asset('assets/icons/kaaba.png', width: 40, height: 40)
        : Image.asset('assets/icons/green_dome.png', width: 40, height: 40);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.surahListTitle)),
      body: FutureBuilder<List<Surah>>(
        future: _loadSurahs(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
                child: Text(AppLocalizations.of(context)!.surahLoadError));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
                child: Text(AppLocalizations.of(context)!.noSurahData));
          }
          final surahs = snapshot.data!;
          return ListView.separated(
            itemCount: surahs.length,
            separatorBuilder: (context, i) =>
                Divider(height: 1, color: Colors.grey[300]),
            itemBuilder: (context, i) {
              final surah = surahs[i];
              return InkWell(
                onTap: () => onSurahSelected(surah),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  child: Row(
                    children: [
                      // Icon
                      _buildTypeIcon(surah.type),
                      const SizedBox(width: 12),
                      // Ayah count
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.ayahCountLabel,
                            style: TextStyle(
                                fontSize: 13, color: Colors.grey[700]),
                          ),
                          Text(
                            '${surah.ayahs}',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(width: 18),
                      // Surah name (Arabic)
                      Expanded(
                        child: Text(
                          surah.name,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Amiri',
                          ),
                        ),
                      ),
                      // Surah number
                      Container(
                        width: 32,
                        alignment: Alignment.center,
                        child: Text(
                          '${surah.number}',
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
