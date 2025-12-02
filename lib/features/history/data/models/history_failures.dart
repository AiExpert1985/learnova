/// Failure types for history operations
library;

abstract class HistoryFailure {
  final String message;
  const HistoryFailure(this.message);

  @override
  String toString() => message;
}

class StorageFailure extends HistoryFailure {
  const StorageFailure(super.message);
}

class NotFoundFailure extends HistoryFailure {
  const NotFoundFailure(super.message);
}

class SerializationFailure extends HistoryFailure {
  const SerializationFailure(super.message);
}
