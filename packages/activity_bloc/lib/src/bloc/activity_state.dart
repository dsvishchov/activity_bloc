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
  final Object? scope;
  final DateTime? updatedAt;

  bool get isInitial
    => status == ActivityStatus.initial;
  bool get isRunning
    => status == ActivityStatus.running;
  bool get isCompleted
    => status == ActivityStatus.completed;
  bool get isFailed
    => status == ActivityStatus.failed;

  // ignore: unused_element
  ActivityState<I, O, F> _initial() {
    return _copyWith(
      status: ActivityStatus.initial,
      failure: null,
      input: null,
      output: null,
      updatedAt: DateTime.now(),
    );
  }

  ActivityState<I, O, F> _running([
    I? input,
    Object? scope,
  ]) {
    return _copyWith(
      input: input ?? this.input,
      scope: scope ?? this.scope,
      status: ActivityStatus.running,
      updatedAt: DateTime.now(),
    );
  }

  ActivityState<I, O, F> _completed([
    O? output,
    Object? scope,
  ]) {
    return _copyWith(
      status: ActivityStatus.completed,
      output: output ?? this.output,
      failure: null,
      scope: scope ?? this.scope,
      updatedAt: DateTime.now(),
    );
  }

  ActivityState<I, O, F> _failed([
    F? failure,
    Object? scope,
  ]) {
    return _copyWith(
      status: ActivityStatus.failed,
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
      scope: scope == _Undefined ? this.scope : scope,
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
