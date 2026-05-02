import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Import your highly customizable package
import 'package:qcf_quran_lite/qcf_quran_lite.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

void main() {
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
  );
  runApp(const MyApp());
}

// =============================================================================
// Theme Notifier for Dark/Light Mode Toggle
// =============================================================================
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

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
            // ضمان أن التطبيق بالكامل يعمل من اليمين لليسار (RTL)
            return Directionality(
              textDirection: TextDirection.rtl,
              child: child!,
            );
          },
          themeMode: currentMode,
          // --- Light Theme ---
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
            fontFamily: 'Cairo', // استخدم خط يدعم العربية للواجهة
          ),
          // --- Dark Theme ---
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
// Dashboard Screen (Search, Stats, and Navigation)
// =============================================================================
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map> _searchResults = [];
  int _searchOccurrences = 0;

  void _performSearch(String query) {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _searchOccurrences = 0;
      });
      return;
    }
    String cleanedQuery = normalise(query);
    Map results = searchWords(cleanedQuery);
    setState(() {
      _searchOccurrences = results['occurences'];
      _searchResults = List<Map>.from(results['result']);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'مكتبة المصحف الذكية',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
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
            // --- Navigation Buttons ---
            Row(
              children: [
                Expanded(
                  child: _buildNavButton(
                    context,
                    title: 'المصحف الكامل',
                    icon: Icons.menu_book,
                    color: primaryColor,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MushafScreen(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildNavButton(
                    context,
                    title: 'قراءة كقائمة',
                    icon: Icons.format_list_numbered_rtl,
                    color: Theme.of(context).colorScheme.secondary,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SurahListReaderScreen(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 25),

            // --- Statistics Section ---
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
                _buildStatCard('مكية', '$totalMakkiSurahs', Icons.location_on),
                const SizedBox(width: 10),
                _buildStatCard('مدنية', '$totalMadaniSurahs', Icons.location_city),
              ],
            ),
            const SizedBox(height: 30),

            // --- Search Section ---
            _buildSectionTitle('محرك البحث المدمج', primaryColor),
            const SizedBox(height: 10),
            TextField(
              controller: _searchController,
              onSubmitted: _performSearch,
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
            const SizedBox(height: 15),

            // --- Search Results ---
            if (_searchOccurrences > 0) ...[
              Text(
                'تم العثور على $_searchOccurrences نتيجة:',
                style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor),
              ),
              const SizedBox(height: 10),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _searchResults.length > 5 ? 5 : _searchResults.length,
                itemBuilder: (context, index) {
                  final result = _searchResults[index];
                  int sNum = result['sora'];
                  int vNum = result['aya_no'];
                  String sName = getSurahNameArabic(sNum);
                  int pNum = getPageNumber(sNum, vNum);
                  String verseText = getVerse(sNum, vNum, verseEndSymbol: true);

                  return Card(
                    elevation: 1,
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(verseText, style: QuranTextStyles.hafsStyle(fontSize: 23.55)),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'سورة $sName - آية $vNum (صفحة $pNum)',
                                style: TextStyle(color: primaryColor, fontSize: 12),
                              ),
                              IconButton(
                                icon: Icon(Icons.menu_book, color: primaryColor, size: 20),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => MushafScreen(
                                        initialPage: pNum,
                                        highlightSurah: sNum,
                                        highlightAyah: vNum,
                                      ),
                                    ),
                                  );
                                },
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
            ],
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
        Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _buildNavButton(BuildContext context, {required String title, required IconData icon, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color.withOpacity(0.5)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
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
              Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Mushaf Screen (Professional UI & Gesture Integration)
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
  List<HighlightVerse> _activeHighlights = [];
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late ValueNotifier<String> _hizbTextNotifier;

  Timer? _highlightTimer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialPage - 1);
    _hizbTextNotifier = ValueNotifier(getCurrentHizbTextForPage(widget.initialPage, isArabic: true));

    // Handle initial incoming highlight (e.g., from search)
    if (widget.highlightSurah != null && widget.highlightAyah != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _triggerTemporaryHighlight(widget.highlightSurah!, widget.highlightAyah!, widget.initialPage);
      });
    }
  }

  /// Temporarily highlights a verse for a few seconds
  void _triggerTemporaryHighlight(int surah, int ayah, int page) {
    final highlightColor = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFFD4AF37) // Gold in dark mode
        : Theme.of(context).colorScheme.primary;

    setState(() {
      _activeHighlights.add(HighlightVerse(surah: surah, verseNumber: ayah, page: page, color: highlightColor));
    });

    _highlightTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() {
          _activeHighlights.removeWhere((h) => h.surah == surah && h.verseNumber == ayah);
        });
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _hizbTextNotifier.dispose();
    _highlightTimer?.cancel();
    super.dispose();
  }

  /// Displays an interactive Context Menu (Popup) right next to the user's finger
  void _showContextMenu(BuildContext context, int surahNumber, int verseNumber, Offset globalPosition) async {
    final currentPage = _pageController.hasClients ? _pageController.page!.toInt() + 1 : widget.initialPage;

    // First, highlight the verse while the menu is open to show selection
    final highlightColor = Theme.of(context).colorScheme.primary;

    setState(() {
      _activeHighlights.add(HighlightVerse(surah: surahNumber, verseNumber: verseNumber, page: currentPage, color: highlightColor));
    });

    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;

    // Show the menu at the exact touch coordinates
    final String? result = await showMenu<String>(
      context: context,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      color: Theme.of(context).cardColor,
      position: RelativeRect.fromRect(
        globalPosition & const Size(40, 40),
        Offset.zero & overlay.size,
      ),
      items: [
        PopupMenuItem(
          value: 'play',
          child: Row(children: const [Icon(Icons.play_circle_outline), SizedBox(width: 10), Text('استماع للآية')]),
        ),
        PopupMenuItem(
          value: 'copy',
          child: Row(children: const [Icon(Icons.copy), SizedBox(width: 10), Text('نسخ الآية')]),
        ),
        PopupMenuItem(
          value: 'bookmark',
          child: Row(children: const [Icon(Icons.bookmark_border), SizedBox(width: 10), Text('حفظ كعلامة')]),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'details',
          child: Row(children: const [Icon(Icons.info_outline), SizedBox(width: 10), Text('تفاصيل الآية')]),
        ),
      ],
    );

    // Remove the temporary highlight once the menu is closed
    setState(() {
      _activeHighlights.removeWhere((h) => h.surah == surahNumber && h.verseNumber == verseNumber);
    });

    // Handle the user's selection
    if (result != null) {
      switch (result) {
        case 'copy':
          final verseText = getVerse(surahNumber, verseNumber, verseEndSymbol: true);
          Clipboard.setData(ClipboardData(text: verseText));
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم نسخ الآية بنجاح')));
          break;
        case 'bookmark':
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ الآية في العلامات المرجعية')));
          break;
        case 'details':
          _showAyahDetailsBottomSheet(context, surahNumber, verseNumber, currentPage);
          break;
      }
    }
  }

  /// Shows the detailed bottom sheet for the selected verse
  void _showAyahDetailsBottomSheet(BuildContext context, int surahNumber, int verseNumber, int pageNumber) {
    final String surahAr = getSurahNameArabic(surahNumber);
    final int juz = getJuzNumber(surahNumber, verseNumber);
    final String revelation = getPlaceOfRevelation(surahNumber);
    final int qtr = getQuarterNumber(surahNumber, verseNumber);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey.withOpacity(0.5), borderRadius: BorderRadius.circular(10))),
              const SizedBox(height: 20),
              Text('سورة $surahAr', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildBottomSheetCard(context, 'الآية', '$verseNumber', Icons.menu_book),
                  _buildBottomSheetCard(context, 'الصفحة', '$pageNumber', Icons.auto_stories),
                  _buildBottomSheetCard(context, 'الجزء', '$juz', Icons.pie_chart),
                  _buildBottomSheetCard(context, 'النزول', revelation == 'Makkah' ? 'مكية' : 'مدنية', Icons.location_on),
                  _buildBottomSheetCard(context, 'الربع', '$qtr', Icons.data_usage),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomSheetCard(BuildContext context, String title, String value, IconData icon) {
    return Container(
      width: 65,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFFD4AF37), size: 20),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      body: SafeArea(
        child: QuranPageView(
          // --- Core Settings ---
          pageController: _pageController,
          highlights: _activeHighlights,
          scrollDirection: Axis.horizontal,
          pageSnapping: true,

          // --- Styling ---
          ayahStyle: TextStyle(color: Theme.of(context).textTheme.bodyLarge!.color),
          pagePadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          highlightPadding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),

          // 🌟 Custom Highlight Decoration API in action 🌟
          customHighlightDecoration: (highlightColor) {
            return BoxDecoration(
              color: highlightColor.withOpacity(0.15), // Light transparent fill
              border: Border.all(
                color: highlightColor, // Solid border
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(8.0), // Rounded corners
            );
          },

          // --- Builders ---
          // Creates a dynamic top bar that scrolls with the page
          topBarBuilder: (context, pageIndex) {
            return Padding(
              padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 12.0, bottom: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('الجزء ${getCurrentJuzNumberForPage(pageIndex)}', style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontWeight: FontWeight.bold)),
                  Text(getCurrentHizbTextForPage(pageIndex, isArabic: true), style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontWeight: FontWeight.bold)),
                ],
              ),
            );
          },
          // Creates a dynamic bottom bar for the page number
          bottomBarBuilder: (context, pageIndex) {
            return Padding(
              padding: const EdgeInsets.only(top: 8.0, bottom: 12.0),
              child: Center(
                child: Text('$pageIndex', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).colorScheme.primary)),
              ),
            );
          },
          // Background builder for the page (Optional texture or border)
          pageBackgroundBuilder: (context, pageContent) {
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.02),
                borderRadius: BorderRadius.circular(10),
              ),
              child: pageContent,
            );
          },

          // --- Gestures & Interactivity ---
          onPageChanged: (pageNumber) {
            _hizbTextNotifier.value = getCurrentHizbTextForPage(pageNumber, isArabic: true);
          },
          // Triggers on double tap
          onDoubleTap: (surahNumber, verseNumber) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم الحفظ كعلامة سريعة')));
          },
          // Trigger the Context Menu on Long Press using global positioning
          onLongPressStart: (surahNumber, verseNumber, details) {
            _showContextMenu(context, surahNumber, verseNumber, details.globalPosition);
          },
        ),
      ),
    );
  }
}

// =============================================================================
// Surah List Reader Screen
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
  final ItemScrollController _itemScrollController = ItemScrollController();

  Timer? _playbackTimer;
  bool _isPlaying = false;
  int _currentPlayingAyah = 0;

  @override
  void initState() {
    super.initState();
    _selectedSurah = widget.initialSurah;

    if (widget.highlightAyah != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _highlightAndScrollToAyah(widget.highlightAyah!);
      });
    }
  }

  void _highlightAndScrollToAyah(int ayahNumber) {
    if (_itemScrollController.isAttached) {
      _itemScrollController.scrollTo(index: ayahNumber, duration: const Duration(milliseconds: 800), curve: Curves.easeInOutCubic, alignment: 0.25);
    }
    final highlightColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.amber.withOpacity(0.5)
        : const Color(0xFF8D6E63).withOpacity(0.3);

    setState(() {
      _highlights = [HighlightVerse(surah: _selectedSurah, verseNumber: ayahNumber, page: 0, color: highlightColor)];
    });
  }

  void _togglePlay(int startAyah) {
    if (_isPlaying) {
      _stopPlay();
    } else {
      setState(() {
        _currentPlayingAyah = startAyah;
        _isPlaying = true;
      });
      _highlightAndScrollToAyah(_currentPlayingAyah);

      _playbackTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
        int maxAyahs = getVerseCount(_selectedSurah);
        if (_currentPlayingAyah >= maxAyahs) {
          _stopPlay();
        } else {
          setState(() => _currentPlayingAyah++);
          _highlightAndScrollToAyah(_currentPlayingAyah);
        }
      });
    }
  }

  void _stopPlay() {
    _playbackTimer?.cancel();
    setState(() {
      _isPlaying = false;
      _currentPlayingAyah = 0;
      _highlights = [];
    });
  }

  @override
  void dispose() {
    _playbackTimer?.cancel();
    super.dispose();
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
            style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 18),
            items: List.generate(114, (index) {
              int surahNum = index + 1;
              return DropdownMenuItem(value: surahNum, child: Text('سورة ${getSurahNameArabic(surahNum)}'));
            }),
            onChanged: (value) {
              if (value != null) {
                _stopPlay();
                setState(() {
                  _selectedSurah = value;
                  _highlights = [];
                });
                if (_itemScrollController.isAttached) {
                  _itemScrollController.jumpTo(index: 0);
                }
              }
            },
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: QuranSurahListView(
          surahNumber: _selectedSurah,
          highlights: _highlights,
          itemScrollController: _itemScrollController,
          initialScrollIndex: widget.highlightAyah ?? 0,
          ayahBuilder: (context, surahNumber, verseNumber, othmanicText, isHighlighted, highlightColor) {
            final bool isCurrentlyPlaying = _isPlaying && _currentPlayingAyah == verseNumber;

            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isHighlighted ? highlightColor.withOpacity(0.15) : Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isHighlighted ? highlightColor : primaryColor.withOpacity(0.1), width: isHighlighted ? 1.5 : 1),
                boxShadow: [
                  if (!isDark && !isHighlighted) BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.05),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(color: primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                          child: Text('آية $verseNumber', style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor, fontSize: 12)),
                        ),
                        Row(
                          children: [
                            InkWell(
                              onTap: () => _togglePlay(verseNumber),
                              child: Icon(
                                isCurrentlyPlaying ? Icons.pause_circle_filled : Icons.play_circle_outline,
                                size: 26,
                                color: isCurrentlyPlaying ? const Color(0xFFD4AF37) : primaryColor,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Icon(Icons.copy, size: 18, color: primaryColor),
                            const SizedBox(width: 16),
                            Icon(Icons.share_outlined, size: 18, color: primaryColor),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      othmanicText,
                      textAlign: TextAlign.right,
                      style: QuranTextStyles.hafsStyle(fontSize: 26, color: Theme.of(context).textTheme.bodyLarge!.color, height: 1.8),
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
}