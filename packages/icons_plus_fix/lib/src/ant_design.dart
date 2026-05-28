/// AntDesign icon set
class AntDesign {
  static const String fontFamily = 'AntDesign';

  // Heart icons
  static const IconData heart_fill = IconData(0xe87d, fontFamily: fontFamily);
  static const IconData heart_outline =
      IconData(0xe87c, fontFamily: fontFamily);

  // Add more icons as needed for your app
}

/// Simple IconData replacement for Dart-only use
class IconData {
  final int codePoint;
  final String fontFamily;

  const IconData(this.codePoint, {required this.fontFamily});
}
