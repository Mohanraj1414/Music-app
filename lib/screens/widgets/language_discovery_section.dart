import 'package:Bloomee/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Entry points for discovering songs using the active, installed content
/// resolver. These are search shortcuts, not bundled songs or stream URLs.
class LanguageDiscoverySection extends StatelessWidget {
  const LanguageDiscoverySection({super.key});

  static const _languages = [
    _MusicLanguage(
      id: 'tamil',
      title: 'Tamil',
      nativeName: 'தமிழ்',
      subtitle: 'Kollywood • Melodies',
      query: 'Tamil songs',
      accent: Color(0xFFFF8F91),
      background: Color(0xFF512B42),
      icon: Icons.music_note_rounded,
    ),
    _MusicLanguage(
      id: 'english',
      title: 'English',
      nativeName: 'English',
      subtitle: 'Pop • Indie • Classics',
      query: 'English songs',
      accent: Color(0xFF89D7F5),
      background: Color(0xFF1D4259),
      icon: Icons.headphones_rounded,
    ),
    _MusicLanguage(
      id: 'kannada',
      title: 'Kannada',
      nativeName: 'ಕನ್ನಡ',
      subtitle: 'Sandalwood • Hits',
      query: 'Kannada songs',
      accent: Color(0xFFFFD59D),
      background: Color(0xFF57412F),
      icon: Icons.graphic_eq_rounded,
    ),
    _MusicLanguage(
      id: 'hindi',
      title: 'Hindi',
      nativeName: 'हिन्दी',
      subtitle: 'Bollywood • Trending',
      query: 'Hindi songs',
      accent: Color(0xFFC3A3FF),
      background: Color(0xFF44345E),
      icon: Icons.album_rounded,
    ),
  ];

  static const _quickSearches = [
    _QuickSearch(label: 'Tamil melodies', query: 'Tamil melody songs'),
    _QuickSearch(label: 'English pop', query: 'English pop songs'),
    _QuickSearch(label: 'Kannada classics', query: 'Kannada classic songs'),
    _QuickSearch(label: 'Hindi hits', query: 'Hindi hit songs'),
  ];

  static void _openSearch(BuildContext context, String query) {
    context.go(
      Uri(
        path: '/Search',
        queryParameters: {'query': query},
      ).toString(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'MUSIC FOR EVERY LANGUAGE',
            style: TextStyle(
              fontFamily: 'Gilroy',
              color: AppTheme.accentColor2,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Find your sound',
            style: TextStyle(
              fontFamily: 'Gilroy',
              color: AppTheme.primaryColor1,
              fontSize: 26,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Discover Tamil, English, Kannada and Hindi music.',
            style: TextStyle(
              fontFamily: 'Gilroy',
              fontSize: 13,
              color: AppTheme.primaryColor2.withValues(alpha: 0.72),
            ),
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth >= 950) {
                return Row(
                  children: [
                    for (var i = 0; i < _languages.length; i++) ...[
                      if (i > 0) const SizedBox(width: 12),
                      Expanded(
                        child: _LanguageCard(
                          language: _languages[i],
                          onTap: () =>
                              _openSearch(context, _languages[i].query),
                        ),
                      ),
                    ],
                  ],
                );
              }

              return SizedBox(
                height: 158,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  children: [
                    for (var i = 0; i < _languages.length; i++) ...[
                      if (i > 0) const SizedBox(width: 12),
                      SizedBox(
                        width: 224,
                        child: _LanguageCard(
                          language: _languages[i],
                          onTap: () =>
                              _openSearch(context, _languages[i].query),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          Text(
            'QUICK PICKS',
            style: TextStyle(
              fontFamily: 'Gilroy',
              color: AppTheme.primaryColor2.withValues(alpha: 0.75),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.3,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final pick in _quickSearches)
                ActionChip(
                  key: ValueKey('quick-' + pick.query),
                  label: Text(pick.label),
                  avatar: const Icon(
                    Icons.play_arrow_rounded,
                    size: 18,
                    color: AppTheme.primaryColor1,
                  ),
                  backgroundColor: const Color(0xFF201A24),
                  side: BorderSide(
                    color: AppTheme.primaryColor2.withValues(alpha: 0.12),
                  ),
                  labelStyle: const TextStyle(
                    fontFamily: 'Gilroy',
                    color: AppTheme.primaryColor1,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  onPressed: () => _openSearch(context, pick.query),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MusicLanguage {
  const _MusicLanguage({
    required this.id,
    required this.title,
    required this.nativeName,
    required this.subtitle,
    required this.query,
    required this.accent,
    required this.background,
    required this.icon,
  });

  final String id;
  final String title;
  final String nativeName;
  final String subtitle;
  final String query;
  final Color accent;
  final Color background;
  final IconData icon;
}

class _QuickSearch {
  const _QuickSearch({required this.label, required this.query});

  final String label;
  final String query;
}

class _LanguageCard extends StatelessWidget {
  const _LanguageCard({required this.language, required this.onTap});

  final _MusicLanguage language;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: language.accent.withValues(alpha: 0.28)),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [language.background, const Color(0xFF1B1520)],
          ),
        ),
        child: InkWell(
          key: ValueKey('language-' + language.id),
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: SizedBox(
            height: 158,
            child: Stack(
              clipBehavior: Clip.antiAlias,
              children: [
                Positioned(
                  top: -26,
                  right: -18,
                  child: Icon(
                    language.icon,
                    size: 126,
                    color: language.accent.withValues(alpha: 0.14),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(17),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        language.nativeName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: language.accent,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        language.title,
                        style: const TextStyle(
                          fontFamily: 'Gilroy',
                          fontSize: 25,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryColor1,
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              language.subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                fontFamily: 'Gilroy',
                                color: AppTheme.primaryColor1
                                    .withValues(alpha: 0.72),
                              ),
                            ),
                          ),
                          Icon(
                            Icons.arrow_outward_rounded,
                            size: 19,
                            color: language.accent,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
