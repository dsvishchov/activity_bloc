import 'package:activity_bloc/activity_bloc.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'activity_bloc_generator.dart';

class ActivitiesGenerator extends GeneratorForAnnotation<Activities> {
  ActivitiesGenerator(this.options);

  final BuilderOptions options;

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
    final className = '${definingClass.firstFragment.name}';

    final blocsBuffer = StringBuffer();

    final mixinBuffer = StringBuffer();
    final mixinPrefix = definingClassAnnotation.prefix ??
      className.replaceAll(RegExp(r'Repository|Service'), '');

    mixinBuffer.write('''\n\n
      mixin ${mixinPrefix}Blocs {
        B blocs<B extends StateStreamableSource>([String? id]);\n
    ''');

    final methods = definingClass.firstFragment.methods;
    for (final method in methods) {
      final methodAnnotation = _getActivityAnnotation(method.element);

      if (methodAnnotation != null) {
        final blocGenerator = ActivityBlocGenerator(
          options,
          definingClass: definingClass,
          definingClassAnnotation: definingClassAnnotation,
          method: method.element,
          methodAnnotation: methodAnnotation,
        );

        blocsBuffer.write(blocGenerator.blocDefinition());
        mixinBuffer.write(blocGenerator.mixinGetter());
      }
    }

    mixinBuffer.write('}');

    return [
      blocsBuffer.toString(),
      if (options.config['mixin'] ?? false) ...[
        mixinBuffer.toString(),
      ],
    ].join();
  }

  Activities _getActivitiesAnnotation(ClassElement element) {
    final annotation = const TypeChecker
      .typeNamed(Activities)
      .firstAnnotationOf(element);

    final reader = ConstantReader(annotation);
    final prefix = reader.peek('prefix');

    return Activities(
      prefix: prefix?.stringValue,
    );
  }

  Activity? _getActivityAnnotation(MethodElement element) {
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

  void _throwInvalidTargetError(Element element) {
    throw InvalidGenerationSourceError(
      '@activities can only be applied to classes.',
      element: element,
    );
  }
}