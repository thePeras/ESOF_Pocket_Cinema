import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pocket_cinema/model/comment.dart';
import 'package:pocket_cinema/model/media.dart';
import 'package:pocket_cinema/model/media_list.dart';
import 'package:pocket_cinema/model/my_user.dart';

class FirestoreDatabase {
  static Future<String> getUsernameById(String id) async {
    final DocumentReference docRef =
        FirebaseFirestore.instance.collection('users').doc(id);
    final DocumentSnapshot snapshot = await docRef.get();

    if (snapshot.exists) {
      return snapshot.get('username');
    }
    return "Anonymous";
  }

  static Future<String> getEmail(String username) async {
    final usersRef = FirebaseFirestore.instance.collection('users');
    QuerySnapshot snapshot =
        await usersRef.where("username", isEqualTo: username).get();
    if (snapshot.docs.isNotEmpty) {
      String email = snapshot.docs.first.get('email');
      return email;
    }
    return Future.error("User not found");
  }

  static bool isEmail(String str) {
    return RegExp(
            r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
        .hasMatch(str);
  }

  static void addComment(String mediaId, String text) {
    final commentsRef = FirebaseFirestore.instance.collection('comments');
    commentsRef.add({
      "media_id": mediaId,
      "text": text,
      "user_id": FirebaseAuth.instance.currentUser!.uid,
      "time_posted": Timestamp.now()
    });
  }

  static Future<List<Comment>> getComments(String mediaId) async {
    final commentsRef = FirebaseFirestore.instance.collection('comments');
    final querySnapshot = await commentsRef
        .where("media_id", isEqualTo: mediaId)
        .orderBy('time_posted', descending: true)
        .get();

    final List<DocumentSnapshot> commentDocs = querySnapshot.docs;

    List<Comment> comments = await Future.wait(commentDocs.map((doc) async {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      final String userId = data['user_id'];
      final String username = await getUsernameById(userId);

      return Comment(
        mediaID: mediaId,
        username: username,
        userId: userId,
        content: data['text'],
        createdAt: data['time_posted'],
      );
    }));
    return comments;
  }

  static Future<bool> userExists(MyUser user) async {
    final QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where("username", isEqualTo: user.username)
        .where("email", isEqualTo: user.email)
        .get();
    return snapshot.docs.isNotEmpty;
  }

  static Future<bool> emailExists(String email) async {
    final QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where("email", isEqualTo: email)
        .get();
    return snapshot.docs.isNotEmpty;
  }

  static Future<bool> usernameExists(String username) async {
    final QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where("username", isEqualTo: username)
        .get();
    return snapshot.docs.isNotEmpty;
  }

  static Future<void> createUser(MyUser user, String userId) async {
    final docUser = FirebaseFirestore.instance.collection('users').doc(userId);
    await docUser.set(user.toJson());
  }


  static Future<void> createPersonalList(String name) async {
    final docList = FirebaseFirestore.instance.collection('lists').doc();
    await docList.set({
      'name': name,
      'mediaIds': [],
      'createdAt': Timestamp.now(),
      'lastUpdatedAt': Timestamp.now(),
      'ownerId': FirebaseAuth.instance.currentUser!.uid,
    });

    final docUser = FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid);

    await docUser.update({
      'personalLists': FieldValue.arrayUnion([docList.id])
    });
  }

  static Future<List<MediaList>> getPersonalLists() async {
    if (FirebaseAuth.instance.currentUser == null) {
      return [];
    }
    final personalListRef = FirebaseFirestore.instance.collection('lists');
    final querySnapshot = await personalListRef
        .where("ownerId", isEqualTo: FirebaseAuth.instance.currentUser!.uid)
        .orderBy('lastUpdatedAt', descending: true)
        .get();
    final List<MediaList> mediaLists = [];
    for (final doc in querySnapshot.docs) {
      final id = doc.id;
      final name = doc.data()['name'] as String;
      final mediaIds = doc.data()['mediaIds'] as List<dynamic>;
      final createdAt = doc.data()['createdAt'] as Timestamp;
      final lastUpdatedAt = doc.data()['lastUpdatedAt'] as Timestamp;
      final List<Media> media = await Future.wait(mediaIds.map((mediaId) async {
        final mediaSnapshot = await FirebaseFirestore.instance.collection('medias')
            .doc(mediaId).get();
        return Media(
          id: mediaSnapshot.id,
          name: mediaSnapshot.get('name'),
          posterImage: mediaSnapshot.get('posterUrl'),
        );
      }));
      mediaLists.add(MediaList(id: id, name: name, media: media, createdAt: createdAt, lastUpdatedAt: lastUpdatedAt));
    }
    return mediaLists;
  }

  static Future<void> deletePersonalList(String listId) async {
    if (FirebaseAuth.instance.currentUser == null) {
      throw Exception('User not logged in');
    }
    final docList = FirebaseFirestore.instance.collection('lists').doc(listId);
    await docList.delete();
    final docUser = FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid);
    await docUser.update({
      'personalLists': FieldValue.arrayRemove([listId])
    });
  }

  static Future<bool> mediaIsInList(Media media, String listId) async {
    final docList = FirebaseFirestore.instance.collection('lists').doc(listId);
    final docSnapshot = await docList.get();
    if (!docSnapshot.exists) {
      throw Exception('List does not exist');
    }
    final mediaIds = docSnapshot.get('mediaIds') as List<dynamic>;
    return mediaIds.contains(media.id);
  }

  static Future<String> toggleMediaInList(Media media, String listId) async {
    if (await mediaIsInList(media, listId)) {
      await removeMediaFromList(media.id, listId);
      return 'removed from';
    }
    await addMediaToList(media, listId);
    return 'added to';
  }

  static Future<void> addMediaToList(Media media, String listId) async {
    final docList = FirebaseFirestore.instance.collection('lists').doc(listId);
    await docList.update({
      'mediaIds': FieldValue.arrayUnion([media.id]),
      'lastUpdatedAt': Timestamp.now(),
    });
    mediaExists(media);
  }

  static Future<String> mediaExists(Media media) async {
    final docMedia =
        FirebaseFirestore.instance.collection('medias').doc(media.id);

    if (!(await docMedia.get()).exists) {
      final Map<String, dynamic> mediaJson = media.toJson();
      if (media.type == MediaType.series) mediaJson['episodes'] = [];
      await docMedia.set(mediaJson);
    }
    return docMedia.id;
  }

  static Future<void> removeMediaFromList(String mediaId, String listId) async {
    final docList = FirebaseFirestore.instance.collection('lists').doc(listId);
    await docList.update({
      'mediaIds': FieldValue.arrayRemove([mediaId]),
      'lastUpdatedAt': Timestamp.now(),
    });
  }

  static Future<void> addMediaToWatch(Media media) async {
    if (FirebaseAuth.instance.currentUser == null){
      throw Exception('User not logged in');
    }
    mediaExists(media);
    final docUser = FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid);

    final userSnapshot = await docUser.get();
    final List listMedia = userSnapshot.data()?["ToWatch"] ?? [];
    if (listMedia.contains(media.id)) throw Exception("Already added");
    await docUser.update({
      "ToWatch": FieldValue.arrayUnion([media.id])
    });
    return;
  }

  static Future<void> toggleMediaStatus(Media media, String listName) async {
    if (listName != 'watched' && listName != 'toWatch') {
      throw Exception('Invalid list');
    }

    if(FirebaseAuth.instance.currentUser == null) {
      throw Exception('User not logged in');
    }

    mediaExists(media);

    final docUser = FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid);


    final userSnapshot = await docUser.get();
    final List listMedia = userSnapshot.data()?[listName] ?? [];

    if (listMedia.contains(media.id)) {
      await docUser.update({
        listName: FieldValue.arrayRemove([media.id])
      });
    } else {
      await docUser.update({
        listName: FieldValue.arrayUnion([media.id])
      });
    }
  }

  static Future<List<Media>> getPredefinedList(String listName) async {
    if (listName != "watched" && listName != "ToWatch") {
      throw Exception("List name given incorrect");
    }
    if (FirebaseAuth.instance.currentUser == null) {
      return [];
    }
    final userSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .get();

    final List list = userSnapshot.data()?[listName] ?? [];

    final List<Media> medias =
        await Future.wait(list.map((mediaId) async {
      final mediaSnapshot = await FirebaseFirestore.instance
          .collection('medias')
          .doc(mediaId)
          .get();
      return Media(
        id: mediaSnapshot.id,
        name: mediaSnapshot.get('name'),
        posterImage: mediaSnapshot.get('posterUrl'),
      );
    }));
    return medias;
  }
}
