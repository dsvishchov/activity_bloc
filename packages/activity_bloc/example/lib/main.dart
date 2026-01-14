import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import 'users_repository.dart';

final locator = GetIt.instance;

enum GetUserScope {
  direct,
}

void main() {
  locator.registerSingleton(UsersRepository());

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: BlocProvider(
        create: (_) => GetUserBloc(
          source: locator.get<UsersRepository>(),
        ),
        child: Builder(
          builder: (context) => Scaffold(
            body: page(context),
          ),
        ),
      ),
    );
  }

  Widget? page(BuildContext context) {
    final getUser = context.watch<GetUserBloc>();

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 8.0,
        children: [
          FilledButton(
            onPressed: !getUser.isRunning
              ? () => getUser.run(
                  input: GetUserInput(id: 1),
                  scope: GetUserScope.direct,
                )
              : null,
            child: Text('Get user'),
          ),
          getUser.when<Widget>(
            initial: () => Text('Click button above to get user data'),
            running: () => CircularProgressIndicator(),
            completed: (user) => Text('User: ${user.firstName} ${user.lastName} (scope: ${getUser.scope})'),
            failed: (failure) => Text('Failure: ${failure.message}'),
          )!,
        ],
      ),
    );
  }
}
