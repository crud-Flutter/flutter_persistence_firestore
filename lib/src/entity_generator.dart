import 'package:analyzer/dart/element/element.dart';
import 'package:build/src/builder/build_step.dart';
import 'package:flutter_persistence_api/flutter_persistence_api.dart'
    as annotation;
import 'package:crud_generator/crud_generator.dart';
import 'package:source_gen/source_gen.dart';
import 'package:code_builder/code_builder.dart';

class EntityGenerator extends GenerateClassForAnnotation<annotation.Entity> {
  TypeChecker fieldAnnotation = TypeChecker.fromRuntime(annotation.Field);

  @override
  generateForAnnotatedElement(
      Element element, ConstantReader annotation, BuildStep buildStep) {
    name = '${element.name}Entity';
    this.element = element;
    _declareField();
    _constructorEmpty();
    _methodFromMap();
    _methodToMap();
    _documentIdFieldAndMethod();
    return "import 'package:cloud_firestore/cloud_firestore.dart';\n" + build();
  }

  void _constructorEmpty() {
    declareConstructor();
  }

  void _documentIdFieldAndMethod() {
    declareField(refer('String'), '_documentId');
    declareMethod('documentId',
        lambda: true, returns: refer('String'), body: Code('_documentId'));
  }

  void _declareField() {
    elementAsClass.fields.forEach((field) {
      declareField(refer(field.type.name), field.name);
    });
  }

  void _methodFromMap() {
    var fieldFromMap = BlockBuilder();

    elementAsClass.fields.forEach((field) {
      if (fieldAnnotation.hasAnnotationOfExact(field)) {
        if (field.type.name == 'DateTime') {
          fieldFromMap.statements.add(
              Code("Timestamp timestamp = document.data['${field.name}'];"));
          fieldFromMap.statements.add(Code(
              "document.data['${field.name}'] == null ? null: DateTime.fromMillisecondsSinceEpoch(timestamp.millisecondsSinceEpoch);"));
        } else {
          fieldFromMap.statements
              .add(Code("${field.name} = document.data['${field.name}'];"));
        }
      }
    });
    if (fieldFromMap.statements.length > 0) {
      declareConstructorNamed('fromMap', fieldFromMap.build(),
          requiredParameters: [
            Parameter((b) => b
              ..name = 'document'
              ..type = refer('DocumentSnapshot'))
          ]);
    }
  }

  void _methodToMap() {
    var fieldToMap = BlockBuilder();
    elementAsClass.fields.forEach((field) {
      if (fieldAnnotation.hasAnnotationOfExact(field)) {
        fieldToMap.statements
            .add(Code('map[\'${field.name}\'] = this.${field.name};'));
      }
    });
    if (fieldToMap.statements.length > 0) {
      fieldToMap.statements
          .insert(0, Code('var map = new Map<String, dynamic>();'));
      declareMethod('toMap',
          returns: refer('Map<String, dynamic>'), body: fieldToMap.build());
    }
  }
}
