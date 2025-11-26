/// Mock data for testing and development
library;

class MockData {
  /// Sample transcript from a business/learning video (2-3 minutes)
  /// This is used for Step 1 testing before YouTube integration
  static const String sampleTranscript = '''
Welcome to this lesson on effective learning strategies. Today we'll explore how our brains actually learn and retain information.

The first key principle is spaced repetition. Research shows that reviewing material at increasing intervals dramatically improves long-term retention. Instead of cramming everything in one session, spacing out your learning over days or weeks creates stronger neural pathways.

The second principle is active recall. Simply re-reading notes is passive and inefficient. Instead, test yourself repeatedly. Close your book and try to recall the information. This struggle to remember actually strengthens memory formation.

The third principle is interleaving. Rather than studying one topic until mastery, mix different subjects or problem types in a single session. This builds connections between concepts and improves your ability to apply knowledge flexibly.

The fourth principle is elaboration. Don't just memorize facts in isolation. Connect new information to what you already know. Ask yourself "why" and "how" questions. The more connections you make, the stronger your understanding becomes.

Finally, the fifth principle is concrete examples. Abstract concepts are hard to remember. Always ground your learning in specific, real-world examples. If you're learning about marketing, think of actual ad campaigns. If you're studying psychology, observe these principles in your daily interactions.

The most important insight is this: learning is not about hours spent. It's about using evidence-based strategies that align with how your brain actually works. Ten minutes of active recall beats an hour of passive re-reading.
''';

  /// Video metadata for context
  static const String videoTitle = "5 Evidence-Based Learning Strategies";
  static const Duration videoDuration = Duration(minutes: 2, seconds: 45);
}
