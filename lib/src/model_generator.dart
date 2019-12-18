import 'package:analyzer/dart/element/element.dart';
import 'package:build/src/builder/build_step.dart';
import 'package:flutter_persistence_api/flutter_persistence_api.dart';
import 'package:crud_generator/crud_generator.dart';
import 'package:source_gen/source_gen.dart';

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
    generateClass.writeln('String _documentId;');
    this.constructorEmpty();
    generateClass.writeln('String documentId() => this._documentId;');
  }

  _fromMap() {
    if (fields.length > 0) {
      generateClass.writeln('$name.fromMap(DocumentSnapshot document) {');
      generateClass.writeln('_documentId = document.documentID;');
      fields.forEach((name, type) {
        String value = 'document.data[\'$name\']';
        if (type == 'DateTime') {
          generateClass
              .writeln('Timestamp timestamp = document.data[\'$name\'];');
          value =
              'document.data[\'$name\'] == null? null:DateTime.fromMillisecondsSinceEpoch(timestamp.millisecondsSinceEpoch)';
        }
        generateClass.writeln('this.$name = $value;');
      });
      generateClass.writeln('}');
    }
  }

  _toMap() {
    if (fields.length > 0) {
      generateClass.writeln('toMap() {');
      generateClass.writeln('var map = new Map<String, dynamic>();');
      fields.forEach((name, type) {
        generateClass.writeln('map[\'$name\'] = this.$name;');
      });
      generateClass.writeln('return map;');
      generateClass.writeln('}');
    }
  }

  String build() {
    this._fromMap();
    this._toMap();
    return super.build();
  }

  @override
  addImports() {
    generateClass
        .writeln('import \'package:cloud_firestore/cloud_firestore.dart\';');
  }
}
