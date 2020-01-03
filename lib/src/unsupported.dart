class Firestore {
  String collection;

  Firestore(this.collection);

  Future<dynamic> add(Map<String, dynamic> data) {
    throw 'Platform Not Supported!';
  }

  Future<void> update(String documentId, Map<String, dynamic> data) {
    throw 'Platform Not Supported!';
  }

  Future<void> delete(String documentId) {
    throw 'Platform Not Supported!';
  }

  Stream<dynamic> list() {
    throw 'Platform Not Supported!';
  }

  static DateTime getDate(dynamic date) {
    throw 'Platform Not Supported!';
  }
}
