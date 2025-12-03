import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learnova/features/history/data/models/conversation_history.dart';
import 'package:learnova/features/history/data/models/history_failures.dart';
import 'package:learnova/features/history/data/models/history_result.dart';
import 'package:learnova/features/history/data/models/qa_entry.dart';
import 'package:learnova/features/history/providers/history_providers.dart';
import 'package:learnova/features/history/services/history_service.dart';
import 'package:learnova/features/history/ui/widgets/history_bottom_sheet.dart';

/// Mock history service for testing
class MockHistoryService implements HistoryService {
  final List<ConversationHistory> _mockConversations = [];
  bool _shouldFail = false;

  void setShouldFail(bool value) => _shouldFail = value;

  void addMockConversation(ConversationHistory conversation) {
    _mockConversations.add(conversation);
  }

  @override
  Future<HistoryResult<void>> initialize() async {
    return HistoryResult.success(null);
  }

  @override
  Future<HistoryResult<List<ConversationHistory>>>
  loadAllConversations() async {
    if (_shouldFail) {
      return HistoryResult.failure(StorageFailure('Mock load failed'));
    }
    return HistoryResult.success(List.from(_mockConversations));
  }

  @override
  Future<HistoryResult<void>> deleteConversation(String id) async {
    if (_shouldFail) {
      return HistoryResult.failure(StorageFailure('Mock delete failed'));
    }
    _mockConversations.removeWhere((conv) => conv.id == id);
    return HistoryResult.success(null);
  }

  @override
  Future<HistoryResult<void>> clearAllHistory() async {
    if (_shouldFail) {
      return HistoryResult.failure(StorageFailure('Mock clear failed'));
    }
    _mockConversations.clear();
    return HistoryResult.success(null);
  }

  @override
  Future<HistoryResult<ConversationHistory>> saveConversation({
    required String videoId,
    required String videoTitle,
    required List<QAEntry> qaHistory,
  }) async {
    if (_shouldFail) {
      return HistoryResult.failure(StorageFailure('Mock save failed'));
    }
    final conversation = ConversationHistory.create(
      videoId: videoId,
      videoTitle: videoTitle,
      initialQAHistory: qaHistory,
    );
    _mockConversations.add(conversation);
    return HistoryResult.success(conversation);
  }

  @override
  Future<HistoryResult<ConversationHistory?>> loadConversationById(
    String id,
  ) async {
    if (_shouldFail) {
      return HistoryResult.failure(StorageFailure('Mock load failed'));
    }
    final conversation = _mockConversations
        .where((c) => c.id == id)
        .firstOrNull;
    return HistoryResult.success(conversation);
  }

  @override
  Future<HistoryResult<ConversationHistory?>> loadConversationByVideoId(
    String videoId,
  ) async {
    if (_shouldFail) {
      return HistoryResult.failure(StorageFailure('Mock load failed'));
    }
    final conversation = _mockConversations
        .where((c) => c.videoId == videoId)
        .firstOrNull;
    return HistoryResult.success(conversation);
  }

  @override
  Future<HistoryResult<void>> close() async {
    return HistoryResult.success(null);
  }
}

void main() {
  late MockHistoryService mockService;

  setUp(() {
    mockService = MockHistoryService();
  });

  Widget createTestWidget() {
    return ProviderScope(
      overrides: [historyServiceProvider.overrideWithValue(mockService)],
      child: InitHistoryWidget(
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      builder: (context) => const HistoryBottomSheet(),
                    );
                  },
                  child: const Text('Show History'),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  group('HistoryBottomSheet', () {
    testWidgets('should show clear all button when conversations exist', (
      tester,
    ) async {
      // Add mock conversations
      mockService.addMockConversation(
        ConversationHistory.create(videoId: 'video1', videoTitle: 'Video 1'),
      );

      await tester.pumpWidget(createTestWidget());

      // Open bottom sheet
      await tester.tap(find.text('Show History'));
      await tester.pumpAndSettle();

      // Verify clear all button is visible
      expect(find.byIcon(Icons.delete_sweep), findsOneWidget);
      expect(find.byTooltip('Clear All History'), findsOneWidget);
    });

    testWidgets('should not show clear all button when no conversations', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget());

      // Open bottom sheet
      await tester.tap(find.text('Show History'));
      await tester.pumpAndSettle();

      // Verify clear all button is not visible
      expect(find.byIcon(Icons.delete_sweep), findsNothing);
    });

    testWidgets('should show confirmation dialog when clear all is tapped', (
      tester,
    ) async {
      // Add mock conversations
      mockService.addMockConversation(
        ConversationHistory.create(videoId: 'video1', videoTitle: 'Video 1'),
      );

      await tester.pumpWidget(createTestWidget());

      // Open bottom sheet
      await tester.tap(find.text('Show History'));
      await tester.pumpAndSettle();

      // Tap clear all button
      await tester.tap(find.byIcon(Icons.delete_sweep));
      await tester.pumpAndSettle();

      // Verify confirmation dialog appears
      expect(find.text('Clear All History'), findsOneWidget);
      expect(
        find.text(
          'Are you sure you want to delete all conversation history? This action cannot be undone.',
        ),
        findsOneWidget,
      );
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Clear All'), findsOneWidget);
    });

    testWidgets('should cancel clear all when cancel is tapped', (
      tester,
    ) async {
      // Add mock conversations
      mockService.addMockConversation(
        ConversationHistory.create(videoId: 'video1', videoTitle: 'Video 1'),
      );

      await tester.pumpWidget(createTestWidget());

      // Open bottom sheet
      await tester.tap(find.text('Show History'));
      await tester.pumpAndSettle();

      // Tap clear all button
      await tester.tap(find.byIcon(Icons.delete_sweep));
      await tester.pumpAndSettle();

      // Tap cancel
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Verify conversations still exist
      expect(mockService._mockConversations.length, 1);
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('should clear all conversations when confirmed', (
      tester,
    ) async {
      // Add mock conversations
      mockService.addMockConversation(
        ConversationHistory.create(videoId: 'video1', videoTitle: 'Video 1'),
      );
      mockService.addMockConversation(
        ConversationHistory.create(videoId: 'video2', videoTitle: 'Video 2'),
      );

      await tester.pumpWidget(createTestWidget());

      // Open bottom sheet
      await tester.tap(find.text('Show History'));
      await tester.pumpAndSettle();

      // Tap clear all button
      await tester.tap(find.byIcon(Icons.delete_sweep));
      await tester.pumpAndSettle();

      // Tap clear all in dialog
      await tester.tap(find.text('Clear All'));
      await tester.pumpAndSettle();

      // Verify all conversations are cleared
      expect(mockService._mockConversations.length, 0);
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('should show empty state after clearing all', (tester) async {
      // Add mock conversations
      mockService.addMockConversation(
        ConversationHistory.create(videoId: 'video1', videoTitle: 'Video 1'),
      );

      await tester.pumpWidget(createTestWidget());

      // Open bottom sheet
      await tester.tap(find.text('Show History'));
      await tester.pumpAndSettle();

      // Tap clear all button
      await tester.tap(find.byIcon(Icons.delete_sweep));
      await tester.pumpAndSettle();

      // Confirm clear all
      await tester.tap(find.text('Clear All'));
      await tester.pumpAndSettle();

      // Verify empty state is shown
      expect(find.text('No history yet'), findsOneWidget);
      expect(find.text('Your conversations will appear here'), findsOneWidget);
      expect(
        find.byIcon(Icons.delete_sweep),
        findsNothing,
      ); // Clear button should be hidden
    });
  });
}

class InitHistoryWidget extends ConsumerStatefulWidget {
  final Widget child;
  const InitHistoryWidget({required this.child, super.key});

  @override
  ConsumerState<InitHistoryWidget> createState() => _InitHistoryWidgetState();
}

class _InitHistoryWidgetState extends ConsumerState<InitHistoryWidget> {
  @override
  void initState() {
    super.initState();
    // Trigger load history when widget is mounted
    Future.microtask(
      () => ref.read(historyNotifierProvider.notifier).loadHistory(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
