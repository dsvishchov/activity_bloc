part of 'activity_bloc.dart';

enum ActivityStatus {
  initial,
  running,
  completed,
  failed,
}

class ActivityState<I, O, F> extends Equatable {
  const ActivityState({
    this.status = ActivityStatus.initial,
    this.failure,
    this.input,
    this.output,
    this.scope,
    this.updatedAt,
  });

  final ActivityStatus status;
  final F? failure;
  final I? input;
  final O? output;
  final Enum? scope;
  final DateTime? updatedAt;

  bool get isInitial => status == .initial;
  bool get isRunning => status == .running;
  bool get isCompleted => status == .completed;
  bool get isFailed => status == .failed;

  T? when<T>({
    T Function()? initial,
    T Function()? running,
    T Function(O output)? completed,
    T Function(F failure)? failed,
  }) {
    return switch (status) {
      .initial => initial?.call(),
      .running => running?.call(),
      // ignore: null_check_on_nullable_type_parameter
      .completed => completed?.call(output!),
      // ignore: null_check_on_nullable_type_parameter
      .failed => failed?.call(failure!),
    };
  }

  // ignore: unused_element
  ActivityState<I, O, F> _initial() {
    return _copyWith(
      status: .initial,
      failure: null,
      input: null,
      output: null,
      updatedAt: DateTime.now(),
    );
  }

  ActivityState<I, O, F> _running([
    I? input,
    Enum? scope,
  ]) {
    return _copyWith(
      input: input ?? this.input,
      scope: scope ?? this.scope,
      status: .running,
      updatedAt: DateTime.now(),
    );
  }

  ActivityState<I, O, F> _completed([
    O? output,
    Enum? scope,
  ]) {
    return _copyWith(
      status: .completed,
      output: output ?? this.output,
      failure: null,
      scope: scope ?? this.scope,
      updatedAt: DateTime.now(),
    );
  }

  ActivityState<I, O, F> _failed([
    F? failure,
    Enum? scope,
  ]) {
    return _copyWith(
      status: .failed,
      output: null,
      failure: failure,
      scope: scope ?? this.scope,
      updatedAt: DateTime.now(),
    );
  }

  ActivityState<I, O, F> _copyWith({
    ActivityStatus? status,
    Object? failure = _Undefined,
    Object? input = _Undefined,
    Object? output = _Undefined,
    Object? scope = _Undefined,
    Object? updatedAt = _Undefined,
  }) {
    return ActivityState<I, O, F>(
      status: status ?? this.status,
      failure: failure is F? ? failure : this.failure,
      input: input is I? ? input : this.input,
      output: output is O? ? output : this.output,
      scope: scope is Enum? ? scope : this.scope,
      updatedAt: updatedAt is DateTime? ? updatedAt : this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    status,
    failure,
    input,
    output,
    scope,
    updatedAt,
  ];
}

class _Undefined {}
