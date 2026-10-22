import 'quran_codec.dart';

/// Quran data of the 2003 edition.
///
/// Stored in a compact form and expanded lazily on first access, which keeps
/// the package (and the compiled app) much smaller than a huge const literal.
List get quran => decodeQuran2003();