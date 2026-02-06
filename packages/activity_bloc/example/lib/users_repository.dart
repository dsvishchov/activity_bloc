import 'package:activity_bloc/activity_bloc.dart';
import 'package:fpdart/fpdart.dart';

import 'failure.dart';
import 'user.dart';

part 'users_repository.g.dart';

@activities
class UsersRepository {
  static const validUserId = 1;

  @activity
  Future<Either< Failure, User>> getUser({
    required int id,
  }) async {
    return Future.delayed(
      const Duration(seconds: 2),
      () {
        // throw Exception('Uncomment to test exception handling');
        return (id == validUserId)
          ? right(
              User(
                id: id,
                firstName: 'John',
                lastName: 'Doe',
              ),
            )
          : left(
              Failure(message: 'User with id $id does not exist'),
            );
      }
    );
  }
}