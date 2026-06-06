import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:readintent_flutter/features/settings/providers/app_settings_provider.dart";
import "package:readintent_flutter/features/settings/providers/voice_preview_provider.dart";
import "package:readintent_flutter/features/tts/voice_style.dart";

class VoiceSettingsScreen extends ConsumerStatefulWidget {
  const VoiceSettingsScreen({super.key});

  @override
  ConsumerState<VoiceSettingsScreen> createState() =>
      _VoiceSettingsScreenState();
}

class _VoiceSettingsScreenState extends ConsumerState<VoiceSettingsScreen> {
  VoiceGender? _genderFilter;
  VoiceAccent? _accentFilter;

  // Captured in initState so dispose can stop the preview without touching ref
  late final VoicePreview _previewNotifier;

  @override
  void initState() {
    super.initState();
    _previewNotifier = ref.read(voicePreviewProvider.notifier);
  }

  @override
  void dispose() {
    // Stop any preview when leaving the screen.
    _previewNotifier.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selected = ref.watch(appSettingsProvider.select((s) => s.voice));
    final preview = ref.watch(voicePreviewProvider);

    ref.listen(voicePreviewProvider.select((s) => s.error), (_, error) {
      if (error != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error)));
      }
    });

    final voices = VoiceStyle.values
        .where((v) => v != VoiceStyle.unknown)
        .where((v) => _genderFilter == null || v.gender == _genderFilter)
        .where((v) => _accentFilter == null || v.accent == _accentFilter)
        .toList();
    // Keep the selected voice visible even when filters would hide it.
    if (!voices.contains(selected) && selected != VoiceStyle.unknown) {
      voices.insert(0, selected);
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Voice")),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FilterRow<VoiceGender>(
            label: "Gender",
            values: VoiceGender.values,
            selected: _genderFilter,
            labelOf: (g) => g.label,
            onSelected: (g) => setState(() => _genderFilter = g),
          ),
          _FilterRow<VoiceAccent>(
            label: "Accent",
            values: VoiceAccent.values,
            selected: _accentFilter,
            labelOf: (a) => a.label,
            onSelected: (a) => setState(() => _accentFilter = a),
          ),
          const Divider(height: 8),
          Expanded(
            child: ListView(
              children: voices.map((voice) {
                final isSelected = voice == selected;
                return ListTile(
                  leading: Icon(
                    isSelected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : null,
                  ),
                  title: Text(voice.label),
                  subtitle: Text(
                    "${voice.accent.label} · ${voice.gender.label}",
                  ),
                  trailing: _PreviewButton(
                    isGenerating: preview.isGenerating(voice),
                    isPlaying: preview.isPlaying(voice),
                    onPressed: () =>
                        ref.read(voicePreviewProvider.notifier).toggle(voice),
                  ),
                  onTap: () =>
                      ref.read(appSettingsProvider.notifier).setVoice(voice),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterRow<T> extends StatelessWidget {
  final String label;
  final List<T> values;
  final T? selected;
  final String Function(T) labelOf;
  final ValueChanged<T?> onSelected;

  const _FilterRow({
    required this.label,
    required this.values,
    required this.selected,
    required this.labelOf,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 64,
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text("All"),
                  selected: selected == null,
                  onSelected: (_) => onSelected(null),
                ),
                ...values.map(
                  (v) => ChoiceChip(
                    label: Text(labelOf(v)),
                    selected: selected == v,
                    onSelected: (_) => onSelected(v),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewButton extends StatelessWidget {
  final bool isGenerating;
  final bool isPlaying;
  final VoidCallback onPressed;

  const _PreviewButton({
    required this.isGenerating,
    required this.isPlaying,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    if (isGenerating) {
      return const SizedBox(
        width: 40,
        height: 40,
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    return IconButton(
      icon: Icon(
        isPlaying ? Icons.stop_circle_outlined : Icons.play_circle_outline,
      ),
      tooltip: isPlaying ? "Stop preview" : "Preview voice",
      onPressed: onPressed,
    );
  }
}
