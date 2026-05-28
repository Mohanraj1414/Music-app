import 'package:flutter/material.dart';

/// FontAwesome icon set - Complete set of commonly used icons
class FontAwesome {
  static const String _fontFamilySolid = 'FontAwesome-Solids';
  static const String _fontFamilyBrand = 'FontAwesome-Brands';
  static const String _fontFamilyRegular = 'FontAwesome-Regular';

  // Brand icons
  static const IconData x_twitter_brand =
      IconData(0xf081, fontFamily: _fontFamilyBrand); // Twitter/X
  static const IconData twitter_brand =
      IconData(0xf081, fontFamily: _fontFamilyBrand);
  static const IconData linkedin_brand =
      IconData(0xf08c, fontFamily: _fontFamilyBrand);
  static const IconData github_alt_brand =
      IconData(0xf113, fontFamily: _fontFamilyBrand);
  static const IconData lastfm_brand =
      IconData(0xf202, fontFamily: _fontFamilyBrand);

  // Solid icons
  static const IconData file_import_solid =
      IconData(0xf56e, fontFamily: _fontFamilySolid);
  static const IconData download_solid =
      IconData(0xf019, fontFamily: _fontFamilySolid);
  static const IconData rotate_right_solid =
      IconData(0xf2f9, fontFamily: _fontFamilySolid);
  static const IconData pause_solid =
      IconData(0xf04c, fontFamily: _fontFamilySolid);
  static const IconData play_solid =
      IconData(0xf04b, fontFamily: _fontFamilySolid);
  static const IconData plus_solid =
      IconData(0xf067, fontFamily: _fontFamilySolid);
  static const IconData backward_step_solid =
      IconData(0xf049, fontFamily: _fontFamilySolid);
  static const IconData forward_step_solid =
      IconData(0xf050, fontFamily: _fontFamilySolid);
  static const IconData chart_simple_solid =
      IconData(0xe473, fontFamily: _fontFamilySolid);

  // Regular icons
  static const IconData download_regular =
      IconData(0xf019, fontFamily: _fontFamilyRegular);
}
