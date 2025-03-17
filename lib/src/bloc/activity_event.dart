part of 'activity_bloc.dart';

sealed class ActivityEvent {
  const ActivityEvent();
}

final class ActivityRun<I> extends ActivityEvent {
  const ActivityRun([
    this.input,
    this.silently = false,
  ]);

  final I? input;
  final bool silently;
}
