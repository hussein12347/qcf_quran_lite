qcf_quran_lite 📖A highly performant, lightweight, and fully customizable Flutter package for building professional Quran applications. It provides offline Quranic data (Othmanic text), advanced search capabilities, rich metadata, and production-ready reading UI components.📸 Screenshots(Note: Replace these URLs with your actual repository image links once uploaded to GitHub)<p align="center"> <img src="https://www.google.com/search?q=https://via.placeholder.com/250x500.png%3Ftext%3DClassic%2BMushaf%2BView" width="250" alt="Mushaf View"> &nbsp;&nbsp;&nbsp;&nbsp; <img src="https://www.google.com/search?q=https://via.placeholder.com/250x500.png%3Ftext%3DCustom%2BList%2BView%2B(Audio%2BSync)" width="250" alt="List View"> &nbsp;&nbsp;&nbsp;&nbsp; <img src="https://www.google.com/search?q=https://via.placeholder.com/250x500.png%3Ftext%3DSmart%2BSearch%2BEngine" width="250" alt="Search"> </p>🚀 Getting StartedAdd qcf_quran_lite to your pubspec.yaml:dependencies:
  qcf_quran_lite: ^latest_version
  # Required if you want to use the Auto-Scrolling/Audio Sync feature in List View
  scrollable_positioned_list: ^0.3.8 
Then, import the package in your Dart code:import 'package:qcf_quran_lite/qcf_quran_lite.dart';
✨ Features & Usage Guide1. Classic Mushaf Mode (QuranPageView)Display the Quran in the classic page-by-page layout exactly like the printed Mushaf. It supports swipe gestures, page tracking, and a high-performance verse highlighting system.final ValueNotifier<List<HighlightVerse>> _highlights = ValueNotifier([]);
final PageController _pageController = PageController(initialPage: 0);

QuranPageView(
  pageController: _pageController,
  highlightsNotifier: _highlights,
  // Easily adapt to Dark/Light mode
  ayahStyle: TextStyle(color: Theme.of(context).textTheme.bodyLarge!.color),
  onPageChanged: (pageNumber) {
    print('Current Page: $pageNumber');
    // E.g., Update Appbar with: getCurrentHizbTextForPage(pageNumber)
  },
  onLongPress: (surahNumber, verseNumber, details) {
    // Toggle Highlight on long press
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
2. List Reading Mode (QuranSurahListView)Ideal for Tafseer views, translations, or reading verse-by-verse. It renders a specific Surah as a vertical list.QuranSurahListView(
  surahNumber: 1, // Al-Fatihah
  highlightsNotifier: _highlights,
  ayahStyle: TextStyle(fontSize: 24, color: Colors.black),
)
3. Audio Synchronization & Auto-ScrollingQuranSurahListView natively supports programmatic scrolling (via scrollable_positioned_list). This makes it incredibly easy to sync the UI with an audio player.final ItemScrollController _itemScrollController = ItemScrollController();

// 1. Attach the controller to the view
QuranSurahListView(
  surahNumber: 1,
  itemScrollController: _itemScrollController,
  highlightsNotifier: _highlights,
)

// 2. When your audio player moves to the next verse (e.g., Ayah 5), scroll to it:
void syncWithAudio(int currentPlayingAyah) {
  _itemScrollController.scrollTo(
    index: currentPlayingAyah, 
    duration: const Duration(milliseconds: 800), 
    curve: Curves.easeInOutCubic,
    alignment: 0.3, // Keeps the playing Ayah near the top-center of the screen
  );
}
4. Ultimate Customization (Custom Builders)You don't have to stick to the default look. You can completely change how headers and Ayahs look by providing your own widgets.QuranSurahListView(
  surahNumber: 1,
  
  // Custom Surah Header (e.g., with an Image Frame)
  surahHeaderBuilder: (context, surahNum) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Image.asset('assets/mainframe.jpg', width: double.infinity, height: 65, fit: BoxFit.fill),
        Text('Surah ${getSurahNameEnglish(surahNum)}', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
      ],
    );
  },

  // Custom Ayah Cards (e.g., with Play/Copy Buttons)
  ayahBuilder: (context, surahNumber, verseNumber, othmanicText, isHighlighted, highlightColor) {
    return Card(
      color: isHighlighted ? highlightColor : Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Ayah $verseNumber'),
              IconButton(icon: Icon(Icons.play_circle), onPressed: () {}), 
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              othmanicText, 
              textAlign: TextAlign.right,
              style: QuranTextStyles.hafsStyle(fontSize: 26),
            ),
          ),
        ],
      ),
    );
  },
)
5. Smart Search EngineThe package includes a highly optimized search function. It automatically normalizes Arabic text (removes Tashkeel, normalizes variations of Alef, Taa Marbuta, etc.) to guarantee 100% accurate results regardless of how the user types.// 1. Clean the user input
String query = normalise("الرّحْمَٰن"); 

// 2. Search the database
Map searchResults = searchWords(query);

int totalOccurrences = searchResults['occurences'];
List<Map> results = List<Map>.from(searchResults['result']);

for (var result in results) {
  print("Found in Surah: ${result['sora']}, Ayah: ${result['aya_no']}");
}
6. Reactive Highlighting SystemEasily manage temporary or permanent highlights without triggering full UI rebuilds.// Add a new highlight
_highlights.value = [
  ..._highlights.value, 
  HighlightVerse(surah: 1, verseNumber: 2, page: 1, color: Colors.blue.withOpacity(0.3))
];

// Clear all highlights
_highlights.value = [];

// Remove a specific highlight
_highlights.value = _highlights.value.where((h) => !(h.surah == 1 && h.verseNumber == 2)).toList();
7. Rich Metadata APIsAccess detailed information about the Quran synchronously (no await needed):// Global Constants
print(totalSurahCount);    // 114
print(totalVerseCount);    // 6236
print(totalMakkiSurahs);   // 86
print(totalMadaniSurahs);  // 28

// Surah Information
String nameAr = getSurahNameArabic(1);     // "الفاتحة"
String nameEn = getSurahNameEnglish(1);    // "Al-Fatiha"
String type = getPlaceOfRevelation(1);     // "Makkah"
int ayahsCount = getVerseCount(1);         // 7

// Verse Information
String text = getVerse(1, 1);              // Returns Othmanic text
String cleanText = removeDiacritics(text); // Text without Tashkeel
int page = getPageNumber(1, 1);            // 1
int juz = getJuzNumber(1, 1);              // 1
int quarter = getQuarterNumber(1, 1);      // 1

// Auto-calculating Hizb text for a specific page
String hizbTextAr = getCurrentHizbTextForPage(1, isArabic: true); // "الحزب ١"
String hizbTextEn = getCurrentHizbTextForPage(1, isArabic: false); // "Hizb 1"

// QCF Fonts Support
String qcfGlyph = getaya_noQCF(1, 1);      // Returns the QCF symbol for Ayah 1
📚 Complete ExampleCheck out the example folder in the repository for a complete, production-ready application showcasing:Dark/Light mode theme adaptability.Audio-sync simulation (Auto-Play mocking).Custom UI builders with image frames.Built-in search engine UI.BottomSheets for displaying verse metadata.🤝 ContributionsContributions, issues, and feature requests are welcome! Feel free to check the issues page.❤️ CreditsSpecial thanks to the King Fahd Complex for the Printing of the Holy Quran for the Othmanic text, fonts, and metadata.📄 LicenseThis project is licensed under the MIT License.
