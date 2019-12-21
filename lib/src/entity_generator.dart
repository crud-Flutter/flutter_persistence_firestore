import 'package:analyzer/dart/element/element.dart';
import 'package:build/src/builder/build_step.dart';
import 'package:flutter_persistence_api/flutter_persistence_api.dart';
import 'package:crud_generator/crud_generator.dart';
import 'package:source_gen/source_gen.dart';
import 'package:code_builder/code_builder.dart' as code;

class EntityGenerator extends GeneratorForAnnotation<Entity> {
  @override
  generateForAnnotatedElement(
      Element element, ConstantReader annotation, BuildStep buildStep) {
    GenerateEntityClass generateClass = GenerateEntityClass(element.name);
    var fieldAnnotation = TypeChecker.fromRuntime(Field);
    for (var field in (element as ClassElement).fields) {
      generateClass.addField(field.type.name, field.name,
          persistField: fieldAnnotation.hasAnnotationOfExact(field));
    }
    return generateClass.build();
  }
}

class GenerateEntityClass extends GenerateClass {
  GenerateEntityClass(String name) : super(name, classSuffix: 'Entity') {
    generateClass.fields.add(code.Field((b) => b
      ..name = '_documentId'
      ..type = code.refer('String')));
  }

  _fromMap() {
    if (fields.fieldsPersist().length > 0) {
      List<code.Code> codes = List();
      codes.add(code.Code('_documentId = document.documentID;'));
      fields.fieldsPersist().forEach((name, type) {
        String value = 'document.data[\'$name\'];';
        if (type == 'DateTime') {
          codes.add(
              code.Code('Timestamp timestamp = document.data[\'$name\'];'));
          value =
              'document.data[\'$name\'] == null? null:DateTime.fromMillisecondsSinceEpoch(timestamp.millisecondsSinceEpoch);';
        }
        codes.add(code.Code('$name = $value'));
      });

      generateClass.constructors.add(code.Constructor((b) => b
        ..name = 'fromMap'
        ..body = code.Block((b) => b..statements.addAll(codes))
        ..requiredParameters.add(code.Parameter((b) => b
          ..name = 'document'
          ..type = code.refer('DocumentSnapshot')))));
    }
  }

  _toMap() {
    if (fields.fieldsPersist().length > 0) {
      var codes = code.BlockBuilder();
      codes.statements.add(code.Code('var map = new Map<String, dynamic>();'));
      fields.fieldsPersist().forEach((name, type) {
        codes.statements.add(code.Code('map[\'$name\'] = this.$name;'));
      });
      generateClass.methods.add(code.Method((b) => b
        ..name = 'toMap'
        ..body = codes.build()));
    }
  }

  String build() {
    this._fromMap();
    this._toMap();
    return 'import \'package:cloud_firestore/cloud_firestore.dart\';\n' +
        super.build();
  }
}
