import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:qcf_quran_lite/qcf_quran_lite.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
  );
  runApp(const MyApp());
}

// =============================================================================
// Global app settings (shared by every screen)
// =============================================================================

final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);
final ValueNotifier<MushafEdition> editionNotifier = ValueNotifier(currentMushafEdition);
final ValueNotifier<bool> twoPageNotifier = ValueNotifier(true);
final ValueNotifier<double> twoPageMinWidthNotifier = ValueNotifier(750);
final ValueNotifier<bool> customNumbersNotifier = ValueNotifier(false);
final ValueNotifier<PlaceholderAlignment> numberAlignmentNotifier = ValueNotifier(PlaceholderAlignment.middle);
final ValueNotifier<bool> customHeadersNotifier = ValueNotifier(false);
final ValueNotifier<bool> mushafTajweedNotifier = ValueNotifier(false);
final ValueNotifier<bool> verticalScrollNotifier = ValueNotifier(false);
final ValueNotifier<bool> pageSnappingNotifier = ValueNotifier(true);
final ValueNotifier<bool> bouncingPhysicsNotifier = ValueNotifier(true);
final ValueNotifier<bool> coloredBackgroundNotifier = ValueNotifier(false);
final ValueNotifier<bool> tajweedNotifier = ValueNotifier(true);
final ValueNotifier<double> listFontSizeNotifier = ValueNotifier(26);
final ValueNotifier<bool> wordRulesOnTapNotifier = ValueNotifier(true);
final ValueNotifier<bool> includeNaturalMaddNotifier = ValueNotifier(false);
final ValueNotifier<bool> includeTafkhimNotifier = ValueNotifier(true);
final ValueNotifier<List<Bookmark>> bookmarksNotifier = ValueNotifier([]);

/// الفاصل الزمني (بالثواني) بين ظهور كل كلمة في وضع الإخفاء (الحفظ).
final ValueNotifier<double> revealIntervalNotifier = ValueNotifier(1.0);

// -----------------------------------------------------------------------------
// Highlight style settings
// -----------------------------------------------------------------------------

enum AyahHighlightPreset { soft, outlined, sideBar, underline }

/// أضفنا ستايلات جديدة للكلمات هنا (bordered للحدود، shadow للظلال)
enum WordHighlightPreset { background, rounded, bordered, shadow, underline, wavy }

final ValueNotifier<AyahHighlightPreset> ayahPresetNotifier = ValueNotifier(AyahHighlightPreset.outlined);
final ValueNotifier<double> ayahOpacityNotifier = ValueNotifier(0.15);
final ValueNotifier<double> ayahRadiusNotifier = ValueNotifier(8);
final ValueNotifier<WordHighlightPreset> wordPresetNotifier = ValueNotifier(WordHighlightPreset.bordered);

AyahHighlightStyle buildAyahHighlightStyle() {
  final double opacity = ayahOpacityNotifier.value;
  final BorderRadius radius = BorderRadius.circular(ayahRadiusNotifier.value);
  const padding = EdgeInsets.symmetric(horizontal: 6, vertical: 2);

  switch (ayahPresetNotifier.value) {
    case AyahHighlightPreset.soft:
      return AyahHighlightStyle(opacity: opacity, borderRadius: radius, padding: padding);
    case AyahHighlightPreset.outlined:
      return AyahHighlightStyle(
        padding: padding,
        decorationBuilder: (c) => BoxDecoration(
          color: c.withValues(alpha: opacity),
          border: Border.all(color: c, width: 1.5),
          borderRadius: radius,
        ),
      );
    case AyahHighlightPreset.sideBar:
      return AyahHighlightStyle(
        wrapperBuilder: (context, child, c) => Container(
          padding: padding,
          decoration: BoxDecoration(
            color: c.withValues(alpha: opacity),
            border: BorderDirectional(start: BorderSide(color: c, width: 4)),
          ),
          child: child,
        ),
      );
    case AyahHighlightPreset.underline:
      return AyahHighlightStyle(
        padding: padding,
        decorationBuilder: (c) => BoxDecoration(
          border: Border(bottom: BorderSide(color: c, width: 2)),
        ),
      );
  }
}

/// Builds the [WordHighlightStyle] that matches the current settings.
WordHighlightStyle buildWordHighlightStyle() {
  switch (wordPresetNotifier.value) {
    case WordHighlightPreset.background:
      return const WordHighlightStyle();

    case WordHighlightPreset.rounded:
      return WordHighlightStyle(
        backgroundOpacity: 0.25,
        borderRadius: BorderRadius.circular(8),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      );

    case WordHighlightPreset.bordered: // <--- الميزة الجديدة (الإطار)
      return WordHighlightStyle(
        backgroundOpacity: 0.1, // نجعل الخلفية شفافة جداً
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        // نستخدم decorationBuilder حتى نجعل الإطار يأخذ نفس لون تظليل التجويد ديناميكياً
        decorationBuilder: (h, bg) {
          final activeColor = h.backgroundColor?.withValues(alpha: 1.0) ?? h.textColor ?? Colors.amber;
          return BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: activeColor, width: 1.5), // رسم الإطار
          );
        },
      );

    case WordHighlightPreset.shadow: // <--- الميزة الجديدة (ظل بارز ثلاثي الأبعاد)
      return WordHighlightStyle(
        backgroundOpacity: 1.0,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decorationBuilder: (h, bg) {
          final activeColor = bg ?? h.textColor ?? Colors.blueGrey;
          return BoxDecoration(
            color: activeColor,
            borderRadius: BorderRadius.circular(6),
            boxShadow: [
              BoxShadow(
                color: activeColor.withValues(alpha: 0.5),
                blurRadius: 4,
                offset: const Offset(0, 2),
              )
            ],
          );
        },
        styleBuilder: (h, base) => base.copyWith(
          color: Colors.white, // تغيير لون النص ليكون أبيض ليبرز على الظل
          fontWeight: FontWeight.bold,
        ),
      );

    case WordHighlightPreset.underline:
      return WordHighlightStyle(
        styleBuilder: (h, base) => base.copyWith(
          backgroundColor: Colors.transparent,
          decoration: TextDecoration.underline,
          decorationThickness: 2,
          decorationColor: h.backgroundColor?.withValues(alpha: 1) ?? h.textColor,
        ),
      );

    case WordHighlightPreset.wavy:
      return WordHighlightStyle(
        styleBuilder: (h, base) => base.copyWith(
          backgroundColor: Colors.transparent,
          decoration: TextDecoration.underline,
          decorationStyle: TextDecorationStyle.wavy,
          decorationThickness: 2,
          decorationColor: h.backgroundColor?.withValues(alpha: 1) ?? h.textColor,
        ),
      );
  }
}

// -----------------------------------------------------------------------------

class Bookmark {
  final int surah;
  final int verse;
  const Bookmark(this.surah, this.verse);

  @override
  bool operator ==(Object other) =>
      other is Bookmark && other.surah == surah && other.verse == verse;

  @override
  int get hashCode => Object.hash(surah, verse);
}

/// مرجع لكلمة محددة (سورة / آية / ترتيب الكلمة) - يستخدم في وضع الإخفاء.
class _WordRef {
  final int surah;
  final int verse;
  final int index;
  const _WordRef(this.surah, this.verse, this.index);

  @override
  bool operator ==(Object other) =>
      other is _WordRef &&
      other.surah == surah &&
      other.verse == verse &&
      other.index == index;

  @override
  int get hashCode => Object.hash(surah, verse, index);
}

bool toggleBookmark(int surah, int verse) {
  final list = List<Bookmark>.from(bookmarksNotifier.value);
  final bookmark = Bookmark(surah, verse);
  final removed = list.remove(bookmark);
  if (!removed) list.add(bookmark);
  bookmarksNotifier.value = list;
  return !removed;
}

bool isBookmarked(int surah, int verse) =>
    bookmarksNotifier.value.contains(Bookmark(surah, verse));

void changeEdition(MushafEdition edition) {
  if (currentMushafEdition == edition) return;
  setMushafEdition(edition);
  editionNotifier.value = edition;
}

String editionLabel(MushafEdition e) =>
    e == MushafEdition.edition1985 ? 'طبعة 1985' : 'طبعة 2003';

String placeArabic(int surah) =>
    getPlaceOfRevelation(surah) == 'Makkah' ? 'مكية' : 'مدنية';

String cleanVerseText(int surah, int verse) => getVerse(surah, verse)
    .replaceAll('\n', ' ')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

void showSnack(BuildContext context, String message) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(SnackBar(content: Text(message)));
}

void copyVerse(BuildContext context, int surah, int verse) {
  final text = '${cleanVerseText(surah, verse)}\n[${getSurahNameArabic(surah)} : $verse]';
  Clipboard.setData(ClipboardData(text: text));
  showSnack(context, 'تم نسخ الآية بنجاح');
}

// =============================================================================
// Tajweed rules API (word sheet and ayah sheet)
// =============================================================================

List<String> verseWords(int surah, int verse) => getVerse(surah, verse)
    .replaceAll('\n', ' ')
    .replaceAll('\u00a0', ' ')
    .trim()
    .split(RegExp(r'\s+'))
    .where((w) => w.isNotEmpty)
    .toList();

Color ruleColor(TajweedRule rule, bool isDark) =>
    isDark ? MushafColors.dark.tajweedColor(rule) : rule.color;

Widget coloredWord(
  String word,
  List<TajweedLetterRule> rules,
  bool isDark, {
  required Color baseColor,
  double fontSize = 28,
}) {
  final spans = <InlineSpan>[];
  var cursor = 0;
  for (final r in rules) {
    if (r.start < cursor || r.end > word.length) continue;
    if (r.start > cursor) {
      spans.add(TextSpan(text: word.substring(cursor, r.start)));
    }
    spans.add(TextSpan(
      text: word.substring(r.start, r.end),
      style: TextStyle(color: ruleColor(r.rule, isDark)),
    ));
    cursor = r.end;
  }
  if (cursor < word.length) spans.add(TextSpan(text: word.substring(cursor)));

  return Text.rich(
    TextSpan(
      style: QuranTextStyles.tajweedHafsStyle(
          color: baseColor, fontSize: fontSize),
      children: spans,
    ),
    textDirection: TextDirection.rtl,
  );
}

Widget ruleChip(TajweedRule rule, bool isDark, {int? count, String? letter}) {
  final color = ruleColor(rule, isDark);
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withValues(alpha: 0.7)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (letter != null)
          Text(
            letter,
            textDirection: TextDirection.rtl,
            style: QuranTextStyles.tajweedHafsStyle(color: color, fontSize: 20),
          )
        else
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
        const SizedBox(width: 6),
        Text(
          count == null ? rule.label : '${rule.label}  ×$count',
          style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    ),
  );
}

Widget _sheetShell(BuildContext ctx, List<Widget> children) {
  return Container(
    constraints:
        BoxConstraints(maxHeight: MediaQuery.sizeOf(ctx).height * 0.85),
    decoration: BoxDecoration(
      color: Theme.of(ctx).scaffoldBackgroundColor,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
    ),
    child: SafeArea(
      top: false,
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
        children: [
          Center(
            child: Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    ),
  );
}

Widget _ruleCard(
  BuildContext ctx,
  TajweedRule rule,
  bool isDark, {
  List<String> letters = const [],
  List<int> positions = const [],
  bool expanded = false,
}) {
  final theme = Theme.of(ctx);
  final color = ruleColor(rule, isDark);
  const grey = TextStyle(fontSize: 12, color: Colors.grey, height: 1.6);

  return Container(
    margin: const EdgeInsets.only(bottom: 10),
    decoration: BoxDecoration(
      color: theme.cardColor,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: color.withValues(alpha: 0.5)),
    ),
    child: Theme(
      data: theme.copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        initiallyExpanded: expanded,
        leading: CircleAvatar(radius: 8, backgroundColor: color),
        title: Row(
          children: [
            Expanded(
              child: Text(rule.label,
                  style: TextStyle(fontWeight: FontWeight.bold, color: color)),
            ),
            if (letters.isNotEmpty)
              Text(
                letters.join('   '),
                textDirection: TextDirection.rtl,
                style: QuranTextStyles.tajweedHafsStyle(
                    color: color, fontSize: 24),
              ),
          ],
        ),
        subtitle: Text('${rule.englishName} • ${rule.amount}',
            style: const TextStyle(fontSize: 12)),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(rule.definition, style: const TextStyle(height: 1.7)),
          const SizedBox(height: 8),
          if (positions.isNotEmpty)
            Text('ترتيب الحرف في الكلمة: ${positions.join('، ')}', style: grey),
          Text('الحروف: ${rule.letters}', style: grey),
          Text('المصدر: ${rule.source}', style: grey),
          const SizedBox(height: 6),
          Text(rule.evidence, style: grey),
        ],
      ),
    ),
  );
}

void showWordTajweedSheet(
  BuildContext context,
  int surah,
  int verse,
  int wordIndex, {
  String? fallbackWord,
}) {
  final bool isDark = Theme.of(context).brightness == Brightness.dark;
  final Color primary = Theme.of(context).colorScheme.primary;

  List<TajweedLetterRule> rules = const [];
  String? error;
  try {
    rules = getWordTajweedRules(
      surah,
      verse,
      wordIndex,
      includeNaturalMadd: includeNaturalMaddNotifier.value,
      includeTafkhim: includeTafkhimNotifier.value,
    );
  } catch (e) {
    error = e.toString();
  }

  final words = verseWords(surah, verse);
  final bool aligned = wordIndex >= 0 && wordIndex < words.length;
  final String wordText = aligned ? words[wordIndex] : (fallbackWord ?? '');

  final grouped = <TajweedRule, List<TajweedLetterRule>>{};
  for (final r in rules) {
    grouped.putIfAbsent(r.rule, () => []).add(r);
  }

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      final Color base =
          Theme.of(ctx).textTheme.bodyLarge?.color ?? Colors.black;
      return _sheetShell(ctx, [
        Center(
          child: (aligned && error == null)
              ? coloredWord(wordText, rules, isDark,
                  baseColor: base, fontSize: 34)
              : Text(
                  wordText,
                  textDirection: TextDirection.rtl,
                  style: QuranTextStyles.tajweedHafsStyle(
                      color: base, fontSize: 34),
                ),
        ),
        const SizedBox(height: 4),
        Center(
          child: Text(
            'الكلمة ${wordIndex + 1} • آية $verse • سورة ${getSurahNameArabic(surah)}',
            style: TextStyle(fontSize: 12, color: primary),
          ),
        ),
        const SizedBox(height: 16),
        if (error != null)
          Text(error!, style: const TextStyle(color: Colors.grey))
        else if (rules.isEmpty)
          const Text(
            'لا توجد أحكام تجويد في هذه الكلمة بالإعدادات الحالية.',
            style: TextStyle(color: Colors.grey),
          )
        else
          for (final e in grouped.entries)
            _ruleCard(
              ctx,
              e.key,
              isDark,
              letters: e.value.map((x) => x.letter).toList(),
              positions: e.value.map((x) => x.letterIndex + 1).toList(),
              expanded: grouped.length == 1,
            ),
      ]);
    },
  );
}

void showAyahTajweedSheet(BuildContext context, int surah, int verse) {
  final bool isDark = Theme.of(context).brightness == Brightness.dark;
  final Color primary = Theme.of(context).colorScheme.primary;

  final List<List<TajweedLetterRule>> rules = getAyahTajweedRules(
    surah,
    verse,
    includeNaturalMadd: includeNaturalMaddNotifier.value,
    includeTafkhim: includeTafkhimNotifier.value,
  );
  final words = verseWords(surah, verse).take(rules.length).toList();

  final counts = <TajweedRule, int>{};
  for (final r in rules.expand((e) => e)) {
    counts[r.rule] = (counts[r.rule] ?? 0) + 1;
  }

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      final Color base =
          Theme.of(ctx).textTheme.bodyLarge?.color ?? Colors.black;
      return _sheetShell(ctx, [
        Center(
          child: Text('أحكام التجويد',
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold, color: primary)),
        ),
        const SizedBox(height: 4),
        Center(
          child: Text('سورة ${getSurahNameArabic(surah)} • آية $verse',
              style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ),
        const SizedBox(height: 14),
        if (counts.isEmpty)
          const Text('لا توجد أحكام بالإعدادات الحالية.',
              style: TextStyle(color: Colors.grey))
        else
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final e in counts.entries)
                ruleChip(e.key, isDark, count: e.value),
            ],
          ),
        const Divider(height: 28),
        for (var i = 0; i < words.length; i++)
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () {
              Navigator.pop(ctx);
              showWordTajweedSheet(context, surah, verse, i);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  coloredWord(words[i], rules[i], isDark,
                      baseColor: base, fontSize: 24),
                  const SizedBox(height: 6),
                  if (rules[i].isEmpty)
                    const Text('—', style: TextStyle(color: Colors.grey))
                  else
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final r in rules[i])
                          ruleChip(r.rule, isDark, letter: r.letter),
                      ],
                    ),
                ],
              ),
            ),
          ),
      ]);
    },
  );
}

// =============================================================================
// Shared builders (ayah number, Surah header, Basmallah)
// =============================================================================

Widget buildCustomAyahNumber(
  BuildContext context,
  int surahNumber,
  int verseNumber,
  String glyph,
  bool isDark,
) {
  final color =
      isDark ? const Color(0xFFD4AF37) : Theme.of(context).colorScheme.primary;
  return Container(
    width: 30,
    height: 30,
    margin: const EdgeInsets.symmetric(horizontal: 2),
    alignment: Alignment.center,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(color: color, width: 1.2),
    ),
    child: Text(
      getVerseEndSymbol(verseNumber),
      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
    ),
  );
}

Widget buildCustomSurahHeader(BuildContext context, int surahNumber) {
  final color = Theme.of(context).colorScheme.primary;
  return SizedBox(
    height: 56,
    child: Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${placeArabic(surahNumber)} • ${getVerseCount(surahNumber)} آية',
            style: TextStyle(fontSize: 12, color: color),
          ),
          Text(
            'سورة ${getSurahNameArabic(surahNumber)}',
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: color),
          ),
          Text(
            getSurahNameEnglish(surahNumber),
            style: TextStyle(fontSize: 12, color: color),
          ),
        ],
      ),
    ),
  );
}

Widget buildCustomBasmallah(BuildContext context, int surahNumber) {
  return SizedBox(
    height: 44,
    child: Center(
      child: Text(
        'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ',
        style: QuranTextStyles.hafsStyle(
          fontSize: 22,
          color: Theme.of(context).textTheme.bodyLarge!.color,
        ),
      ),
    ),
  );
}

void showAyahDetailsSheet(BuildContext context, int surah, int verse) {
  final int page = getPageNumber(surah, verse);
  final String surahAr = getSurahNameArabic(surah);
  final int juz = getJuzNumber(surah, verse);
  final int quarter = getQuarterNumber(surah, verse);
  final primary = Theme.of(context).colorScheme.primary;

  Widget card(String title, String value, IconData icon) {
    return Container(
      width: 70,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFFD4AF37), size: 20),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          Text(value,
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.bold, color: primary)),
        ],
      ),
    );
  }

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return Container(
        decoration: BoxDecoration(
          color: Theme.of(ctx).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 16),
              Text('سورة $surahAr',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: primary)),
              const SizedBox(height: 12),
              Text(
                cleanVerseText(surah, verse),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: QuranTextStyles.hafsStyle(
                  fontSize: 20,
                  color: Theme.of(ctx).textTheme.bodyLarge!.color,
                  height: 1.8,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  card('الآية', '$verse', Icons.menu_book),
                  card('الصفحة', '$page', Icons.auto_stories),
                  card('الجزء', '$juz', Icons.pie_chart),
                  card('الربع', '$quarter', Icons.data_usage),
                  card('النزول', placeArabic(surah), Icons.location_on),
                  card('آيات السورة', '${getVerseCount(surah)}',
                      Icons.format_list_numbered_rtl),
                ],
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                icon: const Icon(Icons.palette_outlined),
                label: const Text('أحكام التجويد في الآية'),
                onPressed: () {
                  Navigator.pop(ctx);
                  showAyahTajweedSheet(context, surah, verse);
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}

// =============================================================================
// Settings bottom sheet
// =============================================================================

void showSettingsSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const SettingsSheet(),
  );
}

class SettingsSheet extends StatelessWidget {
  const SettingsSheet({super.key});

  Widget _switch(String title, String subtitle, ValueNotifier<bool> notifier) {
    return ValueListenableBuilder<bool>(
      valueListenable: notifier,
      builder: (_, value, __) => SwitchListTile(
        title: Text(title),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        value: value,
        onChanged: (v) => notifier.value = v,
      ),
    );
  }

  Widget _section(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 20, 4, 4),
      child: Row(
        children: [
          Icon(Icons.brightness_1, size: 10, color: color),
          const SizedBox(width: 8),
          Text(title,
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _choice<T>(ValueNotifier<T> notifier, Map<T, String> options) {
    return ValueListenableBuilder<T>(
      valueListenable: notifier,
      builder: (_, selected, __) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final e in options.entries)
              ChoiceChip(
                label: Text(e.value),
                selected: selected == e.key,
                onSelected: (_) => notifier.value = e.key,
              ),
          ],
        ),
      ),
    );
  }

  Widget _slider(
    String title,
    ValueNotifier<double> notifier,
    double min,
    double max,
    int divisions, {
    int decimals = 2,
  }) {
    return ValueListenableBuilder<double>(
      valueListenable: notifier,
      builder: (_, value, __) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text('$title: ${value.toStringAsFixed(decimals)}'),
          ),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: (v) => notifier.value = v,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Text('الإعدادات',
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold, color: primary)),

          _section('عام', primary),
          const Text('طبعة المصحف'),
          const SizedBox(height: 8),
          ValueListenableBuilder<MushafEdition>(
            valueListenable: editionNotifier,
            builder: (_, edition, __) => SegmentedButton<MushafEdition>(
              segments: const [
                ButtonSegment(
                    value: MushafEdition.edition2003, label: Text('طبعة 2003')),
                ButtonSegment(
                    value: MushafEdition.edition1985, label: Text('طبعة 1985')),
              ],
              selected: {edition},
              onSelectionChanged: (s) => changeEdition(s.first),
            ),
          ),
          const SizedBox(height: 8),
          ValueListenableBuilder<ThemeMode>(
            valueListenable: themeNotifier,
            builder: (_, mode, __) => SwitchListTile(
              title: const Text('الوضع الداكن'),
              value: mode == ThemeMode.dark,
              onChanged: (v) =>
                  themeNotifier.value = v ? ThemeMode.dark : ThemeMode.light,
            ),
          ),
          _switch('أرقام آيات مخصصة', 'بدل رمز الخط الافتراضي (المصحف والقائمة)',
              customNumbersNotifier),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Text('محاذاة رقم الآية المخصص'),
          ),
          ValueListenableBuilder<PlaceholderAlignment>(
            valueListenable: numberAlignmentNotifier,
            builder: (_, alignment, __) => SegmentedButton<PlaceholderAlignment>(
              segments: const [
                ButtonSegment(
                    value: PlaceholderAlignment.middle, label: Text('وسط')),
                ButtonSegment(
                    value: PlaceholderAlignment.baseline,
                    label: Text('خط الأساس')),
                ButtonSegment(
                    value: PlaceholderAlignment.bottom, label: Text('أسفل')),
              ],
              selected: {alignment},
              onSelectionChanged: (s) => numberAlignmentNotifier.value = s.first,
            ),
          ),
          _switch('ترويسة وبسملة مخصصتان',
              'استخدام surahHeaderBuilder و basmallahBuilder', customHeadersNotifier),

          _section('المصحف (صفحات)', primary),
          _switch('ألوان التجويد', 'خط uthmanic_hafs مع تلوين أحكام التجويد',
              mushafTajweedNotifier),
          _switch('عرض صفحتين', 'على الشاشات الأعرض من الحد الأدنى أدناه',
              twoPageNotifier),
          ValueListenableBuilder<double>(
            valueListenable: twoPageMinWidthNotifier,
            builder: (_, width, __) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text('الحد الأدنى لعرض صفحتين: ${width.round()} بكسل'),
                ),
                Slider(
                  value: width,
                  min: 500,
                  max: 1400,
                  divisions: 18,
                  onChanged: (v) => twoPageMinWidthNotifier.value = v,
                ),
              ],
            ),
          ),
          _switch('تمرير عمودي', 'يعطّل عرض الصفحتين', verticalScrollNotifier),
          _switch('تثبيت الصفحة أثناء التمرير', 'pageSnapping', pageSnappingNotifier),
          _switch('تمرير مرتد (Bouncing)', 'وإلا يُستخدم تمرير متوقف عند الحافة',
              bouncingPhysicsNotifier),
          _switch('خلفية ملوّنة', 'pageBackgroundColor', coloredBackgroundNotifier),

          _section('شكل التظليل', primary),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Text('تظليل الآية'),
          ),
          _choice<AyahHighlightPreset>(ayahPresetNotifier, const {
            AyahHighlightPreset.soft: 'ناعم',
            AyahHighlightPreset.outlined: 'بإطار',
            AyahHighlightPreset.sideBar: 'شريط جانبي',
            AyahHighlightPreset.underline: 'خط سفلي',
          }),
          _slider('الشفافية', ayahOpacityNotifier, 0.05, 0.6, 11),
          _slider('استدارة الزوايا', ayahRadiusNotifier, 0, 24, 12,
              decimals: 0),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text('تظليل الكلمة (اضغط على كلمة لتجربته)'),
          ),
          _choice<WordHighlightPreset>(wordPresetNotifier, const {
            WordHighlightPreset.background: 'خلفية',
            WordHighlightPreset.rounded: 'مدوّر',
            WordHighlightPreset.bordered: 'بإطار', // <--- الخيار الجديد
            WordHighlightPreset.shadow: 'ظل بارز', // <--- الخيار الجديد
            WordHighlightPreset.underline: 'خط سفلي',
            WordHighlightPreset.wavy: 'خط متموج',
          }),

          _section('أحكام التجويد (واجهة البرمجة)', primary),
          _switch('أحكام الكلمة عند الضغط', 'يفتح getWordTajweedRules عند الضغط على كلمة',
              wordRulesOnTapNotifier),
          _switch('تضمين المدّ الطبيعي', 'includeNaturalMadd',
              includeNaturalMaddNotifier),
          _switch('تضمين التفخيم والترقيق', 'includeTafkhim',
              includeTafkhimNotifier),

          _section('وضع الإخفاء (الحفظ)', primary),
          _slider('الفاصل بين ظهور الكلمات (ثانية)', revealIntervalNotifier,
              0.5, 5, 9,
              decimals: 1),

          _section('القراءة كقائمة', primary),
          _switch('ألوان التجويد', 'في شاشة القراءة كقائمة', tajweedNotifier),
          ValueListenableBuilder<double>(
            valueListenable: listFontSizeNotifier,
            builder: (_, size, __) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text('حجم الخط في القائمة: ${size.round()}'),
                ),
                Slider(
                  value: size,
                  min: 18,
                  max: 40,
                  divisions: 22,
                  onChanged: (v) => listFontSizeNotifier.value = v,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// App
// =============================================================================

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, ThemeMode currentMode, __) {
        return MaterialApp(
          title: 'QCF Quran Lite Demo',
          debugShowCheckedModeBanner: false,
          builder: (context, child) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: child!,
            );
          },
          themeMode: currentMode,
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
            scaffoldBackgroundColor: const Color(0xFFFBF6EE),
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF3E2723),
              secondary: Color(0xFF8D6E63),
              surface: Color(0xFFF9F1E3),
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFFFBF6EE),
              foregroundColor: Color(0xFF3E2723),
              elevation: 0,
            ),
            cardColor: const Color(0xFFF9F1E3),
            textTheme: const TextTheme(
              bodyLarge: TextStyle(color: Color(0xFF212121)),
              bodyMedium: TextStyle(color: Color(0xFF5D4037)),
            ),
            fontFamily: 'Cairo',
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF121212),
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFD4AF37),
              secondary: Color(0xFFA1887F),
              surface: Color(0xFF1E1E1E),
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF121212),
              foregroundColor: Color(0xFFD4AF37),
              elevation: 0,
            ),
            cardColor: const Color(0xFF1E1E1E),
            textTheme: const TextTheme(
              bodyLarge: TextStyle(color: Color(0xFFE0E0E0)),
              bodyMedium: TextStyle(color: Color(0xFFAAAAAA)),
            ),
            fontFamily: 'Cairo',
          ),
          home: const DashboardScreen(),
        );
      },
    );
  }
}

// =============================================================================
// Dashboard (navigation, statistics, page jump, search)
// =============================================================================

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _pageController = TextEditingController();

  List<Map> _searchResults = [];
  int _searchOccurrences = 0;
  bool _exactMatch = false;
  int? _infoPage;

  @override
  void dispose() {
    _searchController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _searchOccurrences = 0;
      });
      return;
    }
    final Map results = searchWords(query, limit: 50, exactMatch: _exactMatch);
    setState(() {
      _searchOccurrences = results['occurences'] as int;
      _searchResults = List<Map>.from(results['result'] as List);
    });
  }

  void _showPageInfo() {
    final int? page = int.tryParse(_pageController.text.trim());
    if (page == null || page < 1 || page > totalPagesCount) {
      showSnack(context, 'أدخل رقم صفحة بين 1 و $totalPagesCount');
      setState(() => _infoPage = null);
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _infoPage = page);
  }

  void _openMushaf({int page = 1, int? surah, int? ayah}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MushafScreen(
          initialPage: page,
          highlightSurah: surah,
          highlightAyah: ayah,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final secondaryColor = Theme.of(context).colorScheme.secondary;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'مكتبة المصحف الذكية',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'الإعدادات',
            icon: const Icon(Icons.tune),
            onPressed: () => showSettingsSheet(context),
          ),
          IconButton(
            tooltip: 'الوضع الداكن',
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: () {
              themeNotifier.value = isDark ? ThemeMode.light : ThemeMode.dark;
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ValueListenableBuilder<MushafEdition>(
              valueListenable: editionNotifier,
              builder: (_, edition, __) => Align(
                alignment: AlignmentDirectional.centerStart,
                child: ActionChip(
                  avatar: Icon(Icons.menu_book, size: 18, color: primaryColor),
                  label: Text(editionLabel(edition)),
                  onPressed: () => showSettingsSheet(context),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildNavButton(
                    title: 'المصحف الكامل',
                    icon: Icons.menu_book,
                    color: primaryColor,
                    onTap: () => _openMushaf(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildNavButton(
                    title: 'قراءة كقائمة',
                    icon: Icons.format_list_numbered_rtl,
                    color: secondaryColor,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SurahListReaderScreen(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildNavButton(
                    title: 'الفهرس',
                    icon: Icons.list_alt,
                    color: secondaryColor,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const IndexScreen()),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildNavButton(
                    title: 'العلامات المرجعية',
                    icon: Icons.bookmarks_outlined,
                    color: primaryColor,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const BookmarksScreen()),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 25),
            _buildSectionTitle('إحصائيات القرآن', primaryColor),
            const SizedBox(height: 10),
            Row(
              children: [
                _buildStatCard('سور القرآن', '$totalSurahCount', Icons.library_books),
                const SizedBox(width: 10),
                _buildStatCard('عدد الآيات', '$totalVerseCount', Icons.format_list_numbered_rtl),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _buildStatCard('الصفحات', '$totalPagesCount', Icons.auto_stories),
                const SizedBox(width: 10),
                _buildStatCard('الأجزاء', '$totalJuzCount', Icons.pie_chart),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _buildStatCard('مكية', '$totalMakkiSurahs', Icons.location_on),
                const SizedBox(width: 10),
                _buildStatCard('مدنية', '$totalMadaniSurahs', Icons.location_city),
              ],
            ),
            const SizedBox(height: 30),
            _buildSectionTitle('الانتقال إلى صفحة', primaryColor),
            const SizedBox(height: 10),
            TextField(
              controller: _pageController,
              keyboardType: TextInputType.number,
              onSubmitted: (_) => _showPageInfo(),
              decoration: InputDecoration(
                hintText: 'رقم الصفحة (1 - $totalPagesCount)',
                prefixIcon: Icon(Icons.numbers, color: primaryColor),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.info_outline),
                  onPressed: _showPageInfo,
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                filled: true,
                fillColor: Theme.of(context).cardColor,
              ),
            ),
            if (_infoPage != null) ...[
              const SizedBox(height: 10),
              _buildPageInfoCard(_infoPage!, primaryColor),
            ],
            const SizedBox(height: 30),
            _buildSectionTitle('محرك البحث المدمج', primaryColor),
            const SizedBox(height: 10),
            TextField(
              controller: _searchController,
              onSubmitted: _performSearch,
              onChanged: (_) => setState(() {}),
              style: TextStyle(color: Theme.of(context).textTheme.bodyLarge!.color),
              decoration: InputDecoration(
                hintText: 'ابحث (مثال: الله، الرحمن)...',
                prefixIcon: Icon(Icons.search, color: primaryColor),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _performSearch('');
                  },
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                filled: true,
                fillColor: Theme.of(context).cardColor,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                FilterChip(
                  label: const Text('مطابقة تامة للكلمة'),
                  selected: _exactMatch,
                  onSelected: (v) {
                    setState(() => _exactMatch = v);
                    _performSearch(_searchController.text);
                  },
                ),
                const SizedBox(width: 10),
                if (_searchController.text.trim().isNotEmpty)
                  Expanded(
                    child: Text(
                      'بعد التطبيع: ${normalizeArabicSearchText(_searchController.text.trim())}',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 15),
            if (_searchOccurrences > 0) ...[
              Text(
                'تم العثور على $_searchOccurrences نتيجة (الحد الأقصى 50):',
                style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor),
              ),
              const SizedBox(height: 10),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final result = _searchResults[index];
                  final int sNum = result['sora'] as int;
                  final int vNum = result['aya_no'] as int;
                  final String sName = getSurahNameArabic(sNum);
                  final int pNum = getPageNumber(sNum, vNum);
                  final String verseText = (result['text_othmanic'] ?? '').toString();

                  return Card(
                    elevation: 1,
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            verseText,
                            style: QuranTextStyles.hafsStyle(
                              fontSize: 23.55,
                              color: Theme.of(context).textTheme.bodyLarge!.color,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  'سورة $sName - آية $vNum (صفحة $pNum)',
                                  style: TextStyle(color: primaryColor, fontSize: 12),
                                ),
                              ),
                              IconButton(
                                tooltip: 'نسخ',
                                icon: Icon(Icons.copy, color: primaryColor, size: 20),
                                onPressed: () => copyVerse(context, sNum, vNum),
                              ),
                              IconButton(
                                tooltip: 'فتح في المصحف',
                                icon: Icon(Icons.menu_book, color: primaryColor, size: 20),
                                onPressed: () =>
                                    _openMushaf(page: pNum, surah: sNum, ayah: vNum),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
            ] else if (_searchController.text.trim().isNotEmpty &&
                _searchResults.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text('اضغط Enter للبحث، أو لا توجد نتائج بعد.',
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageInfoCard(int page, Color color) {
    final pageData = getPageData(page);
    final hizbText = getHizbTextByPage(page);
    final lines = <String>[
      'عدد السور في الصفحة: ${getSurahCountByPage(page)}',
      'عدد الآيات في الصفحة: ${getVerseCountByPage(page)}',
      'الجزء: ${getCurrentJuzNumberForPage(page)}',
      if (hizbText.isNotEmpty) 'يبدأ في هذه الصفحة: $hizbText',
      'تبدأ بسورة ${getSurahNameArabic(pageData.first['surah'] as int)} '
          'آية ${pageData.first['start']}',
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('الصفحة $page',
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16, color: color)),
            const SizedBox(height: 6),
            for (final l in lines) Text(l),
            const SizedBox(height: 8),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: FilledButton.icon(
                onPressed: () => _openMushaf(page: page),
                icon: const Icon(Icons.menu_book),
                label: const Text('انتقال'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color color) {
    return Row(
      children: [
        Icon(Icons.brightness_1, size: 12, color: color),
        const SizedBox(width: 8),
        Text(title,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _buildNavButton({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color.withValues(alpha: 0.5)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(title,
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Expanded(
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Icon(icon, color: const Color(0xFFD4AF37), size: 30),
              const SizedBox(height: 8),
              Text(title, style: const TextStyle(fontSize: 14)),
              Text(value,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Index screen (Surahs, Juz, Hizb quarters)
// =============================================================================

class IndexScreen extends StatelessWidget {
  final bool pickMode;

  const IndexScreen({super.key, this.pickMode = false});

  void _open(BuildContext context, int page) {
    if (pickMode) {
      Navigator.pop(context, page);
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => MushafScreen(initialPage: page)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('الفهرس'),
          centerTitle: true,
          bottom: const TabBar(
            tabs: [Tab(text: 'السور'), Tab(text: 'الأجزاء'), Tab(text: 'الأحزاب')],
          ),
        ),
        body: TabBarView(
          children: [
            _buildSurahs(context),
            _buildJuz(context),
            _buildQuarters(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSurahs(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return ListView.builder(
      itemCount: totalSurahCount,
      itemBuilder: (context, index) {
        final int s = index + 1;
        final int page = getPageNumber(s, 1);
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: primary.withValues(alpha: 0.1),
            child: Text('$s', style: TextStyle(color: primary, fontSize: 12)),
          ),
          title: Text('سورة ${getSurahNameArabic(s)}',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(
              '${getSurahNameEnglish(s)} • ${placeArabic(s)} • ${getVerseCount(s)} آية'),
          trailing: Text('ص $page', style: TextStyle(color: primary)),
          onTap: () => _open(context, page),
        );
      },
    );
  }

  Widget _buildJuz(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return ListView.builder(
      itemCount: totalJuzCount,
      itemBuilder: (context, index) {
        final q = quarters[index * 8];
        final int s = q['surah']!;
        final int a = q['ayah']!;
        final int page = getPageNumber(s, a);
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: primary.withValues(alpha: 0.1),
            child: Text('${index + 1}', style: TextStyle(color: primary, fontSize: 12)),
          ),
          title: Text('الجزء ${index + 1}',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('يبدأ من سورة ${getSurahNameArabic(s)} - آية $a'),
          trailing: Text('ص $page', style: TextStyle(color: primary)),
          onTap: () => _open(context, page),
        );
      },
    );
  }

  Widget _buildQuarters(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    const labels = ['الحزب', 'ربع الحزب', 'نصف الحزب', 'ثلاثة أرباع الحزب'];
    return ListView.builder(
      itemCount: quarters.length,
      itemBuilder: (context, index) {
        final q = quarters[index];
        final int s = q['surah']!;
        final int a = q['ayah']!;
        final int page = getPageNumber(s, a);
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: primary.withValues(alpha: 0.1),
            child: Text('${index + 1}', style: TextStyle(color: primary, fontSize: 12)),
          ),
          title: Text('${labels[index % 4]} ${index ~/ 4 + 1}'),
          subtitle: Text('سورة ${getSurahNameArabic(s)} - آية $a'),
          trailing: Text('ص $page', style: TextStyle(color: primary)),
          onTap: () => _open(context, page),
        );
      },
    );
  }
}

// =============================================================================
// Bookmarks screen
// =============================================================================

class BookmarksScreen extends StatelessWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Scaffold(
      appBar: AppBar(title: const Text('العلامات المرجعية'), centerTitle: true),
      body: ValueListenableBuilder<List<Bookmark>>(
        valueListenable: bookmarksNotifier,
        builder: (context, bookmarks, _) {
          if (bookmarks.isEmpty) {
            return const Center(
              child: Text('لا توجد علامات بعد.\nاضغط مطولاً على آية في المصحف ثم اختر «حفظ كعلامة».',
                  textAlign: TextAlign.center),
            );
          }
          return ListView.builder(
            itemCount: bookmarks.length,
            itemBuilder: (context, index) {
              final b = bookmarks[index];
              final int page = getPageNumber(b.surah, b.verse);
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  title: Text(
                    cleanVerseText(b.surah, b.verse),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: QuranTextStyles.hafsStyle(
                      fontSize: 20,
                      color: Theme.of(context).textTheme.bodyLarge!.color,
                    ),
                  ),
                  subtitle: Text(
                    'سورة ${getSurahNameArabic(b.surah)} - آية ${b.verse} (صفحة $page)',
                    style: TextStyle(color: primary, fontSize: 12),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => toggleBookmark(b.surah, b.verse),
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MushafScreen(
                        initialPage: page,
                        highlightSurah: b.surah,
                        highlightAyah: b.verse,
                      ),
                    ),
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

// =============================================================================
// Mushaf screen (single / two-page layout, highlights, menu, playback,
// hide mode for memorization)
// =============================================================================

class MushafScreen extends StatefulWidget {
  final int initialPage;
  final int? highlightSurah;
  final int? highlightAyah;

  const MushafScreen({
    super.key,
    this.initialPage = 1,
    this.highlightSurah,
    this.highlightAyah,
  });

  @override
  State<MushafScreen> createState() => _MushafScreenState();
}

class _MushafScreenState extends State<MushafScreen> {
  late PageController _pageController;
  late int _anchorSurah;
  late int _anchorAyah;
  late int _currentPage;

  HighlightVerse? _flashHighlight;
  HighlightVerse? _menuHighlight;
  HighlightVerse? _playbackHighlight;

  List<WordHighlight> _wordHighlights = [];

  Timer? _flashTimer;
  Timer? _playbackTimer;
  int _playSurah = 1;
  int _playAyah = 1;

  // ---- وضع الإخفاء (الحفظ) ----
  bool _hideMode = false;
  Timer? _hideTimer;
  List<_WordRef> _hiddenWords = [];
  _WordRef? _lastRevealed;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage;
    _pageController = PageController(initialPage: widget.initialPage - 1);
    _updateAnchor(widget.initialPage);
    editionNotifier.addListener(_onEditionChanged);

    if (widget.highlightSurah != null && widget.highlightAyah != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _flashVerse(widget.highlightSurah!, widget.highlightAyah!);
      });
    }
  }

  @override
  void dispose() {
    editionNotifier.removeListener(_onEditionChanged);
    _flashTimer?.cancel();
    _playbackTimer?.cancel();
    _hideTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _updateAnchor(int page) {
    final first = getPageData(page).first;
    _anchorSurah = first['surah'] as int;
    _anchorAyah = first['start'] as int;
  }

  void _onEditionChanged() {
    if (!mounted) return;
    _stopPlayback();
    _stopHideMode();
    final int newPage = getPageNumber(_anchorSurah, _anchorAyah);
    final PageController old = _pageController;

    setState(() {
      _pageController = PageController(initialPage: newPage - 1);
      _currentPage = newPage;
      _flashHighlight = null;
      _menuHighlight = null;
      _wordHighlights = [];
    });
    _updateAnchor(newPage);

    WidgetsBinding.instance.addPostFrameCallback((_) => old.dispose());
  }

  void _goToPage(int page, {bool animate = false}) {
    if (!_pageController.hasClients) return;
    if (animate) {
      _pageController.animateToPage(
        page - 1,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _pageController.jumpToPage(page - 1);
    }
  }

  HighlightVerse _makeHighlight(int surah, int verse, Color color) {
    return HighlightVerse(
      surah: surah,
      verseNumber: verse,
      page: getPageNumber(surah, verse),
      color: color,
    );
  }

  List<HighlightVerse> get _highlights {
    final marks = bookmarksNotifier.value
        .map((b) => _makeHighlight(b.surah, b.verse, const Color(0xFFD4AF37)))
        .toList();
    return [
      ...marks,
      if (_flashHighlight != null) _flashHighlight!,
      if (_menuHighlight != null) _menuHighlight!,
      if (_playbackHighlight != null) _playbackHighlight!,
    ];
  }

  void _flashVerse(int surah, int ayah) {
    final color = Theme.of(context).colorScheme.primary;
    _flashTimer?.cancel();
    setState(() => _flashHighlight = _makeHighlight(surah, ayah, color));
    _flashTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _flashHighlight = null);
    });
  }

  void _startPlayback(int surah, int ayah) {
    _playbackTimer?.cancel();
    _playSurah = surah;
    _playAyah = ayah;
    _showPlaybackVerse();
    _playbackTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (_playAyah < getVerseCount(_playSurah)) {
        _playAyah++;
      } else if (_playSurah < totalSurahCount) {
        _playSurah++;
        _playAyah = 1;
      } else {
        _stopPlayback();
        return;
      }
      _showPlaybackVerse();
    });
  }

  void _showPlaybackVerse() {
    final int page = getPageNumber(_playSurah, _playAyah);
    final color = Theme.of(context).colorScheme.secondary;
    setState(() => _playbackHighlight = _makeHighlight(_playSurah, _playAyah, color));

    final bool twoPage = twoPageNotifier.value &&
        !verticalScrollNotifier.value &&
        MediaQuery.sizeOf(context).width >= twoPageMinWidthNotifier.value;
    _goToPage(page, animate: !twoPage);
  }

  void _stopPlayback() {
    final bool wasPlaying = _playbackTimer != null;
    _playbackTimer?.cancel();
    _playbackTimer = null;
    if (wasPlaying && mounted) setState(() => _playbackHighlight = null);
  }

  // ---------------------------------------------------------------------------
  // وضع الإخفاء (الحفظ): تُخفى كلمات الصفحة ثم تظهر كلمة كل فترة زمنية
  // ---------------------------------------------------------------------------

  List<_WordRef> _wordsOfPage(int page) {
    final out = <_WordRef>[];
    for (final seg in getPageData(page)) {
      final int s = seg['surah'] as int;
      final int start = seg['start'] as int;
      final int end = seg['end'] as int;
      for (var v = start; v <= end; v++) {
        final int n = verseWords(s, v).length;
        for (var i = 0; i < n; i++) {
          out.add(_WordRef(s, v, i));
        }
      }
    }
    return out;
  }

  void _startHideMode(int page) {
    _hideTimer?.cancel();
    setState(() {
      _hideMode = true;
      _lastRevealed = null;
      _wordHighlights = [];
      _hiddenWords = _wordsOfPage(page);
    });
    final ms = (revealIntervalNotifier.value * 1000).round();
    _hideTimer = Timer.periodic(Duration(milliseconds: ms), (_) {
      if (!mounted) return;
      _revealNext();
    });
  }

  void _revealNext() {
    if (_hiddenWords.isEmpty) {
      _stopHideMode();
      return;
    }
    setState(() => _lastRevealed = _hiddenWords.removeAt(0));
    if (_hiddenWords.isEmpty) {
      // آخر كلمة ظهرت: ننهي الوضع بعد لحظة
      _hideTimer?.cancel();
      _hideTimer = null;
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) _stopHideMode();
      });
    }
  }

  void _stopHideMode() {
    _hideTimer?.cancel();
    _hideTimer = null;
    if (!_hideMode) return;
    if (mounted) {
      setState(() {
        _hideMode = false;
        _hiddenWords = [];
        _lastRevealed = null;
      });
    }
  }

  List<WordHighlight> get _effectiveWordHighlights {
    if (!_hideMode) return _wordHighlights;
    const hiddenColor = Colors.transparent;
    return [
      for (final w in _hiddenWords)
        WordHighlight(
          surah: w.surah,
          verseNumber: w.verse,
          wordIndex: w.index,
          backgroundColor: hiddenColor,
          textColor: hiddenColor, // العلامة اللي بنعرف بيها إن الكلمة مخفية
        ),
      if (_lastRevealed != null)
        WordHighlight(
          surah: _lastRevealed!.surah,
          verseNumber: _lastRevealed!.verse,
          wordIndex: _lastRevealed!.index,
          backgroundColor:
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.25),
        ),
    ];
  }

  WordHighlightStyle _buildHideStyle() {
    return WordHighlightStyle(
      backgroundOpacity: 1.0,
      styleBuilder: (h, base) => h.textColor == Colors.transparent
          ? base.copyWith(
              color: Colors.transparent,
              backgroundColor: Colors.transparent,
            )
          : base,
    );
  }

  // ---------------------------------------------------------------------------

  void _onWordTap(int surah, int verse, int wordIndex, String word) {
    // في وضع الإخفاء: الضغط على كلمة مخفية يُظهرها فوراً.
    if (_hideMode) {
      final i = _hiddenWords.indexOf(_WordRef(surah, verse, wordIndex));
      if (i != -1) {
        setState(() => _lastRevealed = _hiddenWords.removeAt(i));
      }
      return;
    }

    // استخدم لون متوافق مع جميع الثيمات.
    final color = Theme.of(context).colorScheme.primary.withValues(alpha: 0.25);
    setState(() {
      _wordHighlights = [
        WordHighlight(
          surah: surah,
          verseNumber: verse,
          wordIndex: wordIndex,
          backgroundColor: color,
        ),
      ];
    });
    if (wordRulesOnTapNotifier.value) {
      showWordTajweedSheet(context, surah, verse, wordIndex, fallbackWord: word);
    } else {
      showSnack(context,
          'الكلمة ${wordIndex + 1} - آية $verse - سورة ${getSurahNameArabic(surah)}');
    }
  }

  Future<void> _showContextMenu(int surah, int verse, Offset globalPosition) async {
    setState(() {
      _menuHighlight =
          _makeHighlight(surah, verse, Theme.of(context).colorScheme.primary);
    });

    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final bool marked = isBookmarked(surah, verse);

    final String? result = await showMenu<String>(
      context: context,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      color: Theme.of(context).cardColor,
      position: RelativeRect.fromRect(
        globalPosition & const Size(40, 40),
        Offset.zero & overlay.size,
      ),
      items: [
        const PopupMenuItem(
          value: 'play',
          child: Row(children: [
            Icon(Icons.play_circle_outline),
            SizedBox(width: 10),
            Text('تتبع من هذه الآية'),
          ]),
        ),
        const PopupMenuItem(
          value: 'copy',
          child: Row(children: [
            Icon(Icons.copy),
            SizedBox(width: 10),
            Text('نسخ الآية'),
          ]),
        ),
        PopupMenuItem(
          value: 'bookmark',
          child: Row(children: [
            Icon(marked ? Icons.bookmark_remove_outlined : Icons.bookmark_border),
            const SizedBox(width: 10),
            Text(marked ? 'إزالة العلامة' : 'حفظ كعلامة'),
          ]),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'details',
          child: Row(children: [
            Icon(Icons.info_outline),
            SizedBox(width: 10),
            Text('تفاصيل الآية'),
          ]),
        ),
      ],
    );

    if (!mounted) return;
    setState(() => _menuHighlight = null);

    switch (result) {
      case 'play':
        _startPlayback(surah, verse);
        break;
      case 'copy':
        copyVerse(context, surah, verse);
        break;
      case 'bookmark':
        final added = toggleBookmark(surah, verse);
        showSnack(context, added ? 'تم حفظ الآية في العلامات المرجعية' : 'تمت إزالة العلامة');
        break;
      case 'details':
        showAyahDetailsSheet(context, surah, verse);
        break;
    }
  }

  Future<void> _showJumpDialog() async {
    final int? page = await showDialog<int>(
      context: context,
      builder: (_) => const _JumpDialog(),
    );
    if (page != null && mounted) _goToPage(page);
  }

  Future<void> _openIndex() async {
    final int? page = await Navigator.push<int>(
      context,
      MaterialPageRoute(builder: (_) => const IndexScreen(pickMode: true)),
    );
    if (page != null && mounted) _goToPage(page);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('سورة ${getSurahNameArabic(_anchorSurah)}',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          if (_playbackTimer != null)
            IconButton(
              tooltip: 'إيقاف التتبع',
              icon: const Icon(Icons.stop_circle_outlined),
              onPressed: _stopPlayback,
            ),
          IconButton(
            tooltip: _hideMode ? 'إيقاف وضع الإخفاء' : 'وضع الإخفاء (حفظ)',
            icon: Icon(_hideMode ? Icons.visibility : Icons.visibility_off),
            onPressed: () =>
                _hideMode ? _stopHideMode() : _startHideMode(_currentPage),
          ),
          IconButton(
            tooltip: 'انتقال إلى صفحة',
            icon: const Icon(Icons.numbers),
            onPressed: _showJumpDialog,
          ),
          IconButton(
            tooltip: 'الفهرس',
            icon: const Icon(Icons.list_alt),
            onPressed: _openIndex,
          ),
          ValueListenableBuilder<bool>(
            valueListenable: mushafTajweedNotifier,
            builder: (_, on, __) => IconButton(
              tooltip: on ? 'إيقاف ألوان التجويد' : 'تشغيل ألوان التجويد',
              icon: Icon(on ? Icons.palette : Icons.palette_outlined),
              onPressed: () => mushafTajweedNotifier.value = !on,
            ),
          ),
          IconButton(
            tooltip: 'الإعدادات',
            icon: const Icon(Icons.tune),
            onPressed: () => showSettingsSheet(context),
          ),
        ],
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: Listenable.merge([
            editionNotifier,
            twoPageNotifier,
            twoPageMinWidthNotifier,
            customNumbersNotifier,
            numberAlignmentNotifier,
            customHeadersNotifier,
            bookmarksNotifier,
            mushafTajweedNotifier,
            verticalScrollNotifier,
            pageSnappingNotifier,
            bouncingPhysicsNotifier,
            coloredBackgroundNotifier,
            ayahPresetNotifier,
            ayahOpacityNotifier,
            ayahRadiusNotifier,
            wordPresetNotifier,
          ]),
          builder: (context, _) {
            final bool customNumbers = customNumbersNotifier.value;
            final bool customHeaders = customHeadersNotifier.value;

            return QuranPageView(
              key: ValueKey(editionNotifier.value),
              pageController: _pageController,
              highlights: _highlights,
              wordHighlights: _effectiveWordHighlights,
              isDarkMode: isDark,
              // ألوان التجويد بتكشف الكلمة، فبنوقفها أثناء الإخفاء
              isTajweed: mushafTajweedNotifier.value && !_hideMode,
              scrollDirection: verticalScrollNotifier.value
                  ? Axis.vertical
                  : Axis.horizontal,
              pageSnapping: pageSnappingNotifier.value,
              physics: bouncingPhysicsNotifier.value
                  ? const BouncingScrollPhysics()
                  : const ClampingScrollPhysics(),
              enableTwoPageLayout: twoPageNotifier.value,
              twoPageMinWidth: twoPageMinWidthNotifier.value,

              pageBackgroundColor: coloredBackgroundNotifier.value
                  ? theme.colorScheme.primary.withValues(alpha: 0.05)
                  : null,
              pagePadding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              twoPagePadding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),

              ayahHighlightStyle: buildAyahHighlightStyle(),
              wordHighlightStyle:
                  _hideMode ? _buildHideStyle() : buildWordHighlightStyle(),

              ayahNumberBuilder: customNumbers ? buildCustomAyahNumber : null,
              ayahNumberAlignment: numberAlignmentNotifier.value,
              surahHeaderBuilder: customHeaders ? buildCustomSurahHeader : null,
              basmallahBuilder: customHeaders ? buildCustomBasmallah : null,
              topBarBuilder: (context, pageIndex) {
                final color = theme.colorScheme.secondary;
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('الجزء ${getCurrentJuzNumberForPage(pageIndex)}',
                          style: TextStyle(color: color, fontWeight: FontWeight.bold)),
                      Text(getCurrentHizbTextForPage(pageIndex, isArabic: true),
                          style: TextStyle(color: color, fontWeight: FontWeight.bold)),
                    ],
                  ),
                );
              },
              bottomBarBuilder: (context, pageIndex) {
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0, bottom: 12.0),
                  child: Center(
                    child: Text(
                      '$pageIndex',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                );
              },
              pageBackgroundBuilder: (context, pageContent) {
                return Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.02),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: pageContent,
                );
              },

              onPageChanged: (pageNumber) {
                _currentPage = pageNumber;
                _updateAnchor(pageNumber);
                if (_hideMode) {
                  // يعيد الإخفاء للصفحة الجديدة
                  _startHideMode(pageNumber);
                } else {
                  setState(() {});
                }
              },
              onWordTap: _onWordTap,
              onAyahNumberTap: (surah, verse) =>
                  showAyahDetailsSheet(context, surah, verse),
              onLongPressStart: (surah, verse, details) =>
                  _showContextMenu(surah, verse, details.globalPosition),
            );
          },
        ),
      ),
    );
  }
}

class _JumpDialog extends StatefulWidget {
  const _JumpDialog();

  @override
  State<_JumpDialog> createState() => _JumpDialogState();
}

class _JumpDialogState extends State<_JumpDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final int? page = int.tryParse(_controller.text.trim());
    Navigator.pop(context, (page != null && page >= 1 && page <= totalPagesCount) ? page : null);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('الانتقال إلى صفحة'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: TextInputType.number,
        onSubmitted: (_) => _submit(),
        decoration: InputDecoration(hintText: '1 - $totalPagesCount'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        FilledButton(onPressed: _submit, child: const Text('انتقال')),
      ],
    );
  }
}

// =============================================================================
// Surah list reader screen
// =============================================================================

class SurahListReaderScreen extends StatefulWidget {
  final int initialSurah;
  final int? highlightAyah;

  const SurahListReaderScreen({
    super.key,
    this.initialSurah = 1,
    this.highlightAyah,
  });

  @override
  State<SurahListReaderScreen> createState() => _SurahListReaderScreenState();
}

class _SurahListReaderScreenState extends State<SurahListReaderScreen> {
  late int _selectedSurah;
  List<HighlightVerse> _highlights = [];
  List<WordHighlight> _wordHighlights = [];
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener = ItemPositionsListener.create();
  final ValueNotifier<int> _visibleAyah = ValueNotifier<int>(0);

  Timer? _playbackTimer;
  bool _isPlaying = false;
  int _currentPlayingAyah = 0;

  @override
  void initState() {
    super.initState();
    _selectedSurah = widget.initialSurah;
    _itemPositionsListener.itemPositions.addListener(_onPositionsChanged);

    if (widget.highlightAyah != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _highlightAndScrollToAyah(widget.highlightAyah!);
      });
    }
  }

  @override
  void dispose() {
    _itemPositionsListener.itemPositions.removeListener(_onPositionsChanged);
    _visibleAyah.dispose();
    _playbackTimer?.cancel();
    super.dispose();
  }

  void _onPositionsChanged() {
    final positions = _itemPositionsListener.itemPositions.value;
    if (positions.isEmpty) return;

    final visible = positions.where((p) => p.itemTrailingEdge > 0);
    if (visible.isEmpty) return;

    final int first =
        visible.map((p) => p.index).reduce((a, b) => a < b ? a : b);
    if (first != _visibleAyah.value) _visibleAyah.value = first;
  }

  void _highlightAndScrollToAyah(int ayahNumber) {
    if (_itemScrollController.isAttached) {
      _itemScrollController.scrollTo(
        index: ayahNumber,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOutCubic,
        alignment: 0.25,
      );
    }
    final highlightColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.amber.withValues(alpha: 0.5)
        : const Color(0xFF8D6E63).withValues(alpha: 0.3);

    setState(() {
      _highlights = [
        HighlightVerse(
          surah: _selectedSurah,
          verseNumber: ayahNumber,
          page: getPageNumber(_selectedSurah, ayahNumber),
          color: highlightColor,
        ),
      ];
    });
  }

  void _togglePlay(int startAyah) {
    if (_isPlaying) {
      _stopPlay();
      return;
    }
    setState(() {
      _currentPlayingAyah = startAyah;
      _isPlaying = true;
    });
    _highlightAndScrollToAyah(_currentPlayingAyah);

    _playbackTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_currentPlayingAyah >= getVerseCount(_selectedSurah)) {
        _stopPlay();
      } else {
        setState(() => _currentPlayingAyah++);
        _highlightAndScrollToAyah(_currentPlayingAyah);
      }
    });
  }

  void _stopPlay() {
    _playbackTimer?.cancel();
    _playbackTimer = null;
    if (!mounted) return;
    setState(() {
      _isPlaying = false;
      _currentPlayingAyah = 0;
      _highlights = [];
    });
  }

  void _onWordTap(int surah, int verse, int wordIndex, String word) {
    setState(() {
      _wordHighlights = [
        WordHighlight(
          surah: surah,
          verseNumber: verse,
          wordIndex: wordIndex,
          backgroundColor:
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.25),
        ),
      ];
    });
    if (wordRulesOnTapNotifier.value) {
      showWordTajweedSheet(context, surah, verse, wordIndex, fallbackWord: word);
    } else {
      showSnack(context, 'الكلمة ${wordIndex + 1} - آية $verse');
    }
  }

  Widget _buildProgressBar(Color primaryColor) {
    final int total = getVerseCount(_selectedSurah);
    return ValueListenableBuilder<int>(
      valueListenable: _visibleAyah,
      builder: (_, ayah, __) {
        final double progress = total == 0 ? 0 : (ayah / total).clamp(0.0, 1.0);
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ayah == 0 ? 'بداية السورة' : 'الآية $ayah من $total',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: primaryColor),
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 4,
                  color: primaryColor,
                  backgroundColor: primaryColor.withValues(alpha: 0.12),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: DropdownButtonHideUnderline(
          child: DropdownButton<int>(
            value: _selectedSurah,
            dropdownColor: Theme.of(context).cardColor,
            iconEnabledColor: primaryColor,
            style: TextStyle(
                color: primaryColor, fontWeight: FontWeight.bold, fontSize: 18),
            items: List.generate(totalSurahCount, (index) {
              final int surahNum = index + 1;
              return DropdownMenuItem(
                value: surahNum,
                child: Text('سورة ${getSurahNameArabic(surahNum)}'),
              );
            }),
            onChanged: (value) {
              if (value == null) return;
              _stopPlay();
              setState(() {
                _selectedSurah = value;
                _highlights = [];
                _wordHighlights = [];
              });
              _visibleAyah.value = 0;
              if (_itemScrollController.isAttached) {
                _itemScrollController.jumpTo(index: 0);
              }
            },
          ),
        ),
        centerTitle: true,
        actions: [
          ValueListenableBuilder<bool>(
            valueListenable: tajweedNotifier,
            builder: (_, on, __) => IconButton(
              tooltip: on ? 'إيقاف ألوان التجويد' : 'تشغيل ألوان التجويد',
              icon: Icon(on ? Icons.palette : Icons.palette_outlined),
              onPressed: () => tajweedNotifier.value = !on,
            ),
          ),
          IconButton(
            tooltip: 'الإعدادات',
            icon: const Icon(Icons.tune),
            onPressed: () => showSettingsSheet(context),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildProgressBar(primaryColor),
            Expanded(
              child: ListenableBuilder(
                listenable: Listenable.merge([
                  editionNotifier,
                  tajweedNotifier,
                  listFontSizeNotifier,
                  customNumbersNotifier,
                  numberAlignmentNotifier,
                  customHeadersNotifier,
                  bookmarksNotifier,
                  ayahPresetNotifier,
                  ayahOpacityNotifier,
                  ayahRadiusNotifier,
                  wordPresetNotifier,
                ]),
                builder: (context, _) {
                  return QuranSurahListView(
                    surahNumber: _selectedSurah,
                    highlights: _highlights,
                    wordHighlights: _wordHighlights,
                    itemScrollController: _itemScrollController,
                    itemPositionsListener: _itemPositionsListener,
                    initialScrollIndex: widget.highlightAyah ?? 0,
                    isDarkMode: isDark,
                    isTajweed: tajweedNotifier.value,
                    fontSize: listFontSizeNotifier.value,

                    wordHighlightStyle: buildWordHighlightStyle(),
                    onWordTap: _onWordTap,

                    onAyahNumberTap: (surah, verse) =>
                        showAyahDetailsSheet(context, surah, verse),
                    onLongPress: (surah, verse, details) =>
                        showAyahDetailsSheet(context, surah, verse),
                    ayahNumberBuilder:
                        customNumbersNotifier.value ? buildCustomAyahNumber : null,
                    ayahNumberAlignment: numberAlignmentNotifier.value,
                    surahHeaderBuilder:
                        customHeadersNotifier.value ? buildCustomSurahHeader : null,
                    basmallahBuilder:
                        customHeadersNotifier.value ? buildCustomBasmallah : null,

                    ayahBuilder: (context, surahNumber, verseNumber, pageNumber,
                        ayahWidget, isHighlighted, highlightColor) {
                      final bool isCurrentlyPlaying =
                          _isPlaying && _currentPlayingAyah == verseNumber;
                      final bool marked = isBookmarked(surahNumber, verseNumber);

                      final Widget card = AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: primaryColor.withValues(alpha: 0.1),
                          ),
                          boxShadow: [
                            if (!isDark)
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: primaryColor.withValues(alpha: 0.05),
                                borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(15)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: primaryColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      'آية $verseNumber • ص $pageNumber',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: primaryColor,
                                          fontSize: 12),
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      InkWell(
                                        onTap: () => _togglePlay(verseNumber),
                                        child: Icon(
                                          isCurrentlyPlaying
                                              ? Icons.pause_circle_filled
                                              : Icons.play_circle_outline,
                                          size: 26,
                                          color: isCurrentlyPlaying
                                              ? const Color(0xFFD4AF37)
                                              : primaryColor,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      InkWell(
                                        onTap: () => copyVerse(
                                            context, surahNumber, verseNumber),
                                        child: Icon(Icons.copy,
                                            size: 18, color: primaryColor),
                                      ),
                                      const SizedBox(width: 16),
                                      InkWell(
                                        onTap: () {
                                          final added = toggleBookmark(
                                              surahNumber, verseNumber);
                                          showSnack(
                                              context,
                                              added
                                                  ? 'تم حفظ الآية في العلامات المرجعية'
                                                  : 'تمت إزالة العلامة');
                                        },
                                        child: Icon(
                                          marked
                                              ? Icons.bookmark
                                              : Icons.bookmark_border,
                                          size: 20,
                                          color: primaryColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: ayahWidget,
                            ),
                          ],
                        ),
                      );

                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: buildAyahHighlightStyle().apply(
                          context,
                          card,
                          isHighlighted ? highlightColor : null,
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}