import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nobemol/audio/metronome.dart';
import 'package:nobemol/clock.dart';
import 'package:nobemol/reading/tapping.dart';
import 'package:nobemol/theme/tokens.dart';
import 'package:nobemol/ui/depth.dart';

enum _Phase { idle, starting, running, done }

/// Un grand bouton à taper sur un métronome. Un premier appui lance
/// [track] (le décompte, puis les temps). Chaque appui suivant est noté à
/// l'instant où le doigt se pose, depuis le premier clic (voir
/// [alignTaps]), et signalé tout de suite par [onTap]. Un demi-temps après
/// le dernier clic, [onDone] reçoit les touches, sans calage.
///
/// Les temps s'affichent aussi : le numéro du décompte sur le bouton, puis
/// un point par temps de la mesure, retardés de [latency] pour tomber avec
/// les clics entendus. Sans son, on peut taper à l'œil.
class RhythmTapper extends ConsumerStatefulWidget {
  const RhythmTapper({
    super.key,
    required this.track,
    required this.idleLabel,
    required this.tapLabel,
    required this.onDone,
    this.onTap,
    this.latency = Duration.zero,
  });

  final ClickTrack track;

  /// Sur le bouton, avant le départ.
  final String idleLabel;

  /// Sur le bouton, après le décompte.
  final String tapLabel;

  final ValueChanged<List<Duration>> onDone;

  /// À chaque touche, l'instant de sa réception depuis le premier clic :
  /// le retour sonore et haptique.
  final ValueChanged<Duration>? onTap;

  /// Le calage du téléphone : le retard entre un clic joué et la touche
  /// qui l'accompagne.
  final Duration latency;

  @override
  ConsumerState<RhythmTapper> createState() => _RhythmTapperState();
}

class _RhythmTapperState extends ConsumerState<RhythmTapper>
    with SingleTickerProviderStateMixin {
  late final Metronome _metronome;
  late final Ticker _ticker;
  var _phase = _Phase.idle;
  late DateTime _start;
  final _taps = <({Duration stamp, Duration received})>[];
  Timer? _end;

  @override
  void initState() {
    super.initState();
    _metronome = ref.read(metronomeProvider);
    unawaited(
      Future.sync(() => _metronome.prepare(widget.track))
          .catchError((Object _) {}),
    );
    _ticker = createTicker((_) => setState(() {}));
  }

  @override
  void dispose() {
    _end?.cancel();
    _ticker.dispose();
    if (_phase == _Phase.running) {
      unawaited(Future.sync(_metronome.stop).catchError((Object _) {}));
    }
    super.dispose();
  }

  Duration get _elapsed => ref.read(clockProvider)().difference(_start);

  Future<void> _begin() async {
    setState(() => _phase = _Phase.starting);
    // Le son est parti depuis [played] : le premier clic, c'était alors.
    var played = Duration.zero;
    try {
      played = await _metronome.play(widget.track);
    } catch (_) {
      // Pas de son : les temps restent visibles.
    }
    if (!mounted) return;
    _start = ref.read(clockProvider)().subtract(played);
    setState(() => _phase = _Phase.running);
    unawaited(_ticker.start());
    final track = widget.track;
    // Une touche en retard sur la dernière note arrive encore, calage
    // compris.
    final late = widget.latency.isNegative ? Duration.zero : widget.latency;
    _end = Timer(track.length + track.beat ~/ 2 + late - played, _finish);
  }

  void _finish() {
    _ticker.stop();
    setState(() => _phase = _Phase.done);
    widget.onDone(alignTaps(_taps));
  }

  void _down(PointerDownEvent event) {
    switch (_phase) {
      case _Phase.idle:
        unawaited(_begin());
      case _Phase.running:
        final received = _elapsed;
        _taps.add((stamp: event.timeStamp, received: received));
        widget.onTap?.call(received);
      case _Phase.starting || _Phase.done:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final track = widget.track;
    final running = _phase == _Phase.running;
    final heard = running ? _elapsed - widget.latency : Duration.zero;
    final beat = running
        ? (heard.isNegative
              ? 0
              : heard.inMicroseconds ~/ track.beat.inMicroseconds)
        : -1;
    final counting = running && beat < track.beatsPerMeasure;
    final label = switch (_phase) {
      _Phase.idle || _Phase.starting => widget.idleLabel,
      _ when counting => '${beat + 1}',
      _ => widget.tapLabel,
    };

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < track.beatsPerMeasure; i++)
              Container(
                key: ValueKey('beat-$i'),
                width: 12,
                height: 12,
                margin: const EdgeInsets.symmetric(horizontal: Space.xs),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      running &&
                          beat < track.beats &&
                          beat % track.beatsPerMeasure == i
                      ? (i == 0 ? c.accentDeep : c.accent)
                      : c.line,
                ),
              ),
          ],
        ),
        const SizedBox(height: Space.m),
        Listener(
          key: const ValueKey('tap-pad'),
          onPointerDown: _down,
          child: Pressable(
            colors: DepthColors(
              background: c.accent,
              foreground: c.onAccent,
              shadow: c.accentDeep,
              pressed: c.accentDeep,
            ),
            onPressed: _phase == _Phase.done ? null : () {},
            height: Sizes.tapPad,
            borderRadius: BorderRadius.circular(Radii.buttonLg),
            semanticLabel: label,
            child: Center(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: counting
                    ? AppText.displayXl.copyWith(color: c.onAccent)
                    : AppText.titleCard.copyWith(color: c.onAccent),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
