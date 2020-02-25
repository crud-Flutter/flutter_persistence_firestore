import 'package:code_builder/code_builder.dart';
import 'package:flutter_persistence_api/flutter_persistence_api.dart';
import 'package:crud_generator/crud_generator.dart';

class RepositoryGenerator extends GenerateEntityClassForAnnotation<Entity> {
  @override
  String generateName() => '${element.name}${manyToManyPosFix}Repository';

  @override
  void optionalClassInfo() {
    if (!manyToMany)
      addImportPackage('${element.name.toLowerCase()}.entity.dart');
  }

  generateConstructors() {
    if (manyToMany)
      declareConstructor(requiredParameters: [
        Parameter((b) => b
          ..name = 'collectionParent'
          ..type = refer('String')),
        Parameter((b) => b
          ..name = 'documentId'
          ..type = refer('String'))
      ], body: Code('''firestore = Firestore.documentId(
                    collectionParent, documentId, '${element.name.toLowerCase()}');
                    '''));
  }

  void generateFields() {
    addImportPackage('package:flutter_persistence_firestore/firestore.dart');
    if (manyToMany) {
      declareField(refer('Firestore'), 'firestore');
    } else {
      declareField(refer('Firestore'), 'firestore',
          assignment: Code("Firestore('${element.name.toLowerCase()}')"));
    }

    elementAsClass.fields.forEach((field) {
      if (isManyToOneField(field)) {
        addImportPackage('../${field.type.name.toLowerCase()}/${field.type.name.toLowerCase()}.repository.dart');
        declareField(
            refer('${field.type.name}Repository'), '${field.name}Repository');
      } else if (isManyToManyField(field)) {
        var type = getGenericTypes(field.type).first.element.name;
        declareField(
            refer('${type}ManyToManyRepository'), '${field.name}Repository');
      }
    });
  }

  void generateMethods() {
    _methodAdd();
    _methodUpdate();
    _methodDelete();
    _methodList();
    _methodListManyToOne();
  }

  void _methodAdd() {
    var addCode = StringBuffer(
        'var result = await firestore.add($entityInstance.toMap());');
    elementAsClass.fields.forEach((field) {
      if (isManyToManyField(field)) {
        var type = getGenericTypes(field.type).first.element.name;
        addCode.writeln('''
            ${field.name}Repository = 
            ${type}ManyToManyRepository('${element.name.toLowerCase()}', result.documentID);
            $entityInstance.${field.name}.forEach((${field.name}) {
            ${field.name}Repository.add(${field.name});
            });
            ''');
      }
    });
    addCode.writeln('return result;');
    declareMethod('add',
        returns: refer('Future<dynamic>'),
        requiredParameters: [
          Parameter((b) => b
            ..name = entityInstance
            ..type = refer(entityClass))
        ],
        body: Code(addCode.toString()),
        modifier: MethodModifier.async);
  }

  void _methodUpdate() {
    declareMethod('update',
        returns: refer('Future<void>'),
        requiredParameters: [
          Parameter((b) => b
            ..name = entityInstance
            ..type = refer(entityClass))
        ],
        lambda: true,
        body: Code(
            'firestore.update($entityInstance.documentId, $entityInstance.toMap())'));
  }

  void _methodDelete() {
    declareMethod('delete',
        returns: refer('Future<void>'),
        requiredParameters: [
          Parameter((b) => b
            ..name = '$entityInstance'
            ..type = refer('$entityClass'))
        ],
        lambda: true,
        body: Code('firestore.delete($entityInstance.documentId)'));
  }

  void _methodList() {
    declareMethod('list',
        returns: refer('Stream<List<$entityClass>>'),
        lambda: true,
        body: Code('''firestore.list().map((snapshot) => 
            snapshot.documents.map<$entityClass>((document) => 
            $entityClass.fromMap(document.documentID, document.data)).toList())
            '''));
  }

  void _methodListManyToOne() {
    elementAsClass.fields.forEach((field) {
      if (isManyToOneField(field)) {
        addImportPackage(
            '../${field.type.name.toLowerCase()}/${field.type.name.toLowerCase()}.repository.dart');
        addImportPackage(
            '../${field.type.name.toLowerCase()}/${field.type.name.toLowerCase()}.entity.dart');
        declareMethod('list${field.type.name}',
            returns: refer('Stream<List<${field.type.name}Entity>>'),
            lambda: true,
            body: Code("${field.name}Repository.list()"));
      }
    });
  }

  @override
  GenerateClassForAnnotation instance() => RepositoryGenerator()
    ..manyToMany = true
    ..generateImport = false;
}
