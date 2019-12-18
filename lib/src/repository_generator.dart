import 'package:analyzer/dart/element/element.dart';
import 'package:build/src/builder/build_step.dart';
import 'package:flutter_persistence_api/flutter_persistence_api.dart';
import 'package:crud_generator/crud_generator.dart';
import 'package:source_gen/source_gen.dart';

class RepositoryGenerator extends GeneratorForAnnotation<Entity> {
  @override
  generateForAnnotatedElement(
      Element element, ConstantReader annotation, BuildStep buildStep) {
    return GenerateRepositoryClass(element.name).build();
  }
}

class GenerateRepositoryClass extends GenerateEntityClassAbstract {
  
  GenerateRepositoryClass(String name)
      : super(name, classSuffix: 'Repository') {
    _reference();
    _add();
    _update();
    _delete();
    _list();
  }

  _reference() {
    generateClass.writeln(
        'CollectionReference _collection = Firestore.instance.collection(\'$nameLowerCase\');');
  }

  _add() {
    generateClass.writeln(
        'void add($entityClassInstance) => _collection.add($entityInstance.toMap());');
  }

  _update() {
    generateClass.writeln(
        'void update(String documentId, $entityClassInstance) => _collection.document(documentId).updateData($entityInstance.toMap());');
  }

  _delete() {
    generateClass.writeln(
        'void delete(String documentId) => _collection.document(documentId).delete();');
  }

  _list() {
    generateClass.writeln('Stream<List<$entityClass>> get $nameLowerCase'
        's => _collection.snapshots().map((snapshot) => snapshot.documents.map<$entityClass>((document) => $entityClass.fromMap(document)).toList());');
  }

  @override
  addImports() {
    importEntity();
    generateClass
        .writeln('import \'package:cloud_firestore/cloud_firestore.dart\';');
  }
}
