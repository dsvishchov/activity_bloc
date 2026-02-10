import 'package:activity_bloc/activity_bloc.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

class ActivityBlocGenerator {
  const ActivityBlocGenerator(
    this.options, {
    required this.definingClass,
    required this.definingClassAnnotation,
    required this.method,
    required this.methodAnnotation,
  });

  final BuilderOptions options;
  final ClassElement definingClass;
  final Activities definingClassAnnotation;
  final MethodElement method;
  final Activity methodAnnotation;

  String get inputTypeName => '${_typePrefix}Input';
  String get stateTypeName => '${_typePrefix}State';
  String get blocTypeName => '${_typePrefix}Bloc';

  String blocDefinition() {
    return [
      _inputDefinition,
      _blocDefinition,
    ].join();
  }

  String mixinGetter() {
    return '$blocTypeName get ${method.firstFragment.name} => blocs();';
  }

  String get _inputDefinition {
    if (_namedParameters.isEmpty) {
      return '';
    }

    final constructorParameters = _namedParameters
      .map((parameter) => '${parameter.isRequired ? 'required ' : ''} this.${parameter.firstFragment.name},')
      .join('\n');

    final fields = _namedParameters
      .map((parameter) => 'final ${parameter.type.getDisplayString()} ${parameter.firstFragment.name};')
      .join('\n');

    return '''
      final class $inputTypeName {
        const $inputTypeName({
          $constructorParameters
        });

        $fields
      }
    ''';
  }

  String get _blocDefinition {
    if (!method.returnType.isDartAsyncFuture || (method.returnType is! InterfaceType)) {
      _throwInvalidReturnTypeError(method);
    }

    final returnType = method.returnType as InterfaceType;
    final posiblyEitherType = returnType.typeArguments.firstOrNull;
    if ((posiblyEitherType?.element?.firstFragment.name != 'Either') || (posiblyEitherType is! InterfaceType)) {
      _throwInvalidReturnTypeError(method);
    }

    final eitherType = posiblyEitherType as InterfaceType;
    if (eitherType.typeArguments.length != 2) {
      _throwInvalidReturnTypeError(method);
    }

    final hasInput = _namedParameters.isNotEmpty;
    final hasOutput = eitherType.typeArguments[1].element?.firstFragment.name != null;

    final activityTypes = [
      hasInput ? inputTypeName : 'void',
      eitherType.typeArguments[1].getDisplayString(),
      eitherType.typeArguments[0].getDisplayString(),
    ];

    final activityParameters = _namedParameters
      .map((parameter) => '${parameter.firstFragment.name}: input.${parameter.firstFragment.name},')
      .join('\n');

    return '''
      typedef $stateTypeName = ActivityState<${activityTypes.join(', ')}>;

      typedef ${_typePrefix}Event = ActivityEvent;
      typedef ${_typePrefix}Run = ActivityRun;

      final class $blocTypeName extends ActivityBloc<${activityTypes.join(', ')}> {
        $blocTypeName({
          required this.source,
          ${hasInput ? 'super.input,' : '// No input'}
          ${hasOutput ? 'super.output,' : '// No output'}
          super.scope,
          super.runImmediately,
          super.runSilently,
        }) : super(
          activity: (input) => source.${method.firstFragment.name}(
            $activityParameters
          ),
        );

        final ${definingClass.firstFragment.name} source;
      }
    ''';
  }

  String get _name => methodAnnotation.name ?? method.firstFragment.name!;

  String get _typePrefix {
    final capitalizedName = '${_name[0].toUpperCase()}${_name.substring(1)}';
    final isClassCustomized = definingClassAnnotation.prefix != null;
    final isMethodCustomized = (methodAnnotation.name != null) || (methodAnnotation.prefix != null);

    return isClassCustomized && !isMethodCustomized
      ? '${definingClassAnnotation.prefix}$capitalizedName'
      : '${methodAnnotation.prefix ?? ''}$capitalizedName';
  }

  List<FormalParameterElement> get _namedParameters {
    return method.firstFragment.formalParameters
      .where((fragment) => fragment.element.isNamed)
      .map((fragment) => fragment.element)
      .toList();
  }

  void _throwInvalidReturnTypeError(Element element) {
    throw InvalidGenerationSourceError(
      '@activity can only be applied to async methods with return type of Future<Either<F, O>>',
      element: element,
    );
  }
}
