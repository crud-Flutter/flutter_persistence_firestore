abstract class GenerateClass {
  String name;
  String classPrefix;
  String classSuffix;
  String parentClass;
  StringBuffer generateClass = new StringBuffer();
  GenerateClass(this.classPrefix, {this.classSuffix, this.parentClass}) {
    this.name = this.classPrefix;
    if (this.classSuffix != null) {
      this.name += this.classSuffix;
    }
    addImports();
    _setClass();
  }

  _setClass() {
    String declaredClass = 'class $name';
    if (this.parentClass != null) {
      declaredClass += ' extends $parentClass';
    }
    declaredClass += ' {';
    generateClass.writeln(declaredClass);
  }

  constructorEmpty() {
    generateClass.writeln('$name();');
  }

  String build() {
    generateClass.write('}');
    return generateClass.toString();
  }

  addImports();
}

class GenerateModelClass extends GenerateClass {
  Map<String, String> fields = new Map();

  GenerateModelClass(String name) : super(name, classSuffix: 'Entity') {
    generateClass.writeln('String _documentId;');
    this.constructorEmpty();
    generateClass.writeln('String documentId() => this._documentId;');
  }

  GenerateModelClass addField(String type, String name,
      {bool persistField: false}) {
    if (persistField) {
      fields[name] = type;
    }
    generateClass.writeln('$type $name;');
    return this;
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

class GenerateRepositoryClass extends GenerateClass {
  String entityInstance;
  String entityClassInstance;
  String entityClass;
  GenerateRepositoryClass(String name)
      : super(name, classSuffix: 'Repository') {
    // GenerateRepositoryClass(String name): super(name+'Repository', parentClass: 'Disposable') {
    this.entityInstance = name.toLowerCase() + 'Entity';
    this.entityClass = this.classPrefix + 'Entity';
    this.entityClassInstance = '$entityClass $entityInstance';
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
    String fileEntity = this.classPrefix.toLowerCase() + '.entity.dart';
    generateClass.writeln('import \'$fileEntity\';');    
    generateClass
        .writeln('import \'package:cloud_firestore/cloud_firestore.dart\';');    
  }
}
