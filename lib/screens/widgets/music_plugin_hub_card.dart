import 'package:Bloomee/core/theme/app_theme.dart';
import 'package:Bloomee/plugins/blocs/plugin/plugin_bloc.dart';
import 'package:Bloomee/plugins/blocs/plugin/plugin_state.dart';
import 'package:Bloomee/screens/screen/plugin_manager_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// A transparent entry point to every installed *compatible* plugin type.
///
/// Provider availability is controlled by the installed repository, local
/// legislation, plugin manifest compatibility, and provider licensing.
class MusicPluginHubCard extends StatelessWidget {
  const MusicPluginHubCard({super.key});

  static const _features = [
    (Icons.library_music_rounded, 'Music sources'),
    (Icons.lyrics_rounded, 'Lyrics'),
    (Icons.trending_up_rounded, 'Charts'),
    (Icons.manage_search_rounded, 'Suggestions'),
    (Icons.playlist_add_rounded, 'Importers'),
  ];

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PluginBloc, PluginState>(
      builder: (context, state) {
        final installed = state.availablePlugins.length;
        final active = state.loadedPluginIds.length;

        return Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 16),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              color: const Color(0xFF11263A),
              border: Border.all(
                color: AppTheme.accentColor2.withValues(alpha: 0.18),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.extension_rounded,
                        color: AppTheme.accentColor2,
                        size: 24,
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Music extensions',
                          style: TextStyle(
                            color: AppTheme.primaryColor1,
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        '$active/$installed active',
                        style: const TextStyle(
                          color: AppTheme.accentColor2,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Explore compatible plugins for music sources, lyrics, '
                    'charts, search suggestions and playlist importing.',
                    style: TextStyle(
                      color: AppTheme.primaryColor2.withValues(alpha: 0.8),
                      fontSize: 13,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 13),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final entry in _features)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A374C),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                entry.$1,
                                size: 15,
                                color: AppTheme.accentColor2,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                entry.$2,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.primaryColor1,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      icon: const Icon(Icons.tune_rounded, size: 19),
                      label: const Text('Manage music plugins'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.accentColor2,
                        foregroundColor: AppTheme.themeColor,
                        minimumSize: const Size(0, 43),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(13),
                        ),
                      ),
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const PluginManagerScreen(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
