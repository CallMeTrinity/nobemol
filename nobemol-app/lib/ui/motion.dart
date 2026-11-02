import 'dart:math';

import 'package:flutter/material.dart';

/// Durées et courbes des animations. Courtes : une animation accompagne un
/// changement, elle ne le retarde pas.
abstract final class Motion {
  /// Retour d'un geste : un chiffre qui saute, une erreur qui tremble.
  static const fast = Duration(milliseconds: 160);

  /// Un écran ou un bloc qui change.
  static const base = Duration(milliseconds: 240);

  /// Un score qui défile.
  static const count = Duration(milliseconds: 700);

  /// Écart entre deux blocs qui entrent l'un après l'autre.
  static const stagger = Duration(milliseconds: 70);

  static const enter = Curves.easeOutCubic;
  static const exit = Curves.easeInCubic;

  /// Arrivée avec un léger dépassement : un palier, un badge.
  static const emphasis = Curves.easeOutBack;

  /// [duration], ou zéro si le téléphone demande moins d'animations
  /// (accessibilité Android : « Supprimer les animations »).
  static Duration of(BuildContext context, Duration duration) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false
      ? Duration.zero
      : duration;
}

/// Un entier qui défile jusqu'à [value] : depuis [from] à la première
/// image, puis depuis la valeur affichée à chaque changement.
class CountUp extends StatelessWidget {
  const CountUp({
    super.key,
    required this.value,
    required this.format,
    this.from,
    this.duration = Motion.count,
    this.style,
    this.textAlign,
  });

  final int value;

  /// Point de départ, `null` pour afficher [value] tout de suite.
  final int? from;
  final String Function(int value) format;
  final Duration duration;
  final TextStyle? style;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: (from ?? value).toDouble(), end: value.toDouble()),
      duration: Motion.of(context, duration),
      curve: Motion.enter,
      builder: (context, shown, _) => Text(
        format(shown.round()),
        textAlign: textAlign,
        // Chiffres de même chasse : le texte ne tremble pas en défilant.
        style: (style ?? const TextStyle()).copyWith(
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

/// Entrée d'un bloc : il monte un peu en apparaissant, après [delay].
/// Une seule fois, à sa création.
class Reveal extends StatefulWidget {
  const Reveal({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.offset = 12,
    this.scale = 1,
    this.duration = Motion.base,
    this.curve = Motion.enter,
  });

  final Widget child;
  final Duration delay;

  /// Distance de la montée, en pixels.
  final double offset;

  /// Taille de départ : 1 sans grossissement.
  final double scale;
  final Duration duration;
  final Curve curve;

  /// Délai du [index]-ième bloc d'une liste qui entre en cascade.
  static Duration staggered(int index) => Motion.stagger * index;

  @override
  State<Reveal> createState() => _RevealState();
}

class _RevealState extends State<Reveal> with SingleTickerProviderStateMixin {
  // Un seul contrôleur, attente comprise : pas de minuteur à annuler.
  late final _controller = AnimationController(vsync: this);
  late final Animation<double> _progress;

  @override
  void initState() {
    super.initState();
    final total = widget.delay + widget.duration;
    final start = total == Duration.zero
        ? 0.0
        : widget.delay.inMicroseconds / total.inMicroseconds;
    _progress = CurvedAnimation(
      parent: _controller,
      curve: Interval(start, 1, curve: widget.curve),
    );
    _controller.duration = total;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller.isAnimating || _controller.isCompleted) return;
    if (Motion.of(context, widget.duration) == Duration.zero) {
      _controller.value = 1;
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _progress,
      child: widget.child,
      builder: (context, child) {
        final t = _progress.value;
        return Opacity(
          opacity: t.clamp(0, 1),
          child: Transform.translate(
            offset: Offset(0, (1 - t) * widget.offset),
            child: widget.scale == 1
                ? child
                : Transform.scale(
                    scale: widget.scale + (1 - widget.scale) * t,
                    child: child,
                  ),
          ),
        );
      },
    );
  }
}

/// Petit saut de [child] à chaque changement de [trigger] : un score qui
/// monte, un combo qui grandit. Rien à la première image.
class Pop extends StatefulWidget {
  const Pop({
    super.key,
    required this.trigger,
    required this.child,
    this.scale = 1.15,
  });

  final Object? trigger;
  final Widget child;

  /// Taille au sommet du saut.
  final double scale;

  @override
  State<Pop> createState() => _PopState();
}

class _PopState extends State<Pop> with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(vsync: this);

  @override
  void didUpdateWidget(Pop oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger == oldWidget.trigger) return;
    final duration = Motion.of(context, Motion.fast * 1.5);
    if (duration == Duration.zero) return;
    _controller
      ..duration = duration
      ..forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      // Monte vite, redescend plus doucement.
      builder: (context, child) => Transform.scale(
        scale:
            1 +
            (widget.scale - 1) *
                sin(pi * Curves.easeOut.transform(_controller.value)),
        child: child,
      ),
    );
  }
}

/// Tremblement horizontal de [child] quand [active] passe à vrai : une
/// réponse fausse.
class Shake extends StatefulWidget {
  const Shake({super.key, required this.active, required this.child});

  final bool active;
  final Widget child;

  @override
  State<Shake> createState() => _ShakeState();
}

class _ShakeState extends State<Shake> with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(vsync: this);

  /// Amplitude, en pixels : assez pour se voir, sans toucher les voisines.
  static const _amplitude = 4.0;

  @override
  void didUpdateWidget(Shake oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.active || oldWidget.active) return;
    final duration = Motion.of(context, Motion.fast * 2);
    if (duration == Duration.zero) return;
    _controller
      ..duration = duration
      ..forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      // Trois allers-retours qui s'amortissent.
      builder: (context, child) {
        final t = _controller.value;
        final dx = sin(t * 3 * 2 * pi) * _amplitude * (1 - t);
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
    );
  }
}

/// Passage d'un contenu à l'autre : l'ancien s'efface, le nouveau monte en
/// apparaissant. Le contenu change quand la clé de [child] change.
class FadeSwitcher extends StatelessWidget {
  const FadeSwitcher({
    super.key,
    required this.child,
    this.offset = const Offset(0, 0.02),
    this.duration = Motion.base,
  });

  final Widget child;

  /// Décalage de départ du nouveau contenu, en part de sa taille.
  final Offset offset;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: Motion.of(context, duration),
      // L'ancien part deux fois plus vite : les deux ne se mêlent pas.
      reverseDuration: Motion.of(context, duration ~/ 2),
      switchInCurve: Motion.enter,
      switchOutCurve: Motion.exit,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween(begin: offset, end: Offset.zero).animate(animation),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

/// [child] qui apparaît en grossissant, et disparaît en rétrécissant, sa
/// place avec lui : les voisins se poussent en douceur.
class Appear extends StatelessWidget {
  const Appear({super.key, required this.visible, required this.child});

  final bool visible;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final duration = Motion.of(context, Motion.base);
    return AnimatedSize(
      duration: duration,
      curve: Motion.enter,
      child: AnimatedSwitcher(
        duration: duration,
        switchInCurve: Motion.emphasis,
        switchOutCurve: Motion.exit,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: ScaleTransition(scale: animation, child: child),
        ),
        child: visible
            ? KeyedSubtree(key: const ValueKey(true), child: child)
            : const SizedBox.shrink(key: ValueKey(false)),
      ),
    );
  }
}
