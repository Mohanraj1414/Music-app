import 'dart:async';

import 'package:Bloomee/core/theme/app_theme.dart';
import 'package:Bloomee/services/bloomee_player.dart';
import 'package:Bloomee/services/player/recommendation_settings.dart';
import 'package:flutter/material.dart';

/// Player-level listening preference selector. Preferences persist and apply
/// to subsequent autoplay recommendations without interrupting a current song.
class RecommendationModeSelector extends StatelessWidget {
  const RecommendationModeSelector({super.key, required this.player});
  final BloomeeMusicPlayer player;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<RecommendationSettings>(
      stream: player.recommendationSettings,
      initialData: player.recommendationSettings.value,
      builder: (context, snapshot) {
        final settings = snapshot.data ?? const RecommendationSettings();
        return Center(
          child: TextButton.icon(
            key: const ValueKey('open-recommendation-settings'),
            onPressed: () => _openChooser(context),
            style: TextButton.styleFrom(
              backgroundColor: AppTheme.accentColor2.withValues(alpha: 0.10),
              foregroundColor: AppTheme.accentColor2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: BorderSide(
                    color: AppTheme.accentColor2.withValues(alpha: 0.28)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
            ),
            icon: const Icon(Icons.tune_rounded, size: 18),
            label: Text(
              '${settings.mode.label} • ${settings.mood.label} • '
              '${settings.language.label}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        );
      },
    );
  }

  void _openChooser(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: const Color(0xFF101F32),
      builder: (sheetContext) {
        return StreamBuilder<RecommendationSettings>(
          stream: player.recommendationSettings,
          initialData: player.recommendationSettings.value,
          builder: (context, snapshot) {
            final current = snapshot.data ?? const RecommendationSettings();
            return SafeArea(
              child: FractionallySizedBox(
                widthFactor: 1,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(22, 8, 22, 26),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Your music, your mood',
                        style: TextStyle(
                          color: AppTheme.primaryColor1,
                          fontSize: 23,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        'Choose how the next songs are discovered.',
                        style: TextStyle(color: AppTheme.primaryColor2),
                      ),
                      const SizedBox(height: 18),
                      _optionGroup<RadioMode>(
                        title: 'Recommendation mode',
                        values: RadioMode.values,
                        selected: current.mode,
                        label: (mode) => mode.label,
                        onSelected: (mode) => unawaited(
                          player.setRecommendationSettings(
                            current.copyWith(mode: mode),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        current.mode.description,
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.primaryColor2),
                      ),
                      const SizedBox(height: 22),
                      _optionGroup<ListeningMood>(
                        title: 'Mood',
                        values: ListeningMood.values,
                        selected: current.mood,
                        label: (mood) => mood.label,
                        onSelected: (mood) => unawaited(
                          player.setRecommendationSettings(
                            current.copyWith(mood: mood),
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      _optionGroup<RadioLanguage>(
                        title: 'Song language',
                        values: RadioLanguage.values,
                        selected: current.language,
                        label: (language) => language.label,
                        onSelected: (language) => unawaited(
                          player.setRecommendationSettings(
                            current.copyWith(language: language),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Recommendations use your active music plugin. '
                        'Some moods, languages or songs may be unavailable '
                        'from the selected source. Recently played tracks '
                        'are avoided where alternatives exist.',
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.45,
                          color: AppTheme.primaryColor2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () => Navigator.pop(sheetContext),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppTheme.accentColor2,
                            foregroundColor: AppTheme.themeColor,
                          ),
                          child: const Text('Done'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _optionGroup<T>({
    required String title,
    required List<T> values,
    required T selected,
    required String Function(T) label,
    required ValueChanged<T> onSelected,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppTheme.primaryColor1,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 9),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final value in values)
              ChoiceChip(
                key: ValueKey('radio-option-${value.toString()}'),
                label: Text(label(value)),
                selected: selected == value,
                onSelected: (_) => onSelected(value),
                selectedColor: AppTheme.accentColor2.withValues(alpha: 0.23),
                backgroundColor: const Color(0xFF192F45),
                side: BorderSide(
                  color: selected == value
                      ? AppTheme.accentColor2
                      : AppTheme.primaryColor2.withValues(alpha: 0.15),
                ),
                labelStyle: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selected == value
                      ? AppTheme.accentColor2
                      : AppTheme.primaryColor1,
                ),
              ),
          ],
        ),
      ],
    );
  }
}
