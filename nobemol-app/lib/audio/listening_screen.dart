import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:nobemol/audio/note_player.dart';
import 'package:nobemol/audio/piano.dart';
import 'package:nobemol/theme/tokens.dart';
import 'package:nobemol/ui/depth.dart';

/// Page d'écoute, pour le développement seulement : absente d'un build
/// release (`flutter run --profile` pour l'entendre au plus près de la
/// release). Pas traduite, elle n'est jamais livrée.
///
/// Tout le clavier, note par note, et trois parcours automatiques : les
/// notes enregistrées seules (un saut de volume entre deux fichiers), tout
/// le clavier (le décalage d'un demi-ton), une rafale (des réponses rapides
/// en arcade). Joue même si le son est coupé dans les réglages.
const listeningAvailable = !kReleaseMode;

class ListeningScreen extends ConsumerStatefulWidget {
  const ListeningScreen({super.key});

  @override
  ConsumerState<ListeningScreen> createState() => _ListeningScreenState();
}

class _ListeningScreenState extends ConsumerState<ListeningScreen> {
  static const _names = [
    'do',
    'do♯',
    'ré',
    'ré♯',
    'mi',
    'fa',
    'fa♯',
    'sol',
    'sol♯',
    'la',
    'la♯',
    'si',
  ];

  Timer? _timer;
  int? _sounding;

  @override
  void initState() {
    super.initState();
    unawaited(_player.load().catchError((Object _) {}));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  NotePlayer get _player => ref.read(notePlayerProvider);

  /// do4 pour 60.
  static String nameOf(int midi) => '${_names[midi % 12]}${midi ~/ 12 - 1}';

  void _play(int midi) {
    unawaited(_player.play([midi]).catchError((Object _) {}));
    setState(() => _sounding = midi);
  }

  void _run(List<int> notes, Duration step) {
    _timer?.cancel();
    var index = 0;
    void next() {
      if (index == notes.length) return _stop();
      _play(notes[index++]);
    }

    next();
    _timer = Timer.periodic(step, (_) => next());
  }

  void _stop() {
    _timer?.cancel();
    setState(() {
      _timer = null;
      _sounding = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final running = _timer != null;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            Space.l,
            Space.m,
            Space.l,
            Space.xl,
          ),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                key: const ValueKey('back'),
                tooltip: 'Retour',
                onPressed: () => context.pop(),
                icon: Icon(Icons.arrow_back_rounded, color: c.ink),
              ),
            ),
            Text(
              'Écoute du piano',
              style: AppText.titleScreen.copyWith(color: c.ink),
            ),
            const SizedBox(height: Space.xs),
            Text(
              'Debug. En surligné, les notes enregistrées ; les autres sont '
              'décalées d’un demi-ton.',
              style: AppText.body.copyWith(color: c.inkMuted),
            ),
            const SizedBox(height: Space.l),
            Text(
              _sounding == null ? ' ' : nameOf(_sounding!),
              key: const ValueKey('listening-now'),
              style: AppText.displayXl.copyWith(color: c.ink),
            ),
            const SizedBox(height: Space.l),
            Wrap(
              spacing: Space.s,
              runSpacing: Space.s,
              children: [
                DepthButton(
                  key: const ValueKey('listening-samples'),
                  label: 'Notes enregistrées',
                  onPressed: () =>
                      _run(pianoSamples, const Duration(milliseconds: 700)),
                ),
                DepthButton(
                  key: const ValueKey('listening-keyboard'),
                  label: 'Tout le clavier',
                  variant: ButtonVariant.outline,
                  onPressed: () => _run([
                    for (var midi = 21; midi <= 108; midi++) midi,
                  ], const Duration(milliseconds: 400)),
                ),
                DepthButton(
                  key: const ValueKey('listening-burst'),
                  label: 'Rafale',
                  variant: ButtonVariant.outline,
                  // 20 notes de la clé de sol en 2 s, comme en arcade.
                  onPressed: () => _run([
                    for (var i = 0; i < 20; i++) 60 + (i * 7) % 24,
                  ], const Duration(milliseconds: 100)),
                ),
                DepthButton(
                  key: const ValueKey('listening-stop'),
                  label: 'Stop',
                  variant: ButtonVariant.text,
                  onPressed: running ? _stop : null,
                ),
              ],
            ),
            for (var octave = 0; octave <= 8; octave++) ...[
              const SizedBox(height: Space.l),
              Text(
                'OCTAVE $octave',
                style: AppText.meta.copyWith(color: c.inkMuted),
              ),
              const SizedBox(height: Space.s),
              Wrap(
                spacing: Space.xs,
                runSpacing: Space.xs,
                children: [
                  for (var step = 0; step < 12; step++)
                    if (12 * (octave + 1) + step case final midi
                        when midi >= 21 && midi <= 108)
                      _Key(
                        midi: midi,
                        label: nameOf(midi),
                        recorded: pianoSample(midi).sample == midi,
                        sounding: midi == _sounding,
                        onTap: () => _play(midi),
                      ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Key extends StatelessWidget {
  const _Key({
    required this.midi,
    required this.label,
    required this.recorded,
    required this.sounding,
    required this.onTap,
  });

  final int midi;
  final String label;
  final bool recorded;
  final bool sounding;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: sounding
          ? c.accent
          : recorded
          ? c.accentSoft
          : c.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.sm),
        side: BorderSide(color: c.line),
      ),
      child: InkWell(
        key: ValueKey('listening-$midi'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(Radii.sm),
        child: SizedBox(
          width: 52,
          height: Sizes.minTarget,
          child: Center(
            child: Text(
              label,
              style: AppText.meta.copyWith(
                color: sounding ? c.onAccent : c.ink,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
