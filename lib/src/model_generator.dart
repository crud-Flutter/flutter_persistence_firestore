import 'package:analyzer/dart/element/element.dart';
import 'package:build/src/builder/build_step.dart';
import 'package:flutter_persistence_api/flutter_persistence_api.dart';
import 'package:flutter_persistence_firestore/src/class_source.dart';
import 'package:source_gen/source_gen.dart';

class EntityGenerator extends GeneratorForAnnotation<Entity> {
  @override
  generateForAnnotatedElement(
      Element element, ConstantReader annotation, BuildStep buildStep) {
    GenerateEntityClass generateClass = new GenerateEntityClass(element.name);    
    var fieldAnnotation = TypeChecker.fromRuntime(Field);
    for (var field in (element as ClassElement).fields) {
      generateClass.addField(field.type.name, field.name,
          persistField: fieldAnnotation.hasAnnotationOfExact(field));
    }
    return generateClass.build();
  }
}
