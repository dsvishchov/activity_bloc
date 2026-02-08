[activity_bloc] is an addition to the awesome [bloc] state management library which allows
to easily convert any async function into a runnable bloc which emits states corresponding
to the state of the async function execution.

# Motivation

Let's assume we have a repository class with some method to get some data from a remote API,
and we want to use this method in a Flutter widget and manage its state according to the state
of method execution: show activity indicator while loading, show error widget if failed,
show data once completed.

One of possible options is to create a bloc for this widget and keep execution state in this
widget's state. That works, pretty well, but adds a lot of boilerplate code on top and instead of
focusing on business logic one has to write an additional code to manage exection states.
Things become much more complicated when ther are more than one async operation which might
be running at the some point of time and we want to react on their execution states separately.

One of common use cases might be, for example, a page with a searchable list of items with
lazy loading, pull to refresh functionality and ability to interact with one or more items.

Managing this complex state in a single bloc is a nightmare. And this is where wrapping individual
async operations into activity blocs becomes a life safer. Along with the code generation supported
by using [activity_bloc_builder] things become even easier, reducing any boilerplate code required.

# How to use

## Install

To use [activity_bloc], simply add it to your `pubspec.yaml` file:

```console
dart pub add activity_bloc
```

To use code generation, which is the preferrable and the most convenient way, you will need
to add development dependecy for [activity_bloc_builder] along with the common setup required
to use [build_runner]:

```console
dart pub add dev:activity_bloc_builder
dart pub add dev:build_runner
```

## Annotate

You need to annotate classes with `@activities` and class methods you want activity blocs to be
generated for with `@activity`, for example:

```dart
import 'package:activity_bloc/activity_bloc.dart';
import 'package:fpdart/fpdart.dart';

part 'users_repository.g.dart';

@activities
class UsersRepository {
  @activity
  Future<Either<Failure, User>> getUser({
    required int id,
  }) async {
    ...
  }
}
```

## Generate

Run the code generator:

```console
dart run build_runner build
```

This will generate the following classes for `getItems` method mentioned in the example above:
- `GetUserInput`: represents input paramteres of the method wrapped in a class
- `GetUserBloc`: bloc inherited from the base `ActivityBloc` which wraps method call into a bloc
- `GetUserState`: bloc state which describes operation's status, input, output and failure

Sometimes we prefer to use short names for class methods and assume that the class name itself
is descriptive enough, for example we might name `getUser` just `get`. In this case in order to
get descriptive activity blocs names one should support either `prefix` on the class-level
annotation or `prefix` and/or `name` on the method-level annotation.

In order to add an additional prefix to all generated blocs you can use `@Activities`
instead of `@activities` and supply `prefix` like this:

```dart
@Activities(prefix: 'User')
class UsersRepository {...
  @activity
  Future<Either<Failure, User>> get(... // UserGetBloc
```

If you want to use another prefix or a completely different name for a single method
you can use `@Activity` instead of `@activity` and supply `name` and/or `prefix` like this:

```dart
@Activity(name: 'GetUser')
Future<Either<Failure, User>> get(... // GetUserBloc
```

Note that the method-level `prefix` and/or `name` overrides any class-level `prefix`.

## Use

Provide bloc through `BlocProvider` as usually:
```dart
BlocProvider(
  create: (_) => GetUserBloc(
    source: /* instace of UsersRepository */,
    input: GetUserInput(id: /* user id */)
    runImmediatelly: true,
  ),
),
```
Any `ActivityBloc` has the following constructor parameters:
- `source`: this is an instance of class the activity method should be called from
(e.g. repository through dependency injection)
- `input`: this is an instance of activity method parameters (if any)
- `output`: this can be used during construction in order to provide cached output of activity
- `runImmediatelly`: forces activity to be run immediatelly, otherwise it can be run or
re-run later at any point of time with the same or other input
- `runSilently`: allows to skip emitting a `running` state

Wherever you have a `BuildContext` you can watch for a bloc state changes as usually:

```dart
final getUser = context.watch<GetUserBloc>();
```

And utilize the current state of activity by either using a `when` helper, for example:

```dart
getUser.when<Widget>(
  initial: () => /* widget for the initial state when activity has never been run yet */,
  running: () => /* widget to be shown when activity is running */ ,
  completed: (output) => /* widget to show when activity completed */,
  failed: (failure) => /* widget to show when failure has occured */,
),
```

Or by directly accessing activity state using the following methods of `ActivityBloc`:
- `isInitial`, `isRunning`, `isCompleted`, `isFailed`: to get the current status of activity
- `input`, `output`, `failure`: to get the corresponding data

Also activity can be run or re-run at any point of time, e.g.:

```dart
getUser.run(input: GetInput(...))
```

And there is also a convenient method `runAnWait` to run and wait for activity to be completed,
which might be helpful in cases you need to provide a `Future` and `await` it.

## Configuration

Additional code generation options can be provided within a build.yaml file.

```yaml
targets:
  $default:
    builders:
      activity_bloc_builder:
        options:
          global_getters: false
```

Currently supported options:
- `global_getters`: global getters through singleton instance of [get_it] will be generated,
which might be quite useful if you use [get_it] for blocs lifecycle management

## Dependencies/limitations

- As of now [activity_bloc] supports only async functions with return type of `Either` from
the [fpdart] package, which allows seamless error handling.
- Code generation supports only class level methods with named parameters.


[activity_bloc]: https://pub.dartlang.org/packages/activity_bloc
[activity_bloc_builder]: https://pub.dartlang.org/packages/activity_bloc_builder
[bloc]: https://pub.dartlang.org/packages/bloc
[build_runner]: https://pub.dev/packages/build_runner
[fpdart]: https://pub.dev/packages/fpdart
[get_it]: https://pub.dev/packages/get_it