part of 'activity_bloc.dart';

sealed class ActivityEvent {
  const ActivityEvent();
}

final class ActivityRun<I> extends ActivityEvent {
  const ActivityRun({
    this.input,
    this.scope,
    this.silently = false,
});

  final I? input;
  final Enum? scope;
  final bool silently;
}

final class ActivityReset extends ActivityEvent {
  const ActivityReset();
}