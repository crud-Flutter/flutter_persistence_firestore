import 'dart:async';

import 'package:firebase/firestore.dart' as fs;
import 'package:firebase/firebase.dart';

class Firestore {
  String collection;
  fs.CollectionReference _collection;
  
  Firestore(this.collection) {    
    _collection = firestore().collection(this.collection);
  }

  Future<String> add(Map<String, dynamic> data) async {
    var add = await _collection.add(data);
    return add.id;
  }

  Future<void> update(String documentId, Map<String, dynamic> data) {
    return _collection.doc(documentId).update(data: data);
  }

  Future<void> delete(String documentId) {
    return _collection.doc(documentId).delete();
  }

  Stream<dynamic> list() {
    StreamController<Documents> controller = StreamController<Documents>();
    _collection.onSnapshot.listen((snapshot) {
      controller.add(Documents(snapshot.docs
          .map<Document>((document) => Document(document.id, document.data()))
          .toList()));
    });
    return controller.stream;
  }

  static DateTime getDate(dynamic date) {
    return date;
  }
}

class Documents {
  List<Document> documents;
  Documents(this.documents);
}

class Document {
  String documentID;
  Map<String, dynamic> data;
  Document(this.documentID, this.data);
}
