import 'package:activity_bloc/activity_bloc.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'activity_bloc_generator.dart';

class ActivitiesGenerator extends GeneratorForAnnotation<Activities> {
  @override
  String generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    if (element is! ClassElement) {
      _throwInvalidTargetError(element);
    }
    final definingClass = element as ClassElement;
    final definingClassAnnotation = _getActivitiesAnnotation(definingClass);

    final buffer = StringBuffer();

    final methods = definingClass.methods;
    for (final method in methods) {
      final methodAnnotation = _getActivityAnnotation(method);

      if (methodAnnotation != null) {
        final blocGenerator = ActivityBlocGenerator(
          definingClass: definingClass,
          definingClassAnnotation: definingClassAnnotation,
          method: method,
          methodAnnotation: methodAnnotation,
        );

        buffer.write(blocGenerator.generate());
      }
    }

    return buffer.toString();
  }

  Activities _getActivitiesAnnotation(ClassElement element) {
    final annotation = const TypeChecker
      .fromRuntime(Activities)
      .firstAnnotationOf(element);

    final reader = ConstantReader(annotation);
    final prefix = reader.peek('prefix');

    return Activities(
      prefix: prefix?.stringValue,
    );
  }

  Activity? _getActivityAnnotation(MethodElement element) {
    final annotation = const TypeChecker
      .fromRuntime(Activity)
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

  void _throwInvalidTargetError(Element element) {
    throw InvalidGenerationSourceError(
      '@activities can only be applied to classes.',
      element: element,
    );
  }
}