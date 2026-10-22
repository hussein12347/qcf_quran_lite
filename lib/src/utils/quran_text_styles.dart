import 'package:flutter/material.dart';

/// A utility class providing ready-to-use TextStyles for rendering Quranic text.
class QuranTextStyles {
  /// The official Hafs Othmanic (QCF Smart Glyphs) font style used in normal mode.
  static TextStyle hafsStyle({
    Color? color,
    double fontSize = 23.55,
    double? height,
  }) {
    return TextStyle(
      fontFamily: 'hafs',
      package: 'qcf_quran_lite',
      color: color,
      fontSize: fontSize,
      height: height,
    );
  }

  /// The standard Uthmanic Hafs Unicode font style used in Tajweed mode
  /// to support character-level diacritic parsing and coloring.
  static TextStyle tajweedHafsStyle({
    Color? color,
    double fontSize = 23.55,
    double? height,
  }) {
    return TextStyle(
      fontFamily: 'uthmanic_hafs',
      package: 'qcf_quran_lite',
      color: color,
      fontSize: fontSize,
      height: height,
    );
  }

  /// The special decorative font used for rendering Surah names in the header.
  static TextStyle surahHeaderStyle({Color? color, double fontSize = 30.0}) {
    return TextStyle(
      fontFamily: 'arsura',
      package: 'qcf_quran_lite',
      color: color,
      fontSize: fontSize,
    );
  }

  /// Specialized font style for the Basmallah (Bismillah) calligraphic text.
  static TextStyle basmallahStyle({Color? color, double fontSize = 30.0}) {
    return TextStyle(
      fontFamily: 'QCF4_BSML',
      package: 'qcf_quran_lite',
      color: color,
      fontSize: fontSize,
    );
  }
}