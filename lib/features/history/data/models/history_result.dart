/// Result wrapper for history operations
library;

import 'history_failures.dart';

class HistoryResult<T> {
  final T? data;
  final HistoryFailure? failure;

  const HistoryResult._({this.data, this.failure});

  factory HistoryResult.success(T data) {
    return HistoryResult._(data: data);
  }

  factory HistoryResult.failure(HistoryFailure failure) {
    return HistoryResult._(failure: failure);
  }

  bool get isSuccess => data != null;
  bool get isFailure => failure != null;

  /// Execute callback based on success or failure
  R when<R>({
    required R Function(T data) success,
    required R Function(HistoryFailure failure) failure,
  }) {
    if (isSuccess) {
      return success(data as T);
    } else {
      return failure(this.failure!);
    }
  }
}
