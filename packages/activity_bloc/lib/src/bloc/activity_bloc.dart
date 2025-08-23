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
class ActivityBloc<I, O, F> extends Bloc<ActivityEvent, ActivityState<I, O, F>> {
  ActivityBloc({
    required this.activity,
    I? input,
    O? output,
    bool runImmediately = false,
    bool runSilently = false,
  }) : super(
    ActivityState<I, O, F>(
      input: input,
      output: output,
    ),
  ) {
    on<ActivityRun<I>>(_onRun);
    on<ActivityReset>(_onReset);

    if (runImmediately) {
      run(
        input: input,
        silently: runSilently,
      );
    }
  }

  final ActivityWithInput<I, O, F> activity;

  I? get input => state.input;
  O? get output => state.output;
  F? get failure => state.failure;

  bool get isInitial => state.isInitial;
  bool get isRunning => state.isRunning;
  bool get isCompleted => state.isCompleted;
  bool get isFailed => state.isFailed;

  void run({
    I? input,
    bool silently = false,
  }) {
    add(ActivityRun<I>(input, silently));
  }

  void reset() {
    add(const ActivityReset());
  }

  Future<void> runAndWait({
    I? input,
    bool silently = true,
    Duration minWaitTime = const Duration(milliseconds: 500),
  }) async {
    run(
      input: input,
      silently: silently,
    );

    await Future.wait([
      Future.delayed(minWaitTime),
      stream.first,
    ]);
  }

  T when<T>({
    T Function()? initial,
    T Function()? running,
    T Function(O output)? completed,
    T Function(F failure)? failed,
    T Function()? otherwise,
  }) {
    final value = switch (state.status) {
      ActivityStatus.initial => initial?.call(),
      ActivityStatus.running => running?.call(),
      // ignore: null_check_on_nullable_type_parameter
      ActivityStatus.completed => completed?.call(state.output!),
      // ignore: null_check_on_nullable_type_parameter
      ActivityStatus.failed => failed?.call(state.failure!),
    };

    assert(
      value != null || otherwise != null,
      'Either `${state.status.name}` or `otherwise` callback should be provided',
    );

    return value ?? otherwise!.call();
  }

  Future<void> _onReset(
    ActivityReset event,
    Emitter<ActivityState<I, O, F>> emit,
  ) async {
    emit(state._initial());
  }

  Future<void> _onRun(
    ActivityRun<I> event,
    Emitter<ActivityState<I, O, F>> emit,
  ) async {
    if ((state.output == null) || !state.isInitial) {
      if (!event.silently) {
        emit(state._running(event.input));
      }
      final result = await activity(event.input ?? state.input as I);
      result.fold(
        (F failure) => emit(state._failed(failure)),
        (O output) => emit(state._completed(output)),
      );
    } else {
      emit(state._completed());
    }
  }
}

/// Activity with a single input positional parameter
typedef ActivityWithInput<I, O, F> = Future<Either<F, O>> Function(I);

// Activity with no input parameters
typedef ActivityWithNoInput<O, F> = Future<Either<F, O>> Function();

/// Extension which provides a way to convert any [ActivityWithInput] into a Bloc.
extension ActivityWithInputToBloc<I, O, F> on ActivityWithInput<I, O, F> {
  ActivityBloc<I, O, F> asActivityBloc({
    I? input,
    O? output,
    bool runImmediately = false,
    bool runSilently = false,
  }) {
    return ActivityBloc<I, O, F>(
      activity: this,
      input: input,
      output: output,
      runImmediately: runImmediately,
      runSilently: runSilently,
    );
  }
}

/// Extension which provides a way to convert any [ActivityWithNoInput] into a Bloc.
extension ActivityWithNoInputToBloc<O, F> on ActivityWithNoInput<O, F> {
  ActivityBloc<void, O, F> asActivityBloc({
    O? output,
    bool runImmediately = false,
    bool runSilently = false,
  }) {
    return ActivityBloc<void, O, F>(
      activity: (_) => this(),
      output: output,
      runImmediately: runImmediately,
      runSilently: runSilently,
    );
  }
}