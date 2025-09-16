import 'package:activity_bloc/activity_bloc.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'activity_bloc_generator.dart';

class ActivitiesGenerator extends GeneratorForAnnotation<Activities> {
  @override
  String generateForAnnotatedElement(
    Element2 element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    if (element is! ClassElement2) {
      _throwInvalidTargetError(element);
    }
    final definingClass = element as ClassElement2;
    final definingClassAnnotation = _getActivitiesAnnotation(definingClass);

    final buffer = StringBuffer();

    final methods = definingClass.firstFragment.methods2;
    for (final method in methods) {
      final methodAnnotation = _getActivityAnnotation(method.element);

      if (methodAnnotation != null) {
        final blocGenerator = ActivityBlocGenerator(
          definingClass: definingClass,
          definingClassAnnotation: definingClassAnnotation,
          method: method.element,
          methodAnnotation: methodAnnotation,
        );

        buffer.write(blocGenerator.generate());
      }
    }

    return buffer.toString();
  }

  Activities _getActivitiesAnnotation(ClassElement2 element) {
    final annotation = const TypeChecker
      .typeNamed(Activities)
      .firstAnnotationOf(element);

    final reader = ConstantReader(annotation);
    final prefix = reader.peek('prefix');

    return Activities(
      prefix: prefix?.stringValue,
    );
  }

  Activity? _getActivityAnnotation(MethodElement2 element) {
    final annotation = const TypeChecker
      .typeNamed(Activity)
      .firstAnnotationOf(element);

    if (annotation == null) {
      return null;
    }

    final reader = ConstantReader(annotation);
    final name = reader.peek('name');
    final prefix = reader.peek('prefix');

    return Activity(
      name: name?.stringValue,
      prefix: prefix?.stringValue,
    );
  }

  void _throwInvalidTargetError(Element2 element) {
    throw InvalidGenerationSourceError(
      '@activities can only be applied to classes.',
      element: element,
    );
  }
}