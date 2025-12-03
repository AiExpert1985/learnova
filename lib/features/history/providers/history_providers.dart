/// Riverpod providers for history feature
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/history_repository.dart';
import '../data/repositories/hive_history_repository.dart';
import '../services/history_service.dart';
import '../state/history_notifier.dart';
import '../state/history_state.dart';

/// Provider for history repository (abstracted)
final historyRepositoryProvider = Provider<HistoryRepository>((ref) {
  return HiveHistoryRepository();
  // Future: swap to different implementations
  // return SqliteHistoryRepository();
  // return CloudHistoryRepository();
});

/// Provider for history service (public API)
final historyServiceProvider = Provider<HistoryService>((ref) {
  final repository = ref.watch(historyRepositoryProvider);
  return HistoryService(repository);
});

/// StateNotifier provider for history feature
/// Manages conversation list and loading state
final historyNotifierProvider =
    StateNotifierProvider<HistoryNotifier, HistoryState>((ref) {
  final historyService = ref.watch(historyServiceProvider);
  return HistoryNotifier(historyService: historyService);
});
