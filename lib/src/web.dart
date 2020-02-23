import 'dart:async';

import 'package:firebase/firestore.dart' as fs;
import 'package:firebase/firebase.dart';

class Firestore {
  fs.CollectionReference _collection;

  Firestore(String collection) {
    _collection = firestore().collection(collection);
  }

  Firestore.documentId(
      String collection, String subCollection, String documentId) {
    _collection = firestore()
        .collection(collection)
        .doc(documentId)
        .collection(subCollection);
  }

  Future<dynamic> add(Map<String, dynamic> data) {
    return _collection.add(data);
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
