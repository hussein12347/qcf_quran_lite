import 'quran_compact_raw_1985.dart';
import 'quran_compact_raw_2003.dart';
import 'quran_compact_shared.dart';

// Separators used by the generated data (see tool/generate_compact_quran_data.py).
const String _recordSep = '\u0001';
const String _fieldSep = '\u0002';
const int _noRlmMarker = 0x03;
const int _rlm = 0x200f;

List<Map<String, Object>>? _cache2003;
List<Map<String, Object>>? _cache1985;

/// Decoded Quran data of the 2003 edition (built once, on first access).
List<Map<String, Object>> decodeQuran2003() =>
    _cache2003 ??= _decode(quranCompactRaw2003, null);

/// Decoded Quran data of the 1985 edition (built once, on first access).
List<Map<String, Object>> decodeQuran1985() =>
    _cache1985 ??= _decode(quranCompactRaw2003, quranCompactPatch1985);

/// Returns field [k] from the patch when present, otherwise from the base.
String _pick(List<String> base, List<String>? patch, int k) {
  if (patch != null && k < patch.length && patch[k].isNotEmpty) return patch[k];
  return k < base.length ? base[k] : '';
}

/// The generator removes U+200F that precedes every QCF glyph (private-use
/// character); put it back. [_noRlmMarker] flags the few glyphs that had none.
String _expandOthmanic(String s) {
  final b = StringBuffer();
  var skipRlm = false;
  for (final cu in s.codeUnits) {
    if (cu == _noRlmMarker) {
      skipRlm = true;
      continue;
    }
    if (cu >= 0xE000 && cu <= 0xF8FF) {
      if (!skipRlm) b.writeCharCode(_rlm);
      skipRlm = false;
    }
    b.writeCharCode(cu);
  }
  return b.toString();
}

List<Map<String, Object>> _decode(String baseRaw, String? patchRaw) {
  final baseRecords = baseRaw.split(_recordSep);
  final patchRecords = patchRaw?.split(_recordSep);
  final emlaey = quranEmlaeyRaw.split(_recordSep);
  final namesEn = quranSurahNamesEn.split('|');
  final namesAr = quranSurahNamesAr.split('|');

  final result = <Map<String, Object>>[];
  var index = 0; // 0-based global ayah index
  var juz = 0;

  for (var s = 0; s < quranSurahAyahCounts.length; s++) {
    for (var ayah = 1; ayah <= quranSurahAyahCounts[s]; ayah++) {
      final id = index + 1;
      while (juz < quranJuzStartIds.length && quranJuzStartIds[juz] <= id) {
        juz++;
      }

      final b = baseRecords[index].split(_fieldSep);
      final p = patchRecords?[index].split(_fieldSep);
      final centered = _pick(b, p, 5) == '1';

      result.add(<String, Object>{
        'id': id,
        'jozz': juz,
        'sora': s + 1,
        'sora_name_en': namesEn[s],
        'sora_name_ar': namesAr[s],
        'page': int.parse(_pick(b, p, 0)),
        'line_start': int.parse(_pick(b, p, 1)),
        'line_end': int.parse(_pick(b, p, 2)),
        'aya_no': ayah,
        'aya_text': _pick(b, p, 3),
        'aya_text_emlaey': emlaey[index],
        if (centered) 'centered': true,
        'aya_text_othmanic': _expandOthmanic(_pick(b, p, 4)),
      });
      index++;
    }
  }
  return result;
}