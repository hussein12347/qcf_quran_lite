import 'package:flutter/material.dart';
import 'package:qcf_quran_lite/src/widgets/quran_line.dart';
import 'package:qcf_quran_lite/src/widgets/surah_header_widget.dart';

import '../models/highlight_verse.dart';
import '../models/quran_page.dart';
import '../services/get_page.dart';
import 'bsmallah_widget.dart';

/// A highly customizable, high-performance widget to display pages of the Holy Quran.
class QuranPageView extends StatefulWidget {
  /// Controls the pages of the Quran.
  final PageController pageController;

  /// Callback triggered when the page changes. Returns the current page number.
  final Function(int)? onPageChanged;

  /// A normal list of verses that should be highlighted.
  final List<HighlightVerse> highlights;

  /// An optional widget to be displayed at the top of the Quran pages.
  final Widget? topBar;

  /// An optional widget to be displayed at the bottom of the Quran pages.
  final Widget? bottomBar;

  /// Callback triggered when a user long-presses on a verse.
  /// Provides the [surahNumber], [verseNumber], and touch [details].
  final void Function(
      int surahNumber,
      int verseNumber,
      LongPressStartDetails details,
      )? onLongPress;

  /// Total number of pages to load. Defaults to the standard 604 pages.
  final int quranPagesCount;

  /// Custom builder for the Surah header.
  final Widget Function(BuildContext context, int surahNumber)? surahHeaderBuilder;

  /// Custom builder for the Basmallah (Bismillah) widget.
  final Widget Function(BuildContext context, int surahNumber)? basmallahBuilder;

  /// Custom text style for the ayahs (verses).
  final TextStyle? ayahStyle;

  /// Background color for the Quran pages. Defaults to [Colors.transparent].
  final Color? pageBackgroundColor;

  const QuranPageView({
    super.key,
    required this.pageController,
    this.onPageChanged,
    this.highlights = const [], // تحولت لليست عادية بقيمة افتراضية
    this.onLongPress,
    this.quranPagesCount = 604,
    this.topBar,
    this.bottomBar,
    this.surahHeaderBuilder,
    this.basmallahBuilder,
    this.ayahStyle,
    this.pageBackgroundColor,
  });

  @override
  State<QuranPageView> createState() => _QuranPageViewState();
}

class _QuranPageViewState extends State<QuranPageView> {
  List<QuranPage> pages = [];

  @override
  void initState() {
    super.initState();
    _loadQuranData();
  }

  /// Fetches and processes the Quran page data.
  void _loadQuranData() {
    final quranDataProcessor = GetPage();
    quranDataProcessor.getQuran(widget.quranPagesCount);

    setState(() {
      pages = quranDataProcessor.staticPages;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        color: widget.pageBackgroundColor ?? Colors.transparent,
        child: Column(
          children: [
            if (widget.topBar != null) widget.topBar!,
            Expanded(
              child: PageView.builder(
                physics: const BouncingScrollPhysics(),
                itemCount: pages.length,
                controller: widget.pageController,
                onPageChanged: (pageIndex) {
                  if (widget.onPageChanged != null) {
                    widget.onPageChanged!(pageIndex + 1);
                  }
                },
                itemBuilder: (ctx, index) {
                  final int pageNum = index + 1;

                  return QuranSinglePageWidget(
                    key: PageStorageKey('page_$pageNum'),
                    page: pages[index],
                    pageIndex: pageNum,
                    highlights: widget.highlights, // تمرير الليست العادية
                    onLongPress: widget.onLongPress,
                    pageController: widget.pageController,
                    surahHeaderBuilder: widget.surahHeaderBuilder,
                    basmallahBuilder: widget.basmallahBuilder,
                    ayahStyle: widget.ayahStyle,
                  );
                },
              ),
            ),
            if (widget.bottomBar != null) widget.bottomBar!,
          ],
        ),
      ),
    );
  }
}

/// A specialized, internal widget that renders a single full page of the Quran.
class QuranSinglePageWidget extends StatelessWidget {
  final QuranPage page;
  final int pageIndex;
  final List<HighlightVerse> highlights; // تحولت لليست عادية
  final void Function(int, int, LongPressStartDetails)? onLongPress;
  final PageController pageController;
  final Widget Function(BuildContext context, int surahNumber)? surahHeaderBuilder;
  final Widget Function(BuildContext context, int surahNumber)? basmallahBuilder;
  final TextStyle? ayahStyle;

  const QuranSinglePageWidget({
    super.key,
    required this.page,
    required this.pageIndex,
    this.highlights = const [], // قيمة افتراضية
    this.onLongPress,
    required this.pageController,
    this.surahHeaderBuilder,
    this.basmallahBuilder,
    this.ayahStyle,
  });

  @override
  Widget build(BuildContext context) {
    final deviceSize = MediaQuery.of(context).size;
    final orientation = MediaQuery.of(context).orientation;

    return SizedBox(
      height: deviceSize.height,
      child: (pageIndex == 1 || pageIndex == 2)
          ? _buildFirstTwoPages(context, deviceSize)
          : _buildStandardPage(context, deviceSize, orientation),
    );
  }

  Widget _buildFirstTwoPages(BuildContext context, Size deviceSize) {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (page.ayahs.isNotEmpty)
                surahHeaderBuilder?.call(context, page.ayahs[0].surahNumber) ??
                    SurahHeaderWidget(suraNumber: page.ayahs[0].surahNumber),

              if (page.pageNumber == 2 && page.ayahs.isNotEmpty)
                basmallahBuilder?.call(context, page.ayahs[0].surahNumber) ??
                    BasmallahWidget(page.ayahs[0].surahNumber),

              ...page.lines.map(
                    (line) => _buildQuranLine(line, deviceSize, BoxFit.scaleDown),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStandardPage(
      BuildContext context,
      Size deviceSize,
      Orientation orientation,
      ) {
    List<String> newSurahs = [];
    return LayoutBuilder(
      builder: (context, constraints) {
        return ListView.builder(
          physics: orientation == Orientation.portrait
              ? const NeverScrollableScrollPhysics()
              : const BouncingScrollPhysics(),
          itemCount: page.lines.length,
          itemBuilder: (context, lineIndex) {
            final line = page.lines[lineIndex];
            bool isFirstAyahInSurah = false;

            if (line.ayahs.isNotEmpty) {
              if (line.ayahs[0].ayahNumber == 1 &&
                  !newSurahs.contains(line.ayahs[0].surahNameAr)) {
                newSurahs.add(line.ayahs[0].surahNameAr);
                isFirstAyahInSurah = true;
              }
            }

            double availableHeight = (orientation == Orientation.portrait
                ? constraints.maxHeight
                : deviceSize.width);

            double surahHeaderOffset = (page.numberOfNewSurahs *
                (line.ayahs.isNotEmpty && line.ayahs[0].surahNumber != 9
                    ? 110
                    : 80));

            int linesCount = page.lines.isNotEmpty ? page.lines.length : 1;
            double lineHeight =
                (availableHeight - surahHeaderOffset) * 0.95 / linesCount;

            return Column(
              children: [
                if (isFirstAyahInSurah && line.ayahs.isNotEmpty) ...[
                  surahHeaderBuilder?.call(
                    context,
                    line.ayahs[0].surahNumber,
                  ) ??
                      SurahHeaderWidget(suraNumber: line.ayahs[0].surahNumber),

                  if (line.ayahs[0].surahNumber != 9)
                    basmallahBuilder?.call(
                      context,
                      line.ayahs[0].surahNumber,
                    ) ??
                        BasmallahWidget(line.ayahs[0].surahNumber),
                ],

                SizedBox(
                  width: deviceSize.width - 32,
                  height: lineHeight > 0 ? lineHeight : 40,
                  child: _buildQuranLine(
                    line,
                    deviceSize,
                    line.ayahs.isNotEmpty && line.ayahs.last.centered
                        ? BoxFit.scaleDown
                        : BoxFit.fill,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Builds an individual line of Quranic text.
  Widget _buildQuranLine(Line line, Size deviceSize, BoxFit boxFit) {
    // تم إزالة الـ ValueListenableBuilder وتمرير الـ highlights مباشرة
    return RepaintBoundary(
      child: QuranLine(
        line,
        highlights,
        boxFit: boxFit,
        onLongPress: onLongPress,
        ayahStyle: ayahStyle,
      ),
    );
  }
}