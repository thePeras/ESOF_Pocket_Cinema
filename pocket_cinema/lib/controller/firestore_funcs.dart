import 'package:cloud_firestore/cloud_firestore.dart';


Future<String> getEmail(String username) async {
  final usersRef = FirebaseFirestore.instance.collection('users');
  QuerySnapshot snapshot = await usersRef.where("username", isEqualTo: username).get();
  if (snapshot.docs.isNotEmpty) {
    String email = snapshot.docs.first.get('email');
    return email;
  }
  return "User not found";
}

bool isEmail(String str) {
  return RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
      .hasMatch(str);
}

void addComment(String mediaId, String text, String userId) {
  final commentsRef = FirebaseFirestore.instance.collection('comments');
  commentsRef.add(
    <String, dynamic> { // TODO: replace this for a model class that has comment information with a toJson method
      'media_id': mediaId,
      'user_id': userId,
      'text': text,
      'time_posted': DateTime.now(),
    }
  );
}
