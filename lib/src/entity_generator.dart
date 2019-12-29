import 'package:analyzer/dart/element/element.dart';
import 'package:build/src/builder/build_step.dart';
import 'package:flutter_persistence_api/flutter_persistence_api.dart'
    as annotation;
import 'package:crud_generator/crud_generator.dart';
import 'package:source_gen/source_gen.dart';
import 'package:code_builder/code_builder.dart';

class EntityGenerator extends GenerateClassForAnnotation<annotation.Entity> {
  @override
  generateForAnnotatedElement(
      Element element, ConstantReader annotation, BuildStep buildStep) {
    init();
    name = '${element.name}Entity';
    this.element = element;
    _declareField();
    _constructorEmpty();
    _methodFromMap();
    _methodToMap();
    _documentIdFieldAndMethod();
    return build();
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
      if (isFieldPersist(field)) {
        if (field.type.name == 'DateTime' ||
            field.type.name == 'Date' ||
            field.type.name == 'Time') {
          addImportPackage(
              'package:flutter_persistence_firestore/firestore.dart');
          fieldFromMap.statements.add(Code(
              "${field.name} = Firestore.getDate(data['${field.name}']);"));
        } else {
          fieldFromMap.statements
              .add(Code("${field.name} = data['${field.name}'];"));
        }
      }
    });
    if (fieldFromMap.statements.length > 0) {
      fieldFromMap.statements.insert(0, Code('_documentId = documentId;'));
      declareConstructorNamed('fromMap', fieldFromMap.build(),
          requiredParameters: [
            Parameter((b) => b
              ..name = 'documentId'
              ..type = refer('String')),
            Parameter((b) => b
              ..name = 'data'
              ..type = refer('Map<String, dynamic>'))
          ]);
    }
  }

  void _methodToMap() {
    var fieldToMap = BlockBuilder();
    elementAsClass.fields.forEach((field) {
      if (isFieldPersist(field)) {
        fieldToMap.statements
            .add(Code('map[\'${field.name}\'] = this.${field.name};'));
      }
    });
    if (fieldToMap.statements.length > 0) {
      fieldToMap.statements
          .insert(0, Code('var map = new Map<String, dynamic>();'));
      fieldToMap.statements.add(Code('return map;'));
      declareMethod('toMap',
          returns: refer('Map<String, dynamic>'), body: fieldToMap.build());
    }
  }
}
