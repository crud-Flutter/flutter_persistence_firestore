import 'package:crud_generator/crud_generator.dart';

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
              'DateTime.fromMillisecondsSinceEpoch(timestamp.millisecondsSinceEpoch)';
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

class GenerateRepositoryClass extends GenerateEntityClassAbstract {
  
  GenerateRepositoryClass(String name)
      : super(name, classSuffix: 'Repository') {
    // GenerateRepositoryClass(String name): super(name+'Repository', parentClass: 'Disposable') {
    
    _reference();
    _add();
    _update();
    _delete();
    _list();
  }

  _reference() {
    String collection = this.classPrefix.toLowerCase();
    generateClass.writeln(
        'CollectionReference _collection = Firestore.instance.collection(\'$collection\');');
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
    generateClass.writeln(
        'Stream<List<$entityClass>> get $entityInstance => _collection.snapshots().map((snapshot) => snapshot.documents.map<$entityClass>((document) => $entityClass.fromMap(document)).toList());');
  }

  @override
  addImports() {
    importEntity();
    generateClass
        .writeln('import \'package:cloud_firestore/cloud_firestore.dart\';');
  }
}
