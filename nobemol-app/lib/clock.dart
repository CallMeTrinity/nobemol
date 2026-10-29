import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Horloge de l'appli (chrono, dates de la progression), remplaçable en
/// test.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);
