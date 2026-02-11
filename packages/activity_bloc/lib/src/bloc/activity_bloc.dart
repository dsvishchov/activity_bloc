import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

part 'activity_event.dart';
part 'activity_state.dart';

/// Provides a way to wrap any [Activity] represented by an async function
/// returning either output or failure for a given input into a Bloc.
///
/// Activity wrapped into Bloc can be run immediately by setting
/// `runImmediately` to true in constructor. Activity can  also be run
/// at any point of time with the `input` provided within constructor
/// or a new one by calling [run] method directly.
///
/// Bloc will emit new [ActivityState] on each activity status change.
///
/// Optionally `output` can be provided directly in the constructor, and
/// it will be returned right away as a result of first run. This might
/// be useful for implementing cache functionality, so first run cached
/// output is returned by on subsequent call the actual activity will be
/// taken and new output produced.
///
/// If activity is being run with `runSilently` set to true, then no
/// intermediate running state will be emitted. This might be useful to
/// avoid widgets tree re-build when activity is running.
///
/// Use [runAndWait] to run activity and wait for its completion with either
/// success or failure. Additionally `minWaitTime`  might be used to
/// specify minimum amount of time to wait.
///
/// Use [runEventTransformer] to add a transformer for the run event. If
/// provided, the run event will be transformed by this transformer before
/// being added to the bloc. Equivalent to:
/// `Bloc.on<ActivityRun<I>>(_onRun, transformer: runEventTransformer);`
class ActivityBloc<I, O, F> extends Bloc<ActivityEvent, ActivityState<I, O, F>> {
  ActivityBloc({
    required this.activity,
    I? input,
    O? output,
    Enum? scope,
    bool runImmediately = false,
    bool runSilently = false,
    EventTransformer<ActivityRun<I>>? runEventTransformer,
  }) : super(
    ActivityState<I, O, F>(
      input: input,
      output: output,
      scope: scope,
    ),
  ) {
    on<ActivityRun<I>>(
      _onRun,
      transformer: runEventTransformer,
    );
    on<ActivityReset>(_onReset);

    if (runImmediately) {
      run(
        input: input,
        silently: runSilently,
      );
    }
  }

  /// Global stream of activity blocs status changes.
  ///
  /// This might be useful for global failures handle, for example.
  static Stream<ActivityBloc> get statusChanges  => _statusChanges.stream;
  static final _statusChanges = StreamController<ActivityBloc>.broadcast();

  /// Handler of exceptions thrown during activity execuction.
  ///
  /// If provided and returns an object of type F then it's used as a failure of
  /// of the activity bloc, otherwise exception is rethrown.
  static ExceptionHandler? onException;

  /// Activity to be executed
  final ActivityWithInput<I, O, F> activity;

  I? get input => state.input;
  O? get output => state.output;
  F? get failure => state.failure;

  bool get isInitial => state.isInitial;
  bool get isRunning => state.isRunning;
  bool get isCompleted => state.isCompleted;
  bool get isFailed => state.isFailed;

  Object? get scope => state.scope;

  void run({
    I? input,
    Enum? scope,
    bool silently = false,
  }) {
    add(
      ActivityRun<I>(
        input: input,
        scope: scope,
        silently: silently,
      ),
    );
  }

  void reset() {
    add(const ActivityReset());
  }

  Future<void> runAndWait({
    I? input,
    Enum? scope,
    bool silently = true,
    Duration minWaitTime = const Duration(milliseconds: 500),
  }) async {
    run(
      input: input,
      scope: scope,
      silently: silently,
    );

    await Future.wait([
      Future.delayed(minWaitTime),
      stream.first,
    ]);
  }

  T? when<T>({
    T Function()? initial,
    T Function()? running,
    T Function(O output)? completed,
    T Function(F failure)? failed,
  }) {
    return state.when(
      initial: initial,
      running: running,
      completed: completed,
      failed: failed,
    );
  }

  Future<void> _onReset(
    ActivityReset event,
    Emitter<ActivityState<I, O, F>> emit,
  ) async {
    emit(state._initial());
    _statusChanges.add(this);
  }

  Future<void> _onRun(
    ActivityRun<I> event,
    Emitter<ActivityState<I, O, F>> emit,
  ) async {
    void onRunning() {
      emit(
        state._running(
          event.input,
          event.scope,
        ),
      );
      _statusChanges.add(this);
    }

    void onFailed(F failure) {
      emit(
        state._failed(
          failure,
          event.scope,
        ),
      );
      _statusChanges.add(this);
    }

    void onCompleted([O? output]) {
      emit(
        state._completed(
          output,
          event.scope,
        ),
      );
      _statusChanges.add(this);
    }

    if ((state.output == null) || !state.isInitial) {
      if (!event.silently) {
        onRunning();
      }

      try {
        final result = await activity(event.input ?? state.input as I);
        result.fold(
          (F failure) => onFailed(failure),
          (O output) => onCompleted(output),
        );
      } catch (error, stackTrace) {
        final failure = onException?.call(error, stackTrace);
        if (failure is F) {
          onFailed(failure);
        } else {
          rethrow;
        }
      }
    } else {
      onCompleted();
    }
  }
}

/// Activity with a single input positional parameter
typedef ActivityWithInput<I, O, F> = Future<Either<F, O>> Function(I);

/// Activity with no input parameters
typedef ActivityWithNoInput<O, F> = Future<Either<F, O>> Function();

/// Exception handler
typedef ExceptionHandler = dynamic Function(
  Object? error,
  StackTrace stackTrace,
);

/// Extension which provides a way to convert any [ActivityWithInput] into a Bloc.
extension ActivityWithInputToBloc<I, O, F> on ActivityWithInput<I, O, F> {
  ActivityBloc<I, O, F> asActivityBloc({
    I? input,
    O? output,
    Enum? scope,
    bool runImmediately = false,
    bool runSilently = false,
  }) {
    return ActivityBloc<I, O, F>(
      activity: this,
      input: input,
      output: output,
      scope: scope,
      runImmediately: runImmediately,
      runSilently: runSilently,
    );
  }
}

/// Extension which provides a way to convert any [ActivityWithNoInput] into a Bloc.
extension ActivityWithNoInputToBloc<O, F> on ActivityWithNoInput<O, F> {
  ActivityBloc<void, O, F> asActivityBloc({
    O? output,
    Enum? scope,
    bool runImmediately = false,
    bool runSilently = false,
  }) {
    return ActivityBloc<void, O, F>(
      activity: (_) => this(),
      output: output,
      scope: scope,
      runImmediately: runImmediately,
      runSilently: runSilently,
    );
  }
}