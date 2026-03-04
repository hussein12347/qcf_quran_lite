# qcf_quran_lite
qcf_quran_lite 📖

A highly performant, lightweight, and fully customizable Flutter package for building professional Quran applications. It provides offline Quranic data (Othmanic text), advanced search capabilities, rich metadata, and production-ready reading UI components.

✨ Key Features

📖 Two Reading Modes: Comes with QuranPageView (Classic Mushaf layout with swipe gestures) and QuranSurahListView (Scrollable List layout).

🔍 Advanced Normalized Search: Built-in lightning-fast search engine that handles Arabic text normalization (ignores diacritics/Tashkeel, Alef variations, etc.) for 100% accurate results.

🎨 Ultimate Customization & Theming: Override the default UI entirely. Seamlessly adapts to Dark/Light Mode via ayahStyle. Use your own ayahBuilder, surahHeaderBuilder (e.g., custom image frames), and basmallahBuilder.

⚡ High Performance Highlighting: Uses ValueNotifier for verse highlighting, ensuring smooth 60fps performance without rebuilding the whole screen. Supports single, multiple, and temporary (timed) highlights.

🎵 Audio Sync Ready: QuranSurahListView natively supports auto-scrolling and programmatic jumping (via scrollable_positioned_list) to sync perfectly with audio players.

📊 Rich Metadata APIs: Instantly get Juz, Quarter, Hizb, Page number, Makki/Madani type, verse counts, and Surah names in both Arabic and English.

🌐 Localization & RTL Ready: Naturally supports Right-to-Left (RTL) reading directions and provides localized metadata out of the box.

🪶 Lightweight: Optimized JSON data structure that provides full text and metadata without bloating your app size.

📸 Screenshots

(Note: Replace these URLs with your actual repository image links once uploaded to GitHub)

<p align="center"> <img src="https://www.google.com/search?q=https://via.placeholder.com/250x500.png%3Ftext%3DClassic%2BMushaf%2BView" width="250" alt="Mushaf View"> &nbsp;&nbsp;&nbsp;&nbsp; <img src="https://www.google.com/search?q=https://via.placeholder.com/250x500.png%3Ftext%3DCustom%2BList%2BView%2B(Audio%2BSync)" width="250" alt="List View"> &nbsp;&nbsp;&nbsp;&nbsp; <img src="https://www.google.com/search?q=https://via.placeholder.com/250x500.png%3Ftext%3DSmart%2BSearch%2BEngine" width="250" alt="Search"> </p>

🚀 Getting Started

Add qcf_quran_lite to your pubspec.yaml:

dependencies:
qcf_quran_lite: ^latest_version
# Required if you want to use the Auto-Scrolling/Audio Sync feature in List View
scrollable_positioned_list: ^0.3.8


Then, import the package in your Dart code:

import 'package:qcf_quran_lite/qcf_quran_lite.dart';


🛠️ Usage Examples

1. Classic Mushaf Mode (QuranPageView)

Display the Quran in the classic page-by-page layout exactly like the printed Mushaf. It supports swipe gestures, page tracking, and high-performance verse highlighting.

final ValueNotifier<List<HighlightVerse>> _highlights = ValueNotifier([]);
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
// Toggle Highlight
_highlights.value = [
HighlightVerse(
surah: surahNumber,
verseNumber: verseNumber,
page: _pageController.page!.toInt() + 1,
color: Colors.amber.withValues(alpha: 0.3)
)
];
},
)


2. List Reading Mode & Audio Sync (QuranSurahListView)

Ideal for Tafseer views, translations, or synced audio reading. It renders a specific Surah as a list and allows programmatic scrolling.

final ItemScrollController _itemScrollController = ItemScrollController();

QuranSurahListView(
surahNumber: 1, // Al-Fatihah
highlightsNotifier: _highlights,
itemScrollController: _itemScrollController, // Attach for Audio Sync
)


Syncing with Audio: When your audio player moves to the next verse (e.g., Ayah 5), just call:

_itemScrollController.scrollTo(
index: 5,
duration: const Duration(milliseconds: 800),
curve: Curves.easeInOutCubic,
alignment: 0.3, // Keeps the playing Ayah near the top-center of the screen
);


3. Ultimate Customization (Custom Builders)

You can completely change how headers and Ayahs look. For example, using a custom image frame for the Surah name and building interactive Ayah cards:

QuranSurahListView(
surahNumber: 1,
highlightsNotifier: _highlights,

// 1. Custom Surah Header with Image Frame
surahHeaderBuilder: (context, surahNum) {
return Stack(
alignment: Alignment.center,
children: [
Image.asset('assets/mainframe.jpg', width: double.infinity, height: 65, fit: BoxFit.fill),
Text('Surah ${getSurahNameEnglish(surahNum)}', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
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
IconButton(icon: Icon(Icons.play_arrow), onPressed: () {}), // Play Button
],
),
Text(othmanicText, style: QuranTextStyles.hafsStyle(fontSize: 26)),
],
),
);
},
)


4. Powerful Search Engine

The package includes a highly optimized search function that normalizes Arabic text to guarantee accurate results regardless of user input format.

String query = normalise("الرحمن"); // Clean the user input (removes tashkeel, standardizes Alef)
Map searchResults = searchWords(query);

int totalOccurrences = searchResults['occurences'];
List<Map> results = List<Map>.from(searchResults['result']);

for (var result in results) {
print("Found in Surah: ${result['sora']}, Ayah: ${result['aya_no']}");
}


5. Reactive Highlighting System

Easily manage highlights without triggering full UI rebuilds. Perfect for search results or audio playback.

// Add a highlight
_highlights.value = [..._highlights.value, HighlightVerse(surah: 1, verseNumber: 2, page: 1, color: Colors.blue)];

// Clear all highlights
_highlights.value = [];

// Remove a specific highlight
_highlights.value = _highlights.value.where((h) => !(h.surah == 1 && h.verseNumber == 2)).toList();


6. Rich Metadata APIs

Access any information you need about the Quran instantly without any async calls:

// Global Constants
print(totalSurahCount); // 114
print(totalVerseCount); // 6236
print(totalMakkiSurahs); // 86
print(totalMadaniSurahs); // 28

// Surah Information
String nameAr = getSurahNameArabic(1);     // "الفاتحة"
String nameEn = getSurahNameEnglish(1);    // "Al-Fatiha"
String type = getPlaceOfRevelation(1);     // "Makkah"
int ayahsCount = getVerseCount(1);         // 7

// Verse Information
String text = getVerse(1, 1);              // Returns Othmanic text with end symbol
String cleanText = removeDiacritics(text); // Text without Tashkeel
int page = getPageNumber(1, 1);            // 1
int juz = getJuzNumber(1, 1);              // 1
int quarter = getQuarterNumber(1, 1);      // 1
String hizbText = getCurrentHizbTextForPage(1, isArabic: true); // "الحزب ١"

// QCF Fonts Support
String qcfGlyph = getaya_noQCF(1, 1);      // Returns the QCF symbol for Ayah 1


📚 Complete Example

Check out the example folder in the repository for a complete, production-ready app showcasing Dark/Light mode, Audio-sync simulation, Custom UI builders, Search, and BottomSheets for verse metadata.

🤝 Contributions

Contributions, issues, and feature requests are welcome! Feel free to check the issues page.

❤️ Credits

Special thanks to the King Fahd Complex for the Printing of the Holy Quran for the Othmanic text and metadata.

📄 License

This project is licensed under the MIT License.
