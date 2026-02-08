import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'src/activities_generator.dart';

Builder activityBlocs(BuilderOptions options) {
  return SharedPartBuilder(
    [ActivitiesGenerator(options)],
    'activity_bloc_builder',
  );
}