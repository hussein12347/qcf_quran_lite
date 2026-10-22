import 'package:flutter/material.dart';
import 'package:qcf_quran_lite/qcf_quran_lite.dart';

/// Controls how a highlighted **verse (ayah)** is rendered.
///
/// The highlight color itself comes from `HighlightVerse.color`; this class
/// only decides *how* that color is painted.
///
/// There are three levels of customization, from simplest to most flexible:
///
/// 1. Tweak [opacity], [borderRadius], [padding] and [margin].
/// 2. Provide a [decorationBuilder] to fully control the [Decoration]
///    (borders, gradients, shadows, ...).
/// 3. Provide a [wrapperBuilder] to wrap the verse in any widget
///    (side bars, animations, ...).
class AyahHighlightStyle {
  /// Creates an ayah highlight style.
  const AyahHighlightStyle({
    this.opacity = 0.4,
    this.borderRadius = const BorderRadius.all(Radius.circular(4)),
    this.padding,
    this.margin,
    this.decorationBuilder,
    this.wrapperBuilder,
  });

  /// Opacity (0.0 - 1.0) applied to the highlight color.
  ///
  /// Ignored when [decorationBuilder] is provided.
  final double opacity;

  /// Corner radius of the default highlight background.
  ///
  /// Ignored when [decorationBuilder] is provided.
  final BorderRadiusGeometry borderRadius;

  /// Padding between the highlight edge and the verse text.
  ///
  /// When `null`, the host widget uses its own default padding.
  final EdgeInsetsGeometry? padding;

  /// Margin around the highlight.
  ///
  /// When `null`, the host widget uses its own default margin.
  final EdgeInsetsGeometry? margin;

  /// Builds a fully custom [Decoration] for the highlighted verse.
  ///
  /// Receives the verse highlight color. When provided, [opacity] and
  /// [borderRadius] are ignored.
  final Decoration Function(Color highlightColor)? decorationBuilder;

  /// Wraps the verse in an arbitrary widget when it is highlighted.
  ///
  /// This gives complete control (e.g. animated glow, side bar). It is only
  /// invoked for highlighted verses; non-highlighted verses are never wrapped.
  final Widget Function(
    BuildContext context,
    Widget child,
    Color highlightColor,
  )? wrapperBuilder;

  /// Returns the [Decoration] to paint for [color], or `null` when the verse
  /// is not highlighted (i.e. [color] is `null`).
  Decoration? decorationFor(Color? color) {
    if (color == null) return null;
    return decorationBuilder?.call(color) ??
        BoxDecoration(
          color: color.withValues(alpha: opacity),
          borderRadius: borderRadius,
        );
  }

  /// Applies this style to [child].
  ///
  /// Pass `null` as [color] for a non-highlighted verse. A container with the
  /// same [padding] and [margin] is still returned so the layout does not
  /// shift when a verse becomes highlighted.
  Widget apply(BuildContext context, Widget child, Color? color) {
    if (color != null && wrapperBuilder != null) {
      return wrapperBuilder!(context, child, color);
    }
    return Container(
      padding: padding,
      margin: margin,
      decoration: decorationFor(color),
      child: child,
    );
  }
}

/// Controls how a highlighted **word** is rendered.
///
/// The colors come from [WordHighlight.textColor] and
/// [WordHighlight.backgroundColor]; this class decides how they are applied
/// and lets you add extra text styling or box-level decorations.
///
/// Two rendering paths are supported automatically:
/// - **Inline `TextSpan` mode (default):** Fast inline rendering when only
///   [backgroundOpacity] and/or [styleBuilder] are used.
/// - **Container `WidgetSpan` mode:** Activated automatically when
///   [borderRadius], [padding], or [decorationBuilder] is provided, allowing
///   rounded corners and borders while keeping tap events functional.
///
/// ```dart
/// WordHighlightStyle(
///   backgroundOpacity: 0.3,
///   borderRadius: BorderRadius.circular(6),
///   padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
///   styleBuilder: (h, base) => base.copyWith(
///     decoration: TextDecoration.underline,
///     decorationColor: h.textColor,
///     fontWeight: FontWeight.bold,
///   ),
/// )
/// ```
class WordHighlightStyle {
  /// Creates a word highlight style.
  const WordHighlightStyle({
    this.backgroundOpacity = 1.0,
    this.borderRadius,
    this.padding,
    this.decorationBuilder,
    this.styleBuilder,
  });

  /// Multiplier (0.0 - 1.0) applied to the alpha of the word background color.
  final double backgroundOpacity;

  /// Optional corner radius for the word highlight background.
  ///
  /// When non-null, the highlighted word is rendered inside a decorated
  /// container so the rounded corners are visible.
  final BorderRadiusGeometry? borderRadius;

  /// Optional inner padding around the highlighted word.
  final EdgeInsetsGeometry? padding;

  /// Optional custom [Decoration] builder for the highlighted word container.
  final Decoration Function(WordHighlight highlight, Color? effectiveBgColor)?
      decorationBuilder;

  /// Optional hook to customize the [TextStyle] applied to a highlighted word.
  ///
  /// Receives the [highlight] and the [defaultStyle] built from its colors
  /// (only `color` and `backgroundColor` are set). The returned style is
  /// merged on top of the word's regular style, so only set what you want to
  /// change (underline, bold, different color, ...).
  final TextStyle Function(WordHighlight highlight, TextStyle defaultStyle)?
      styleBuilder;

  /// Returns `true` when box-level properties ([borderRadius], [padding], or
  /// [decorationBuilder]) require wrapping the word in a [WidgetSpan].
  bool get usesContainerDecoration =>
      borderRadius != null || padding != null || decorationBuilder != null;

  /// Computes the background color with [backgroundOpacity] applied.
  Color? effectiveBackgroundColor(WordHighlight highlight) {
    final bg = highlight.backgroundColor;
    if (bg == null) return null;
    return bg.withValues(alpha: (bg.a * backgroundOpacity).clamp(0.0, 1.0));
  }

  /// Resolves the partial [TextStyle] to merge on top of a word's style.
  TextStyle resolve(WordHighlight highlight) {
    final bg = effectiveBackgroundColor(highlight);
    final base = TextStyle(
      color: highlight.textColor,
      // In container mode the background is painted by the Container instead
      // of the TextSpan, so rectangular corners don't bleed past the radius.
      backgroundColor: usesContainerDecoration ? null : bg,
    );
    final resolved = styleBuilder?.call(highlight, base) ?? base;
    return usesContainerDecoration ? _withoutBackground(resolved) : resolved;
  }

  /// Returns a copy of [s] with `backgroundColor` and `background` removed.
  ///
  /// `TextStyle.copyWith(backgroundColor: null)` keeps the old value (null
  /// means "no change" in Flutter), so the style is rebuilt field by field.
  static TextStyle _withoutBackground(TextStyle s) => TextStyle(
        inherit: s.inherit,
        color: s.color,
        fontFamily: s.fontFamily,
        fontFamilyFallback: s.fontFamilyFallback,
        fontSize: s.fontSize,
        fontWeight: s.fontWeight,
        fontStyle: s.fontStyle,
        letterSpacing: s.letterSpacing,
        wordSpacing: s.wordSpacing,
        textBaseline: s.textBaseline,
        height: s.height,
        leadingDistribution: s.leadingDistribution,
        locale: s.locale,
        foreground: s.foreground,
        shadows: s.shadows,
        fontFeatures: s.fontFeatures,
        fontVariations: s.fontVariations,
        decoration: s.decoration,
        decorationColor: s.decorationColor,
        decorationStyle: s.decorationStyle,
        decorationThickness: s.decorationThickness,
        overflow: s.overflow,
      );

  /// Resolves the [Decoration] for container-mode word highlights.
  Decoration? resolveDecoration(WordHighlight highlight) {
    final bg = effectiveBackgroundColor(highlight);
    if (decorationBuilder != null) {
      return decorationBuilder!(highlight, bg);
    }
    if (bg == null && borderRadius == null) return null;
    return BoxDecoration(
      color: bg,
      borderRadius: borderRadius,
    );
  }

  /// Applies this [WordHighlightStyle] to a word's [TextSpan] list.
  ///
  /// - When [highlight] is `null`, returns [wordSpans] unchanged.
  /// - In inline mode, deeply merges [resolve] into every span in [wordSpans].
  /// - In container mode, wraps the styled spans in a [WidgetSpan] with a
  ///   [Container] and attaches [onTap] so word taps still fire.
  List<InlineSpan> applyToWordSpans({
    required List<TextSpan> wordSpans,
    required WordHighlight? highlight,
    VoidCallback? onTap,
  }) {
    if (highlight == null) return wordSpans;

    final extraStyle = resolve(highlight);
    final styledSpans =
        wordSpans.map((s) => mergeStyleDeep(s, extraStyle)).toList();

    if (!usesContainerDecoration) {
      return styledSpans;
    }

    Widget wordBox = Container(
      padding: padding,
      decoration: resolveDecoration(highlight),
      child: Text.rich(
        TextSpan(children: styledSpans),
        textDirection: TextDirection.rtl,
      ),
    );

    if (onTap != null) {
      wordBox = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: wordBox,
      );
    }

    return [
      WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: wordBox,
      ),
    ];
  }
}

/// Merges [extra] into [span] and, recursively, into all its nested children.
///
/// Used to apply word-highlight styling (underline, bold, foreground/background
/// color) on top of spans produced by the Tajweed builder. All span properties
/// (cursor, hover callbacks, locale, ...) are preserved.
TextSpan mergeStyleDeep(TextSpan span, TextStyle extra) {
  return TextSpan(
    text: span.text,
    recognizer: span.recognizer,
    mouseCursor: span.mouseCursor,
    onEnter: span.onEnter,
    onExit: span.onExit,
    semanticsLabel: span.semanticsLabel,
    locale: span.locale,
    spellOut: span.spellOut,
    style: (span.style ?? const TextStyle()).merge(extra),
    children: span.children
        ?.map((c) => c is TextSpan ? mergeStyleDeep(c, extra) : c)
        .toList(),
  );
}