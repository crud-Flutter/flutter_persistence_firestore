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
    this.element = element;
    name = '${element.name}Repository';
    _referenceField();
    _methodAdd();
    _methodUpdate();
    _methodDelete();
    _methodList();
    return "import 'package:cloud_firestore/cloud_firestore.dart';\n"
            "import '${element.name.toLowerCase()}.entity.dart';" +
        build();
  }

  void _referenceField() {
    declareField(
        refer('CollectionReference',
            'package:cloud_firestore/cloud_firestore.dart'),
        '_collection',
        assignment: Code(
            "Firestore.instance.collection('${element.name.toLowerCase()}')"));
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
            Code('(await _collection.add($entityInstance.toMap())).documentID'),
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
            '_collection.document(documentId).updateData($entityInstance.toMap())'));
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
        body: Code(' _collection.document(documentId).delete()'));
  }

  void _methodList() {
    declareMethod('list',
        returns: refer('Stream<List<$entityClass>>'),
        lambda: true,
        body: Code(
            '_collection.snapshots().map((snapshot) => snapshot.documents.map<$entityClass>((document) => $entityClass.fromMap(document.documentID, document.data)).toList())'));
  }
}
