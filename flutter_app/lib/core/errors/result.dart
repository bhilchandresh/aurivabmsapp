import 'failures.dart';

class Result<T> {
  final T? _data;
  final Failure? _failure;
  final bool _isLoading;
  final bool _explicitSuccess;

  Result._({
    T? data,
    Failure? failure,
    bool isLoading = false,
    bool explicitSuccess = false,
  })  : _data = data,
        _failure = failure,
        _isLoading = isLoading,
        _explicitSuccess = explicitSuccess;

  factory Result.success(T data) =>
      Result._(data: data, explicitSuccess: true);
  factory Result.failure(Failure failure) => Result._(failure: failure);
  factory Result.loading() => Result._(isLoading: true);

  /// True if this result was created via [Result.success], regardless of
  /// whether [T] is nullable or void (i.e. data may be null).
  bool get isSuccess =>
      _explicitSuccess && _failure == null && !_isLoading;
  bool get isFailure => _failure != null && !_isLoading;
  bool get isLoading => _isLoading;

  T get data {
    if (!isSuccess) {
      throw StateError('Result is not a success state.');
    }
    return _data!;
  }

  Failure get failure {
    if (!isFailure) {
      throw StateError('Result is not a failure state.');
    }
    return _failure!;
  }

  R when<R>({
    required R Function(T data) onSuccess,
    required R Function(Failure failure) onFailure,
    required R Function() onLoading,
  }) {
    if (isLoading) return onLoading();
    if (isFailure) return onFailure(failure);
    return onSuccess(data);
  }
}
