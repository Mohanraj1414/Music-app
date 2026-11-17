import 'package:Bloomee/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// Quick, source-neutral searches for the four featured music languages.
///
/// These chips query the active user-installed content plugin. They do not
/// claim the catalogue is bundled, licensed, or available in every country.
class RegionalLanguageChips extends StatelessWidget {
  const RegionalLanguageChips({super.key, required this.onSelected});

  final ValueChanged<String> onSelected;

  static const _languages = [
    (
      label: 'தமிழ்  Tamil',
      search: 'Tamil songs',
      color: Color(0xFF36E0BE),
    ),
    (
      label: 'English',
      search: 'English songs',
      color: Color(0xFF8AC3FF),
    ),
    (
      label: 'ಕನ್ನಡ  Kannada',
      search: 'Kannada songs',
      color: Color(0xFFFFD782),
    ),
    (
      label: 'हिन्दी  Hindi',
      search: 'Hindi songs',
      color: Color(0xFFB7B8FF),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'BROWSE BY LANGUAGE',
            style: TextStyle(
              fontFamily: 'Gilroy',
              color: AppTheme.primaryColor2.withValues(alpha: 0.76),
              fontSize: 11,
              letterSpacing: 1.3,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final language in _languages)
                ActionChip(
                  key: ValueKey('search-' + language.search),
                  label: Text(language.label),
                  tooltip: 'Search ' + language.search,
                  backgroundColor: const Color(0xFF14263A),
                  side: BorderSide(
                    color: language.color.withValues(alpha: 0.45),
                  ),
                  labelStyle: TextStyle(
                    fontSize: 13,
                    color: language.color,
                    fontWeight: FontWeight.w600,
                  ),
                  onPressed: () => onSelected(language.search),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
