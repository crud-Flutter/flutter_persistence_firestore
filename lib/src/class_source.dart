class GenerateClass {
  String name;
  String parentClass;
  StringBuffer generateClass = new StringBuffer();
  GenerateClass(this.name, {String import, this.parentClass}) {    
    if (import != null) generateClass.writeln(import);
    _setClass();
  }

  _setClass() {
    // generateClass.writeln('class $name {');
    String declaredClass = 'class $name';
    if (this.parentClass != null) {
      declaredClass += 'extends $parentClass';
    }
    declaredClass += ' {';
    generateClass.writeln(declaredClass);
  }
}

class GenerateModelClass extends GenerateClass {
  Map<String, String> fields = new Map();

  GenerateModelClass(String name)
      : super(name+'Entity',
            import:
                'import \'package:cloud_firestore/cloud_firestore.dart\';') {
    generateClass.writeln('String _documentId;');
    generateClass.writeln('$name'+'Entity();');
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
    if (fields.length>0) {
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
    generateClass.writeln('}');
    return generateClass.toString();
  }
}
