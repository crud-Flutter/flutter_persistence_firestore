import 'package:analyzer/dart/element/element.dart';
import 'package:build/src/builder/build_step.dart';
import 'package:code_builder/code_builder.dart';
import 'package:flutter_persistence_api/flutter_persistence_api.dart';
import 'package:crud_generator/crud_generator.dart';
import 'package:source_gen/source_gen.dart';

class RepositoryGenerator extends GenerateEntityClassForAnnotation<Entity> {
  @override
  generateForAnnotatedElement(
      Element element, ConstantReader annotation, BuildStep buildStep) {
    init();
    this.element = element;
    name = '${element.name}Repository';
    addImportPackage('${element.name.toLowerCase()}.entity.dart');
    _declareField();
    _methodAdd();
    _methodUpdate();
    _methodDelete();
    _methodList();
    return build();
  }

  void _declareField() {
    addImportPackage('package:flutter_persistence_firestore/firestore.dart');
    declareField(
        refer('Firestore'),
        'firestore',
        assignment: Code(
            "Firestore('${element.name.toLowerCase()}')"));
  }

  void _methodAdd() {
    declareMethod('add',
        returns: refer('Future<String>'),
        requiredParameters: [
          Parameter((b) => b
            ..name = entityInstance
            ..type = refer(entityClass))
        ],
        lambda: true,
        body:
            Code('firestore.add($entityInstance.toMap())'),
        modifier: MethodModifier.async);
  }

  void _methodUpdate() {
    declareMethod('update',
        returns: refer('Future<void>'),
        requiredParameters: [
          Parameter((b) => b
            ..name = 'documentId'
            ..type = refer('String')),
          Parameter((b) => b
            ..name = entityInstance
            ..type = refer(entityClass))
        ],
        lambda: true,
        body: Code(
            'firestore.update(documentId, $entityInstance.toMap())'));
  }

  void _methodDelete() {
    declareMethod('delete',
        returns: refer('Future<void>'),
        requiredParameters: [
          Parameter((b) => b
            ..name = 'documentId'
            ..type = refer('String'))
        ],
        lambda: true,
        body: Code('firestore.delete(documentId)'));
  }

  void _methodList() {
    declareMethod('list',
        returns: refer('Stream<List<$entityClass>>'),
        lambda: true,
        body: Code(
            'firestore.list().map((snapshot) => snapshot.documents.map<$entityClass>((document) => $entityClass.fromMap(document.documentID, document.data)).toList())'));
  }
}
