qcf_quran_lite 📖<p align="center"> <img src="https://www.google.com/search?q=https://raw.githubusercontent.com/YOUR_GITHUB_NAME/qcf_quran_lite/main/assets/mushaf_view.png" alt="Classic Mushaf View" width="32%"> <img src="https://www.google.com/search?q=https://raw.githubusercontent.com/YOUR_GITHUB_NAME/qcf_quran_lite/main/assets/list_view.png" alt="Custom List View" width="32%"> <img src="https://www.google.com/search?q=https://raw.githubusercontent.com/YOUR_GITHUB_NAME/qcf_quran_lite/main/assets/search_view.png" alt="Search Engine" width="32%"> </p>A highly performant, lightweight, and fully customizable Flutter package for building professional Quran applications.qcf_quran_lite provides offline Quranic data (Othmanic text), advanced search capabilities, rich metadata, and production-ready reading UI components built for high frame rates and full UI control.📑 Table of ContentsFeaturesGetting StartedBasic UsageClassic Mushaf ModeList Reading ModeAdvanced UsageAudio SynchronizationCustom Builders & UISmart Search EngineReactive HighlightingData & Metadata APIsSupport & Credits✨ Features📖 Two Reading Modes: Ready-to-use QuranPageView (Classic Mushaf layout) and QuranSurahListView (Scrollable List).🔍 Advanced Normalized Search: Built-in engine that ignores diacritics/Tashkeel and Alef variations for 100% accurate results.🎨 Ultimate Customization: Override the default UI completely. Easily adapt to Dark/Light themes.⚡ High Performance: Uses ValueNotifier for verse highlighting, ensuring smooth 60fps performance.🎵 Audio Sync Ready: Natively supports auto-scrolling and programmatic jumping to sync with audio players.📊 Rich Metadata APIs: Instantly get Juz, Quarter, Hizb, Page number, and Surah names (AR/EN).🪶 Lightweight: Optimized JSON data structure without bloating your app size.🚀 Getting StartedAdd dependency in your pubspec.yaml:dependencies:
  qcf_quran_lite: ^latest_version
  # Required for Auto-Scrolling/Audio Sync in List View
  scrollable_positioned_list: ^0.3.8 
Import the package:import 'package:qcf_quran_lite/qcf_quran_lite.dart';
🟢 Basic UsageClassic Mushaf ModeDisplay the Quran in the classic page-by-page layout exactly like the printed Mushaf.final ValueNotifier<List<HighlightVerse>> _highlights = ValueNotifier([]);
final PageController _pageController = PageController(initialPage: 0);

QuranPageView(
  pageController: _pageController,
  highlightsNotifier: _highlights,
  // Automatically adapts to your app's theme
  ayahStyle: TextStyle(color: Theme.of(context).textTheme.bodyLarge!.color),
  onPageChanged: (pageNumber) {
    print('Current Page: $pageNumber');
  },
  onLongPress: (surahNumber, verseNumber, details) {
    // Easily highlight tapped verses
    _highlights.value = [
      HighlightVerse(
        surah: surahNumber, 
        verseNumber: verseNumber, 
        page: _pageController.page!.toInt() + 1, 
        color: Colors.amber.withOpacity(0.3)
      )
    ];
  },
)
List Reading ModeRender a specific Surah as a vertical list, ideal for translations or reading verse-by-verse.QuranSurahListView(
  surahNumber: 1, // Al-Fatihah
  highlightsNotifier: _highlights,
  ayahStyle: TextStyle(fontSize: 24, color: Colors.black),
)
🔴 Advanced UsageAudio Synchronization & Auto-ScrollingQuranSurahListView makes it incredibly easy to sync the UI with an external audio player.final ItemScrollController _itemScrollController = ItemScrollController();

QuranSurahListView(
  surahNumber: 1,
  itemScrollController: _itemScrollController, // Attach controller
  highlightsNotifier: _highlights,
)

// Jump to the currently playing verse:
void syncWithAudio(int currentPlayingAyah) {
  _itemScrollController.scrollTo(
    index: currentPlayingAyah, 
    duration: const Duration(milliseconds: 800), 
    curve: Curves.easeInOutCubic,
    alignment: 0.3, // Keeps the playing Ayah near the top-center
  );
}
Ultimate Customization (Custom Builders)Replace default elements (like Surah headers and Ayah text) with your own interactive widgets.QuranSurahListView(
  surahNumber: 1,
  
  // 1. Custom Surah Header with an Image Frame
  surahHeaderBuilder: (context, surahNum) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Image.asset('assets/mainframe.jpg', width: double.infinity, height: 65, fit: BoxFit.fill),
        Text(
          'Surah ${getSurahNameEnglish(surahNum)}', 
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)
        ),
      ],
    );
  },

  // 2. Custom Ayah Cards with Actions
  ayahBuilder: (context, surahNumber, verseNumber, othmanicText, isHighlighted, highlightColor) {
    return Card(
      color: isHighlighted ? highlightColor : Colors.white,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Ayah $verseNumber'),
              IconButton(icon: Icon(Icons.play_circle), onPressed: () {}), 
            ],
          ),
          Text(othmanicText, textAlign: TextAlign.right, style: QuranTextStyles.hafsStyle(fontSize: 26)),
        ],
      ),
    );
  },
)
Smart Search EngineA highly optimized search function that normalizes Arabic text automatically.// 1. Clean the user input (removes tashkeel, normalizes Alef)
String query = normalise("الرّحْمَٰن"); 

// 2. Search the database
Map searchResults = searchWords(query);
List<Map> results = List<Map>.from(searchResults['result']);

print("Found ${searchResults['occurences']} results");
Reactive Highlighting SystemManage temporary or permanent highlights without full UI rebuilds.// Add a new highlight
_highlights.value = [
  ..._highlights.value, 
  HighlightVerse(surah: 1, verseNumber: 2, page: 1, color: Colors.blue.withOpacity(0.3))
];

// Clear all highlights
_highlights.value = [];
📊 Data & Metadata APIsAccess detailed information about the Quran synchronously:// Global Constants
print(totalSurahCount);    // 114
print(totalVerseCount);    // 6236

// Surah Information
String nameAr = getSurahNameArabic(1);     // "الفاتحة"
String type = getPlaceOfRevelation(1);     // "Makkah"
int ayahsCount = getVerseCount(1);         // 7

// Verse Information
String text = getVerse(1, 1);              // Returns Othmanic text
String cleanText = removeDiacritics(text); // Text without Tashkeel
int page = getPageNumber(1, 1);            // 1
int juz = getJuzNumber(1, 1);              // 1
int quarter = getQuarterNumber(1, 1);      // 1

// QCF Fonts Support
String qcfGlyph = getaya_noQCF(1, 1);      // Returns the QCF symbol for Ayah 1
📚 Complete ExampleCheck out the example folder in the repository for a complete, production-ready application showcasing Dark/Light mode, Audio-sync simulation, Custom UI builders, Search, and BottomSheets for verse metadata.❤️ Support & CreditsIf you find this package useful, please consider giving it a ⭐ on GitHub and a 👍 on pub.dev!Credits: Special thanks to the King Fahd Complex for the Printing of the Holy Quran (KFGQPC) for the Othmanic text, fonts, and metadata.📜 LicenseThis project is licensed under the MIT License.
