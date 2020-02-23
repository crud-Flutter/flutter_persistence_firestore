import 'package:analyzer/dart/element/element.dart';
import 'package:flutter_persistence_api/flutter_persistence_api.dart'
    as annotation;
import 'package:crud_generator/crud_generator.dart';
import 'package:code_builder/code_builder.dart';

class EntityGenerator extends GenerateClassForAnnotation<annotation.Entity> {
  @override
  String generateName() => entityClass;

  @override
  void optionalClassInfo() {
    addImportPackage('${element.name.toLowerCase()}.dart');
    extend = refer('${element.name}');
  }

  void generateConstructors() {
    declareConstructor();
    _constructorFromMap();
  }

  @override
  void generateFields() {
    elementAsClass.fields.forEach((field) {
      if (isManyToOneField(field)) {
        addImportPackage('../${field.type.name.toLowerCase()}'
            '/${field.type.name.toLowerCase()}.entity.dart');
      } else if (isOneToManyField(field)) {
        addImportPackage(
            '../${getGenericTypes(field.type).first.name.toLowerCase()}'
            '/${getGenericTypes(field.type).first.name.toLowerCase()}.entity.dart');
      }
    });
    declareField(refer('String'), 'documentId');
  }

  @override
  void generateMethods() {
    _methodToMap();
  }

  void _constructorFromMap() {
    var fieldFromMap = StringBuffer();

    elementAsClass.fields.forEach((field) {
      if (isFieldPersist(field)) {
        if (field.type.name == 'DateTime' ||
            field.type.name == 'Date' ||
            field.type.name == 'Time') {
          addImportPackage(
              'package:flutter_persistence_firestore/firestore.dart');
          fieldFromMap.writeln(
              "${field.name} = Firestore.getDate(data['${field.name}']);");
        } else if (isManyToOneField(field)) {
          var displayField = getDisplayField(annotation.ManyToOne, field);
          fieldFromMap.writeln('''${field.name} = 
              ${field.type.name}Entity()..$displayField=data['${field.name}'];''');
        } else if (isOneToManyField(field)) {
          fieldFromMap.writeln("if (data['${field.name}'] != null)");
          var displayField = getDisplayField(annotation.OneToMany, field);
          var type = getGenericTypes(field.type).first.name;
          var displayFieldType =
              (getGenericTypes(field.type).first.element as ClassElement)
                  .getField(getDisplayField(annotation.OneToMany, field))
                  .type
                  .name;
          fieldFromMap.writeln('''
              ${field.name} = data['${field.name}'].map<${type}Entity>((${field.name}Entity)
               => ${getGenericTypes(field.type).first.name}Entity()..$displayField = 
              (${field.name}Entity.keys.first as $displayFieldType)).toList();
              ''');
        } else {
          fieldFromMap.writeln("${field.name} = data['${field.name}'];");
        }
      }
    });
    if (fieldFromMap.isNotEmpty) {
      fieldFromMap.writeln('this.documentId = documentId;');
      declareConstructorNamed('fromMap', Code(fieldFromMap.toString()),
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
    var fieldToMap = StringBuffer();
    elementAsClass.fields.forEach((field) {
      if (isFieldPersist(field)) {
        if (isManyToOneField(field)) {
          var displayField = getDisplayField(annotation.ManyToOne, field);
          fieldToMap
              .writeln("map['${field.name}'] = ${field.name}.${displayField};");
        } else if (isOneToManyField(field)) {
          fieldToMap.writeln('if (${field.name} !=null)');
          var displayField = getDisplayField(annotation.OneToMany, field);
          fieldToMap.writeln('''
                    map['${field.name}'] = ${field.name}.map((${field.name}) =>
                  {${field.name}.$displayField: true}).toList();
                  ''');
        } else {
          fieldToMap.writeln("map['${field.name}'] = ${field.name};");
        }
      }
    });
    if (fieldToMap.isNotEmpty) {
      fieldToMap.writeln('return map;');
      declareMethod('toMap',
          returns: refer('Map<String, dynamic>'),
          body: Code(
              'var map = Map<String, dynamic>();' + fieldToMap.toString()));
    }
  }

  EntityGenerator instance() => EntityGenerator()
    ..manyToMany = true
    ..generateImport = false;
}
