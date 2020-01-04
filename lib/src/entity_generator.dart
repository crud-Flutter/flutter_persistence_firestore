import 'package:analyzer/dart/element/element.dart';
import 'package:build/src/builder/build_step.dart';
import 'package:flutter_persistence_api/flutter_persistence_api.dart'
    as annotation;
import 'package:crud_generator/crud_generator.dart';
import 'package:source_gen/source_gen.dart';
import 'package:code_builder/code_builder.dart';

class EntityGenerator extends GenerateClassForAnnotation<annotation.Entity>
    with GenerateManyToManyAnnotation {
  EntityGenerator({bool generateImport, bool manyToMany}) {
    this.generateImport = generateImport;
    this.manyToMany = manyToMany;
  }
  @override
  generateForAnnotatedElement(
      Element element, ConstantReader annotation, BuildStep buildStep) {
    init();
    initManyToMany();
    name = '${element.name}${manyToManyPosFix}Entity';
    extend = refer('${element.name}');
    addImportPackage('${element.name.toLowerCase()}.dart');    
    this.element = element;
    _declareField();
    _constructorEmpty();
    _methodFromMap();
    _methodToMap();
    _documentIdFieldAndMethod();
    _classManyToMany();
    return build(generateImport: !manyToMany) + manyToManyClass;
  }

  _classManyToMany() {
    if (!manyToMany) {
      elementAsClass.fields.forEach((field) {
        if (isManyToManyField(field)) {
          manyToManyClass +=
              EntityGenerator(generateImport: false, manyToMany: true)
                  .generateForAnnotatedElement(
                      getGenericTypes(field.type).first.element, null, null);
        }
      });
    }
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
      if (isManyToOneField(field)) {
        addImportPackage(
            '../${field.type.name.toLowerCase()}/${field.type.name.toLowerCase()}.dart');
      } else if (isOneToManyField(field)) {
        var type = getGenericTypes(field.type);
        addImportPackage(
            '../${getGenericTypes(field.type).first.name.toLowerCase()}'
            '/${getGenericTypes(field.type).first.name.toLowerCase()}.dart');
      }
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
        } else if (isManyToOneField(field)) {
          var displayField = getDisplayField(annotation.ManyToOne, field);
          fieldFromMap.statements.add(Code(
              "${field.name} = ${field.type.name}()..$displayField=data['${field.name}'];"));
        } else if (isOneToManyField(field)) {
        fieldFromMap.statements.add(Code("if (data['${field.name}'] != null)"));
          var displayField = getDisplayField(annotation.OneToMany, field);
          var type = getGenericTypes(field.type).first.name;
          var displayFieldType = (getGenericTypes(field.type).first.element as ClassElement)
            .getField(getDisplayField(annotation.OneToMany, field))
            .type
            .name;
          fieldFromMap.statements.add(Code(
              "${field.name} = data['${field.name}'].map<$type>((${field.name}) => "
              '${getGenericTypes(field.type).first.name}()..$displayField = '
              '(${field.name}.keys.first as $displayFieldType)).toList();'));
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
        if (isManyToOneField(field)) {
          var displayField = getDisplayField(annotation.ManyToOne, field);
          fieldToMap.statements.add(Code(
              'map[\'${field.name}\'] = this.${field.name}.${displayField};'));
        } else if (isOneToManyField(field)) {
          fieldToMap.statements.add(Code('if (${field.name} !=null)'));
          var displayField = getDisplayField(annotation.OneToMany, field);
          fieldToMap.statements.add(Code(
              "map['${field.name}'] = this.${field.name}.map((${field.name}) =>"
              "{${field.name}.$displayField: true}).toList();"));
        } else {
          fieldToMap.statements
              .add(Code('map[\'${field.name}\'] = this.${field.name};'));
        }
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
