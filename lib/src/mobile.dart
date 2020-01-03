import 'package:cloud_firestore/cloud_firestore.dart' as fs;

class Firestore {
  String collection;
  fs.CollectionReference _collection;

  Firestore(this.collection) {    
    _collection = fs.Firestore.instance.collection(this.collection);
  }

  Future<dynamic> add(Map<String, dynamic> data) {
    return _collection.add(data);
  }

  Future<void> update(String documentId, Map<String, dynamic> data) {
    return _collection.document(documentId).updateData(data);    
  }

  Future<void> delete(String documentId) {
    return _collection.document(documentId).delete();
  }

  Stream<dynamic> list() {
    return _collection.snapshots();
  }

  static DateTime getDate(dynamic date) {
    if (date is fs.Timestamp) {
      return date.toDate();
    } else if (date is DateTime) {
      return date;
    }
    return null;    
  }
}