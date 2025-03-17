import 'package:meta/meta_meta.dart';

/// An annotation used to specify that class has methods annotated with @activity.
@Target({TargetKind.classType})
class Activities {
  const Activities();
}

const activities = Activities();
