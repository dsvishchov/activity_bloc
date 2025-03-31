import 'package:meta/meta_meta.dart';

/// An annotation used to specify that `ActivityBloc` should be generated for this method.
@Target({TargetKind.method})
class Activity {
  const Activity({
    this.name,
    this.prefix,
  });

  final String? name;
  final String? prefix;
}

const activity = Activity();
