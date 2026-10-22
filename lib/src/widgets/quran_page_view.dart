import 'package:flutter/material.dart';
import '../../qcf_quran_lite.dart';
import '../models/highlight_index.dart';
import '../models/highlight_style.dart';
import '../services/get_page.dart';
import '../services/parsed_quran_data.dart';
import 'bsmallah_widget.dart';
import 'quran_line.dart';
import 'surah_header_widget.dart';

/// A paged Quran viewer that renders the Mus'haf one page at a time, or two
/// pages side by side on wide screens.
///
/// [QuranPageView] wraps a [PageView.builder] over [quranPagesCount] pages and
/// delegates the rendering of each individual page to [QuranSinglePageWidget].
class QuranPageView extends StatefulWidget {
  /// The [PageController] used to drive the underlying [PageView].
  final PageController pageController;

  /// Called whenever the visible page changes (receives a **1-based** page number).
  final Function(int)? onPageChanged;

  /// Verse-level highlights to render on each page.
  final List<HighlightVerse> highlights;

  /// Word-level highlights to render on each page.
  final List<WordHighlight> wordHighlights;

  /// Controls how highlighted **verses** are painted (opacity, radius,
  /// padding, custom decoration, or a full wrapper widget).
  ///
  /// When `null`, a style is built from the legacy [highlightBorderRadius],
  /// [highlightPadding] and [customHighlightDecoration] parameters.
  final AyahHighlightStyle? ayahHighlightStyle;

  /// Controls how highlighted **words** are painted (background opacity,
  /// border radius, padding, custom decoration, or extra text styling).
  final WordHighlightStyle wordHighlightStyle;

  /// Called when the user taps a word.
  final void Function(
      int surahNumber, int verseNumber, int wordIndex, String word)? onWordTap;

  /// Called when the user taps the ayah-number glyph / widget.
  final void Function(int surahNumber, int verseNumber)? onAyahNumberTap;

  /// Optional custom builder for the ayah-number glyph / widget.
  final AyahNumberBuilder? ayahNumberBuilder;

  /// Alignment of the custom ayah-number [WidgetSpan].
  final PlaceholderAlignment ayahNumberAlignment;

  /// Baseline of the custom ayah-number [WidgetSpan].
  final TextBaseline ayahNumberBaseline;

  /// Whether the widget is rendered on a dark background.
  final bool isDarkMode;

  /// Whether to render using Tajweed color rules and standard Uthmanic text (`aya_text`).
  /// When `false`, renders using smart QCF glyphs (`aya_text_othmanic`).
  final bool isTajweed;

  /// Optional builder for a widget rendered above each page.
  final Widget Function(BuildContext context, int pageIndex)? topBarBuilder;

  /// Optional builder for a widget rendered below each page.
  final Widget Function(BuildContext context, int pageIndex)? bottomBarBuilder;

  /// Optional builder that wraps each rendered page.
  final Widget Function(BuildContext context, Widget pageContent)?
      pageBackgroundBuilder;

  /// Optional builder for the Surah header widget.
  final Widget Function(BuildContext context, int surahNumber)?
      surahHeaderBuilder;

  /// Optional builder for the Basmallah widget.
  final Widget Function(BuildContext context, int surahNumber)?
      basmallahBuilder;

  /// Legacy: optional builder returning a custom [Decoration] for verse highlights.
  ///
  /// Prefer [ayahHighlightStyle] (`decorationBuilder`).
  final Decoration Function(Color highlightColor)? customHighlightDecoration;

  /// Called on a single tap on a verse.
  final void Function(int surahNumber, int verseNumber)? onTap;

  /// Called on the down phase of a single tap on a verse.
  final void Function(int surahNumber, int verseNumber, TapDownDetails details)?
      onTapDown;

  /// Called on the up phase of a single tap on a verse.
  final void Function(int surahNumber, int verseNumber, TapUpDetails details)?
      onTapUp;

  /// Called when a single tap on a verse is cancelled.
  final void Function(int surahNumber, int verseNumber)? onTapCancel;

  /// Called on a double tap on a verse.
  final void Function(int surahNumber, int verseNumber)? onDoubleTap;

  /// Called on the down phase of the first tap of a double tap.
  final void Function(int surahNumber, int verseNumber, TapDownDetails details)?
      onDoubleTapDown;

  /// Called when a double tap on a verse is cancelled.
  final void Function(int surahNumber, int verseNumber)? onDoubleTapCancel;

  /// Called on a long press on a verse.
  final void Function(int surahNumber, int verseNumber)? onLongPress;

  /// Called on the start phase of a long press on a verse.
  final void Function(
          int surahNumber, int verseNumber, LongPressStartDetails details)?
      onLongPressStart;

  /// Called on each pointer move during a long press on a verse.
  final void Function(
          int surahNumber, int verseNumber, LongPressMoveUpdateDetails details)?
      onLongPressMoveUpdate;

  /// Called on the up phase of a long press on a verse.
  final void Function(int surahNumber, int verseNumber)? onLongPressUp;

  /// Called on the end phase of a long press on a verse.
  final void Function(
          int surahNumber, int verseNumber, LongPressEndDetails details)?
      onLongPressEnd;

  /// Called when a long press on a verse is cancelled.
  final void Function(int surahNumber, int verseNumber)? onLongPressCancel;

  /// Total number of pages to render. Defaults to `604`.
  final int quranPagesCount;

  /// Scroll axis of the underlying [PageView].
  final Axis scrollDirection;

  /// Whether the [PageView] snaps to whole pages.
  final bool pageSnapping;

  /// Scroll physics of the underlying [PageView].
  final ScrollPhysics? physics;

  /// Text direction used for the wrapped content.
  final TextDirection textDirection;

  /// Base text style for the verse body.
  final TextStyle? ayahStyle;

  /// Background color applied to the whole view.
  final Color? pageBackgroundColor;

  /// Padding applied around each page in the **single-page** layout.
  final EdgeInsetsGeometry pagePadding;

  /// Padding applied around **each individual page** in the two-page layout.
  final EdgeInsetsGeometry? twoPagePadding;

  /// Legacy: padding applied inside each verse's highlight decoration.
  ///
  /// Prefer [ayahHighlightStyle] (`padding`).
  final EdgeInsetsGeometry? highlightPadding;

  /// Legacy: corner radius for the default verse highlight decoration.
  ///
  /// Prefer [ayahHighlightStyle] (`borderRadius`).
  final BorderRadiusGeometry? highlightBorderRadius;

  /// Whether the two-page layout is allowed on wide screens.
  final bool enableTwoPageLayout;

  /// Minimum available width (in logical pixels) required to switch to the two-page layout.
  final double twoPageMinWidth;

  const QuranPageView({
    super.key,
    required this.pageController,
    this.onPageChanged,
    this.highlights = const [],
    this.wordHighlights = const [],
    this.ayahHighlightStyle,
    this.wordHighlightStyle = const WordHighlightStyle(),
    this.onWordTap,
    this.onAyahNumberTap,
    this.ayahNumberBuilder,
    this.ayahNumberAlignment = PlaceholderAlignment.middle,
    this.ayahNumberBaseline = TextBaseline.alphabetic,
    this.isDarkMode = false,
    this.isTajweed = false,
    this.topBarBuilder,
    this.bottomBarBuilder,
    this.pageBackgroundBuilder,
    this.surahHeaderBuilder,
    this.basmallahBuilder,
    this.customHighlightDecoration,
    this.onTap,
    this.onTapDown,
    this.onTapUp,
    this.onTapCancel,
    this.onDoubleTap,
    this.onDoubleTapDown,
    this.onDoubleTapCancel,
    this.onLongPress,
    this.onLongPressStart,
    this.onLongPressMoveUpdate,
    this.onLongPressUp,
    this.onLongPressEnd,
    this.onLongPressCancel,
    this.quranPagesCount = 604,
    this.scrollDirection = Axis.horizontal,
    this.pageSnapping = true,
    this.physics = const BouncingScrollPhysics(),
    this.textDirection = TextDirection.rtl,
    this.ayahStyle,
    this.pageBackgroundColor,
    this.pagePadding =
        const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
    this.twoPagePadding,
    this.highlightPadding,
    this.highlightBorderRadius,
    this.enableTwoPageLayout = true,
    this.twoPageMinWidth = 750,
  });

  @override
  State<QuranPageView> createState() => _QuranPageViewState();
}

class _QuranPageViewState extends State<QuranPageView> {
  List<QuranPage> pages = [];

  final MemoizedWordHighlightIndex _wordHighlightIndexer =
      MemoizedWordHighlightIndex();
  final MemoizedBookmarkIndex _bookmarkIndexer = MemoizedBookmarkIndex();

  late WordHighlightIndex _wordHighlightIndex;
  late BookmarkIndex _bookmarkIndex;
  late PageController _twoPageController;

  bool _isSyncing = false;
  bool? _lastLayoutMode;
  late int _currentPage;
  DateTime _switchUntil = DateTime.fromMillisecondsSinceEpoch(0);

  bool get _isSwitching => DateTime.now().isBefore(_switchUntil);

  @override
  void initState() {
    super.initState();

    final int initialPage = widget.pageController.initialPage;
    _currentPage = initialPage;

    _twoPageController = PageController(initialPage: initialPage ~/ 2);

    widget.pageController.addListener(_syncExternalToInternal);
    _twoPageController.addListener(_syncInternalToExternal);

    _wordHighlightIndex = _wordHighlightIndexer.refresh(widget.wordHighlights);
    _bookmarkIndex = _bookmarkIndexer.refresh(widget.highlights);
    _loadQuranData();
  }

  @override
  void didUpdateWidget(covariant QuranPageView oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!identical(oldWidget.pageController, widget.pageController)) {
      oldWidget.pageController.removeListener(_syncExternalToInternal);
      widget.pageController.addListener(_syncExternalToInternal);
    }

    _wordHighlightIndex = _wordHighlightIndexer.refresh(widget.wordHighlights);
    _bookmarkIndex = _bookmarkIndexer.refresh(widget.highlights);
  }

  @override
  void dispose() {
    widget.pageController.removeListener(_syncExternalToInternal);
    _twoPageController.removeListener(_syncInternalToExternal);
    _twoPageController.dispose();
    super.dispose();
  }

  void _loadQuranData() {
    final quranDataProcessor = GetPage();
    quranDataProcessor.getQuran(widget.quranPagesCount);
    setState(() {
      pages = quranDataProcessor.staticPages;
    });
  }

  /// Keeps the two-page controller in sync when the external controller moves.
  void _syncExternalToInternal() {
    if (_isSyncing || _isSwitching) return;

    if (!widget.pageController.hasClients || !_twoPageController.hasClients) {
      return;
    }

    final double? externalPage = widget.pageController.page;
    if (externalPage == null) return;

    if (_twoPageController.position.isScrollingNotifier.value) return;

    final int pageIndex = externalPage.round();
    _currentPage = pageIndex;

    final int targetPair = pageIndex ~/ 2;

    if (_twoPageController.page?.round() == targetPair) return;

    _isSyncing = true;
    try {
      _twoPageController.jumpToPage(targetPair);
    } finally {
      _isSyncing = false;
    }
  }

  /// Keeps the external controller in sync when the two-page view is scrolled.
  void _syncInternalToExternal() {
    if (_isSyncing || _isSwitching) return;

    if (!widget.pageController.hasClients || !_twoPageController.hasClients) {
      return;
    }

    if (!_twoPageController.position.isScrollingNotifier.value) return;

    final double? internalPage = _twoPageController.page;
    if (internalPage == null) return;

    final int pairIndex = internalPage.round();
    final int targetSingle = pairIndex * 2;

    final int? currentExternal = widget.pageController.page?.round();
    if (currentExternal != null && currentExternal ~/ 2 == pairIndex) {
      _currentPage = currentExternal;
      return;
    }

    _isSyncing = true;
    try {
      _currentPage = targetSingle;
      widget.pageController.jumpToPage(targetSingle);
    } finally {
      _isSyncing = false;
    }
  }

  /// Re-applies the current page to both controllers after a layout switch.
  void _applyCurrentPage() {
    if (!widget.pageController.hasClients || !_twoPageController.hasClients) {
      return;
    }
    if (pages.isEmpty) return;

    final int page = _currentPage.clamp(0, pages.length - 1);
    final int pair = page ~/ 2;

    _isSyncing = true;
    try {
      if (widget.pageController.page?.round() != page) {
        widget.pageController.jumpToPage(page);
      }
      if (_twoPageController.page?.round() != pair) {
        _twoPageController.jumpToPage(pair);
      }
    } finally {
      _isSyncing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: widget.textDirection,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bool useTwoPageMode = widget.enableTwoPageLayout &&
              widget.scrollDirection == Axis.horizontal &&
              constraints.maxWidth >= widget.twoPageMinWidth;

          if (_lastLayoutMode != useTwoPageMode) {
            _lastLayoutMode = useTwoPageMode;
            _switchUntil =
                DateTime.now().add(const Duration(milliseconds: 250));

            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              _applyCurrentPage();
            });
          }

          return Container(
            color: widget.pageBackgroundColor ?? Colors.transparent,
            child: IndexedStack(
              index: useTwoPageMode ? 0 : 1,
              children: [
                _buildTwoPageLayout(isActive: useTwoPageMode),
                _buildSinglePageLayout(isActive: !useTwoPageMode),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSinglePageLayout({required bool isActive}) {
    return PageView.builder(
      key: const ValueKey('quran_single_page_layout'),
      scrollDirection: widget.scrollDirection,
      pageSnapping: widget.pageSnapping,
      physics: widget.physics,
      itemCount: pages.length,
      controller: widget.pageController,
      onPageChanged: isActive
          ? (pageIndex) {
              _currentPage = pageIndex;
              widget.onPageChanged?.call(pageIndex + 1);
            }
          : null,
      itemBuilder: (ctx, index) {
        if (!isActive) return const SizedBox.expand();
        return _buildPage(ctx, index, forceFit: false);
      },
    );
  }

  Widget _buildTwoPageLayout({required bool isActive}) {
    final int pairCount = (pages.length / 2).ceil();
    final Color dividerColor = widget.isDarkMode ? Colors.white : Colors.black;

    return PageView.builder(
      key: const ValueKey('quran_two_page_layout'),
      scrollDirection: widget.scrollDirection,
      pageSnapping: widget.pageSnapping,
      physics: widget.physics,
      itemCount: pairCount,
      controller: _twoPageController,
      onPageChanged: isActive
          ? (index) {
              final int? external = widget.pageController.hasClients
                  ? widget.pageController.page?.round()
                  : null;

              final int reported =
                  (external != null && external ~/ 2 == index)
                      ? external
                      : index * 2;

              _currentPage = reported;
              widget.onPageChanged?.call(reported + 1);
            }
          : null,
      itemBuilder: (ctx, index) {
        if (!isActive) return const SizedBox.expand();

        final int firstIndex = index * 2;
        final int secondIndex = firstIndex + 1;

        return Row(
          textDirection: TextDirection.rtl,
          children: [
            Expanded(
              child: firstIndex < pages.length
                  ? _buildPage(ctx, firstIndex, forceFit: true)
                  : const SizedBox.shrink(),
            ),
            Container(
              width: 2,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    dividerColor.withValues(alpha: 0.05),
                    dividerColor.withValues(alpha: 0.15),
                    dividerColor.withValues(alpha: 0.05),
                  ],
                ),
              ),
            ),
            Expanded(
              child: secondIndex < pages.length
                  ? _buildPage(ctx, secondIndex, forceFit: true)
                  : const SizedBox.shrink(),
            ),
          ],
        );
      },
    );
  }

  /// The verse highlight style to use: the user's [QuranPageView.ayahHighlightStyle]
  /// if given, otherwise one built from the legacy parameters.
  AyahHighlightStyle get _effectiveAyahHighlightStyle =>
      widget.ayahHighlightStyle ??
      AyahHighlightStyle(
        borderRadius: widget.highlightBorderRadius ?? BorderRadius.circular(4),
        padding: widget.highlightPadding,
        decorationBuilder: widget.customHighlightDecoration,
      );

  Widget _buildPage(BuildContext ctx, int index, {required bool forceFit}) {
    final int pageNum = index + 1;

    final EdgeInsetsGeometry effectivePadding = forceFit
        ? (widget.twoPagePadding ?? widget.pagePadding)
        : widget.pagePadding;

    Widget pageContent = QuranSinglePageWidget(
      key: PageStorageKey(
        forceFit
            ? 'page_two_${pageNum}_${widget.isTajweed}'
            : 'page_${pageNum}_${widget.isTajweed}',
      ),
      page: pages[index],
      pageIndex: pageNum,
      forceFit: forceFit,
      wordHighlightIndex: _wordHighlightIndex,
      bookmarkIndex: _bookmarkIndex,
      ayahHighlightStyle: _effectiveAyahHighlightStyle,
      wordHighlightStyle: widget.wordHighlightStyle,
      onWordTap: widget.onWordTap,
      onAyahNumberTap: widget.onAyahNumberTap,
      ayahNumberBuilder: widget.ayahNumberBuilder,
      ayahNumberAlignment: widget.ayahNumberAlignment,
      ayahNumberBaseline: widget.ayahNumberBaseline,
      isDark: widget.isDarkMode,
      isTajweed: widget.isTajweed,
      onTap: widget.onTap,
      onTapDown: widget.onTapDown,
      onTapUp: widget.onTapUp,
      onTapCancel: widget.onTapCancel,
      onDoubleTap: widget.onDoubleTap,
      onDoubleTapDown: widget.onDoubleTapDown,
      onDoubleTapCancel: widget.onDoubleTapCancel,
      onLongPress: widget.onLongPress,
      onLongPressStart: widget.onLongPressStart,
      onLongPressMoveUpdate: widget.onLongPressMoveUpdate,
      onLongPressUp: widget.onLongPressUp,
      onLongPressEnd: widget.onLongPressEnd,
      onLongPressCancel: widget.onLongPressCancel,
      pageController: widget.pageController,
      surahHeaderBuilder: widget.surahHeaderBuilder,
      basmallahBuilder: widget.basmallahBuilder,
      ayahStyle: widget.ayahStyle,
      pagePadding: effectivePadding,
    );

    if (widget.pageBackgroundBuilder != null) {
      pageContent = widget.pageBackgroundBuilder!(ctx, pageContent);
    }

    return Padding(
      padding: effectivePadding,
      child: Column(
        children: [
          if (widget.topBarBuilder != null) widget.topBarBuilder!(ctx, pageNum),
          Expanded(child: pageContent),
          if (widget.bottomBarBuilder != null)
            widget.bottomBarBuilder!(ctx, pageNum),
        ],
      ),
    );
  }
}

/// Renders a single Quranic page (one Mus'haf page).
class QuranSinglePageWidget extends StatelessWidget {
  /// The page data to render.
  final QuranPage page;

  /// 1-based page number.
  final int pageIndex;

  /// Forces the page to fit the available height (used by the two-page layout).
  final bool forceFit;

  /// Lookup index for word-level highlights.
  final WordHighlightIndex wordHighlightIndex;

  /// Lookup index for verse-level highlights.
  final BookmarkIndex bookmarkIndex;

  /// How verse highlights are painted.
  final AyahHighlightStyle ayahHighlightStyle;

  /// How word highlights are painted.
  final WordHighlightStyle wordHighlightStyle;

  /// The external page controller.
  final PageController pageController;

  /// Optional builder for the Surah header widget.
  final Widget Function(BuildContext context, int surahNumber)?
      surahHeaderBuilder;

  /// Optional builder for the Basmallah widget.
  final Widget Function(BuildContext context, int surahNumber)?
      basmallahBuilder;

  /// Base text style for the verse body.
  final TextStyle? ayahStyle;

  /// Padding applied around the page.
  final EdgeInsetsGeometry pagePadding;

  /// Whether the page is rendered on a dark background.
  final bool isDark;

  /// Whether Tajweed rendering is enabled.
  final bool isTajweed;

  /// Optional custom builder for the ayah-number marker.
  final AyahNumberBuilder? ayahNumberBuilder;

  /// Alignment of the custom ayah-number [WidgetSpan].
  final PlaceholderAlignment ayahNumberAlignment;

  /// Baseline of the custom ayah-number [WidgetSpan].
  final TextBaseline ayahNumberBaseline;

  final void Function(int, int)? onAyahNumberTap;
  final void Function(int, int, int, String)? onWordTap;
  final void Function(int, int)? onTap;
  final void Function(int, int, TapDownDetails)? onTapDown;
  final void Function(int, int, TapUpDetails)? onTapUp;
  final void Function(int, int)? onTapCancel;
  final void Function(int, int)? onDoubleTap;
  final void Function(int, int, TapDownDetails)? onDoubleTapDown;
  final void Function(int, int)? onDoubleTapCancel;
  final void Function(int, int)? onLongPress;
  final void Function(int, int, LongPressStartDetails)? onLongPressStart;
  final void Function(int, int, LongPressMoveUpdateDetails)?
      onLongPressMoveUpdate;
  final void Function(int, int)? onLongPressUp;
  final void Function(int, int, LongPressEndDetails)? onLongPressEnd;
  final void Function(int, int)? onLongPressCancel;

  const QuranSinglePageWidget({
    super.key,
    required this.page,
    required this.pageIndex,
    this.forceFit = false,
    required this.wordHighlightIndex,
    required this.bookmarkIndex,
    this.ayahHighlightStyle = const AyahHighlightStyle(),
    this.wordHighlightStyle = const WordHighlightStyle(),
    required this.pageController,
    this.surahHeaderBuilder,
    this.basmallahBuilder,
    this.ayahStyle,
    required this.pagePadding,
    this.isDark = false,
    this.isTajweed = false,
    this.ayahNumberBuilder,
    this.ayahNumberAlignment = PlaceholderAlignment.middle,
    this.ayahNumberBaseline = TextBaseline.alphabetic,
    this.onAyahNumberTap,
    this.onWordTap,
    this.onTap,
    this.onTapDown,
    this.onTapUp,
    this.onTapCancel,
    this.onDoubleTap,
    this.onDoubleTapDown,
    this.onDoubleTapCancel,
    this.onLongPress,
    this.onLongPressStart,
    this.onLongPressMoveUpdate,
    this.onLongPressUp,
    this.onLongPressEnd,
    this.onLongPressCancel,
  });

  /// Parses all lines of [page] into per-word data.
  /// When [isTajweed] is `true`, uses standard `ayah.ayah` text instead of smart QCF glyphs.
  List<List<ParsedAyahData>> _parsePageLines(QuranPage page) {
    final List<List<ParsedAyahData>> parsedLines = [];
    final Map<String, int> runningWordCount = {};

    for (final line in page.lines) {
      final lineAyahs = <ParsedAyahData>[];

      // Iterate verses in reverse because each verse is wrapped in a WidgetSpan inside RichText.
      for (final ayah in line.ayahs.toList().reversed) {
        final rawOthmanic = ayah.othmanicAyah.replaceAll('\n', ' ').trim();
        final rawStandard =
            ayah.ayah.replaceAll('\n', ' ').replaceAll('\u00a0', ' ').trim();

        final activeText = isTajweed ? rawStandard : rawOthmanic;
        if (activeText.isEmpty) continue;

        final chunks = activeText
            .split(RegExp(r'\s+'))
            .where((c) => c.isNotEmpty)
            .toList();
        if (chunks.isEmpty) continue;

        final String glyph = getayaNoQCF(ayah.surahNumber, ayah.ayahNumber);
        final bool hasGlyph = isTajweed
            ? RegExp(r'^[\u0660-\u0669\u06F0-\u06F90-9\u06DD]+$')
                .hasMatch(chunks.last)
            : (chunks.last == glyph || rawOthmanic.endsWith(glyph));

        final ayahKey = '${ayah.surahNumber}-${ayah.ayahNumber}';
        int currentWordIndex = runningWordCount[ayahKey] ?? 0;

        final wordsData = <ParsedWordData>[];
        final int wordChunksCount = hasGlyph ? chunks.length - 1 : chunks.length;

        // Regular words.
        for (int i = 0; i < wordChunksCount; i++) {
          wordsData.add(ParsedWordData(
            text: chunks[i],
            wordIndex: currentWordIndex,
            isGlyph: false,
          ));
          currentWordIndex++;
        }

        // Trailing ayah-number glyph.
        if (hasGlyph) {
          wordsData.add(ParsedWordData(
            text: isTajweed ? glyph : chunks.last,
            wordIndex: null,
            isGlyph: true,
          ));
        }

        lineAyahs.add(ParsedAyahData(
          surahNumber: ayah.surahNumber,
          ayahNumber: ayah.ayahNumber,
          words: wordsData,
        ));

        runningWordCount[ayahKey] = currentWordIndex;
      }
      parsedLines.add(lineAyahs);
    }
    return parsedLines;
  }

  @override
  Widget build(BuildContext context) {
    final deviceSize = MediaQuery.of(context).size;
    final orientation = MediaQuery.of(context).orientation;

    return (pageIndex == 1 || pageIndex == 2)
        ? _buildFirstTwoPages(context, deviceSize)
        : _buildStandardPage(context, deviceSize, orientation);
  }

  Widget _buildFirstTwoPages(BuildContext context, Size deviceSize) {
    final parsedLines = _parsePageLines(page);
    final List<Widget> lineWidgets = [];

    for (int lineIndex = 0; lineIndex < page.lines.length; lineIndex++) {
      final line = page.lines[lineIndex];
      final parsedAyahsForLine = parsedLines[lineIndex];
      lineWidgets.add(
        _buildQuranLine(line, deviceSize, BoxFit.scaleDown, parsedAyahsForLine),
      );
    }

    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (page.ayahs.isNotEmpty)
              surahHeaderBuilder?.call(context, page.ayahs[0].surahNumber) ??
                  SurahHeaderWidget(suraNumber: page.ayahs[0].surahNumber),
            if (page.pageNumber == 2 && page.ayahs.isNotEmpty)
              basmallahBuilder?.call(context, page.ayahs[0].surahNumber) ??
                  BasmallahWidget(page.ayahs[0].surahNumber),
            ...lineWidgets,
          ],
        ),
      ),
    );
  }

  Widget _buildStandardPage(
      BuildContext context, Size deviceSize, Orientation orientation) {
    final parsedLines = _parsePageLines(page);

    final bool fitToHeight = orientation == Orientation.portrait || forceFit;

    final Set<String> processedSurahs = {};
    for (var line in page.lines) {
      if (line.ayahs.isNotEmpty && line.ayahs.first.ayahNumber == 1) {
        processedSurahs.add(line.ayahs.first.surahNameAr);
      }
    }
    final int headerCount = processedSurahs.length;
    processedSurahs.clear();

    return LayoutBuilder(
      builder: (context, constraints) {
        final double availableHeight =
            fitToHeight ? constraints.maxHeight : deviceSize.width;
        final int linesCount = page.lines.isNotEmpty ? page.lines.length : 1;

        const int pageSlots = 15;
        final int slots = headerCount == 0
            ? linesCount
            : (linesCount + headerCount > pageSlots
                ? linesCount + headerCount
                : pageSlots);

        final double lineHeight = availableHeight / slots;

        final double headerHeight = headerCount == 0
            ? 0
            : (availableHeight - linesCount * lineHeight) / headerCount;

        final double lineWidth = constraints.maxWidth;

        final List<Widget> lineWidgets = [];

        for (int lineIndex = 0; lineIndex < page.lines.length; lineIndex++) {
          final line = page.lines[lineIndex];
          final parsedAyahsForLine = parsedLines[lineIndex];

          bool isFirstAyahInSurah = false;
          if (line.ayahs.isNotEmpty) {
            if (line.ayahs[0].ayahNumber == 1 &&
                !processedSurahs.contains(line.ayahs[0].surahNameAr)) {
              processedSurahs.add(line.ayahs[0].surahNameAr);
              isFirstAyahInSurah = true;
            }
          }

          lineWidgets.add(
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isFirstAyahInSurah && line.ayahs.isNotEmpty)
                  SizedBox(
                    width: lineWidth,
                    height: headerHeight,
                    child: _buildHeaderBlock(
                      context,
                      line.ayahs[0].surahNumber,
                      lineWidth,
                    ),
                  ),
                SizedBox(
                  width: lineWidth,
                  height: lineHeight,
                  child: _buildQuranLine(
                    line,
                    deviceSize,
                    line.ayahs.isNotEmpty && line.ayahs.last.centered
                        ? BoxFit.scaleDown
                        : BoxFit.fill,
                    parsedAyahsForLine,
                  ),
                ),
              ],
            ),
          );
        }

        if (fitToHeight) {
          return Column(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: lineWidgets,
          );
        } else {
          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(children: lineWidgets),
          );
        }
      },
    );
  }

  Widget _buildHeaderBlock(BuildContext context, int surahNumber, double width) {
    final Widget header = surahHeaderBuilder?.call(context, surahNumber) ??
        SurahHeaderWidget(suraNumber: surahNumber);

    final Widget? basmallah = surahNumber == 9
        ? null
        : (basmallahBuilder?.call(context, surahNumber) ??
            BasmallahWidget(surahNumber));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(flex: 8, child: header),
        if (basmallah != null)
          Expanded(
            flex: 3,
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: SizedBox(width: width, child: basmallah),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildQuranLine(
      Line line, Size deviceSize, BoxFit boxFit, List<ParsedAyahData> parsedAyahs) {
    return RepaintBoundary(
      child: QuranLine(
        parsedAyahs: parsedAyahs,
        wordHighlightIndex: wordHighlightIndex,
        bookmarkIndex: bookmarkIndex,
        ayahHighlightStyle: ayahHighlightStyle,
        wordHighlightStyle: wordHighlightStyle,
        onWordTap: onWordTap,
        onAyahNumberTap: onAyahNumberTap,
        ayahNumberBuilder: ayahNumberBuilder,
        ayahNumberAlignment: ayahNumberAlignment,
        ayahNumberBaseline: ayahNumberBaseline,
        isDark: isDark,
        isTajweed: isTajweed,
        boxFit: boxFit,
        ayahStyle: ayahStyle,
        onLongPress: onLongPressStart,
      ),
    );
  }
}