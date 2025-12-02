import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:learnova/features/history/data/models/conversation_history.dart';
import 'package:learnova/features/history/data/models/qa_entry.dart';
import 'package:learnova/features/history/data/repositories/hive_history_repository.dart';

void main() {
  late HiveHistoryRepository repository;

  setUpAll(() async {
    // Initialize Hive for testing
    await Hive.initFlutter();
  });

  setUp(() async {
    repository = HiveHistoryRepository();
    await repository.initialize();
  });

  tearDown(() async {
    await repository.clear();
    await repository.close();
  });

  group('HiveHistoryRepository', () {
    test('initialize should open storage successfully', () async {
      final newRepo = HiveHistoryRepository();
      final result = await newRepo.initialize();

      expect(result.isSuccess, true);
      await newRepo.close();
    });

    test('save should persist conversation to storage', () async {
      final conversation = ConversationHistory.create(
        videoId: 'test123',
        videoTitle: 'Test Video',
        initialQAHistory: [
          QAEntry(
            question: 'What is this?',
            answer: 'This is a test',
            timestamp: DateTime.now(),
            tokensUsed: 10,
          ),
        ],
      );

      final saveResult = await repository.save(conversation);
      expect(saveResult.isSuccess, true);

      final getResult = await repository.getById(conversation.id);
      expect(getResult.isSuccess, true);
      expect(getResult.data, isNotNull);
      expect(getResult.data!.videoId, 'test123');
      expect(getResult.data!.videoTitle, 'Test Video');
      expect(getResult.data!.qaHistory.length, 1);
    });

    test('getAll should return conversations sorted by lastUpdated', () async {
      // Create conversations with different timestamps
      await Future.delayed(Duration(milliseconds: 10));
      final conv1 = ConversationHistory.create(
        videoId: 'video1',
        videoTitle: 'Video 1',
      );
      await repository.save(conv1);

      await Future.delayed(Duration(milliseconds: 10));
      final conv2 = ConversationHistory.create(
        videoId: 'video2',
        videoTitle: 'Video 2',
      );
      await repository.save(conv2);

      final result = await repository.getAll();
      expect(result.isSuccess, true);
      expect(result.data!.length, 2);
      // Most recent should be first
      expect(result.data!.first.videoId, 'video2');
      expect(result.data!.last.videoId, 'video1');
    });

    test('getByVideoId should return most recent conversation for video', () async {
      final conv1 = ConversationHistory.create(
        videoId: 'video123',
        videoTitle: 'Video Title',
      );
      await repository.save(conv1);

      await Future.delayed(Duration(milliseconds: 10));
      final conv2 = ConversationHistory.create(
        videoId: 'video123',
        videoTitle: 'Video Title',
      );
      await repository.save(conv2);

      final result = await repository.getByVideoId('video123');
      expect(result.isSuccess, true);
      expect(result.data, isNotNull);
      expect(result.data!.id, conv2.id);
    });

    test('delete should remove conversation from storage', () async {
      final conversation = ConversationHistory.create(
        videoId: 'test123',
        videoTitle: 'Test Video',
      );
      await repository.save(conversation);

      final deleteResult = await repository.delete(conversation.id);
      expect(deleteResult.isSuccess, true);

      final getResult = await repository.getById(conversation.id);
      expect(getResult.isSuccess, true);
      expect(getResult.data, isNull);
    });

    test('clear should remove all conversations', () async {
      await repository.save(
        ConversationHistory.create(
          videoId: 'video1',
          videoTitle: 'Video 1',
        ),
      );
      await repository.save(
        ConversationHistory.create(
          videoId: 'video2',
          videoTitle: 'Video 2',
        ),
      );

      final clearResult = await repository.clear();
      expect(clearResult.isSuccess, true);

      final getAllResult = await repository.getAll();
      expect(getAllResult.isSuccess, true);
      expect(getAllResult.data!.length, 0);
    });

    test('getById should return null for non-existent conversation', () async {
      final result = await repository.getById('non_existent_id');
      expect(result.isSuccess, true);
      expect(result.data, isNull);
    });

    test('operations should fail when storage not initialized', () async {
      final uninitializedRepo = HiveHistoryRepository();

      final result = await uninitializedRepo.getAll();
      expect(result.isFailure, true);
    });
  });
}
