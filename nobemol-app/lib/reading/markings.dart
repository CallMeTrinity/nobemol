import 'package:notation/core.dart';

/// Sens d'un signe ou d'un terme : les réponses des exercices de signes,
/// dans l'ordre d'affichage.
///
/// Un sens, pas une écriture : le soufflet et « cresc. » donnent
/// [crescendo], « rit. » et « rall. » donnent [ritardando].
enum Marking {
  pianississimo,
  pianissimo,
  piano,
  mezzoPiano,
  mezzoForte,
  forte,
  fortissimo,
  fortississimo,
  crescendo,
  diminuendo,
  staccato,
  tenuto,
  accent,
  fermata,
  ritardando,
  accelerando,
  aTempo,
  dolce,
  legato,
  espressivo,
  cantabile;

  /// Identifiant dans les leçons : `mezzo-piano`, `a-tempo`.
  String get id => name.replaceAllMapped(
    RegExp('[A-Z]'),
    (match) => '-${match[0]!.toLowerCase()}',
  );

  /// Sens d'identifiant [id], `null` s'il n'y en a pas.
  static Marking? byId(String id) =>
      values.where((marking) => marking.id == id).firstOrNull;
}

/// Termes reconnus dans une annotation, par texte écrit.
const terms = <String, Marking>{
  'cresc.': Marking.crescendo,
  'crescendo': Marking.crescendo,
  'dim.': Marking.diminuendo,
  'diminuendo': Marking.diminuendo,
  'decresc.': Marking.diminuendo,
  'decrescendo': Marking.diminuendo,
  'rit.': Marking.ritardando,
  'ritard.': Marking.ritardando,
  'ritardando': Marking.ritardando,
  'rall.': Marking.ritardando,
  'rallentando': Marking.ritardando,
  'accel.': Marking.accelerando,
  'accelerando': Marking.accelerando,
  'a tempo': Marking.aTempo,
  'dolce': Marking.dolce,
  'legato': Marking.legato,
  'espress.': Marking.espressivo,
  'espressivo': Marking.espressivo,
  'cantabile': Marking.cantabile,
};

/// Signes d'un événement qu'un exercice peut cibler : tout sauf les fins de
/// soufflet, qui appartiennent au soufflet de leur première note.
Iterable<Decoration> signsOf(Event event) =>
    event.decorations.where((decoration) => decoration is! HairpinEnd);

/// Sens de [decoration], `null` pour une fin de soufflet ou un texte qui
/// n'est pas un terme connu.
Marking? markingOf(Decoration decoration) => switch (decoration) {
  Dynamic.ppp => Marking.pianississimo,
  Dynamic.pp => Marking.pianissimo,
  Dynamic.p => Marking.piano,
  Dynamic.mp => Marking.mezzoPiano,
  Dynamic.mf => Marking.mezzoForte,
  Dynamic.f => Marking.forte,
  Dynamic.ff => Marking.fortissimo,
  Dynamic.fff => Marking.fortississimo,
  HairpinStart(hairpin: Hairpin.crescendo) => Marking.crescendo,
  HairpinStart(hairpin: Hairpin.diminuendo) => Marking.diminuendo,
  HairpinEnd() => null,
  Articulation.staccato => Marking.staccato,
  Articulation.tenuto => Marking.tenuto,
  Articulation.accent => Marking.accent,
  Articulation.fermata => Marking.fermata,
  Annotation(:final text) => terms[text],
};
