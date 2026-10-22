import 'quran_codec.dart';

/// Quran data of the 1985 edition (expanded lazily on first access).
List get quran1985 => decodeQuran1985();