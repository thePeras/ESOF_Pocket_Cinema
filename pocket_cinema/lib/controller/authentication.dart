import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:pocket_cinema/model/my_user.dart';

import 'firestore_funcs.dart';

class Authentication {
  static Future<void> signOut() async {
    final googleSignIn = GoogleSignIn();
    await googleSignIn.signOut();
    await FirebaseAuth.instance.signOut();
  }
  static Future signIn(TextEditingController userIdTextController, TextEditingController passwordTextController) async {
    final userId = userIdTextController.text;
    return FirebaseAuth.instance.signInWithEmailAndPassword(
      email: isEmail(userId) ? userId : await getEmail(userId).then((email) => email),
      password: passwordTextController.text,
    ).onError((error, stackTrace) {
      throw("Error: ${error.toString()}");
    });
  }

  static Future<User?> signInWithGoogle() async {
    final googleSignIn = GoogleSignIn();
    final googleUser = await googleSignIn.signIn();
    if (googleUser == null) {
      throw FirebaseAuthException(
        message: "Sign in aborted by user",
        code: "ERROR_ABORTED_BY_USER",
      );
    }

    final googleAuth = await googleUser.authentication;
    if (googleAuth.idToken != null) {
      final userCredential = await FirebaseAuth.instance.signInWithCredential(
        GoogleAuthProvider.credential(
          idToken: googleAuth.idToken,
          accessToken: googleAuth.accessToken,
        ),
      );
      return userCredential.user;
    }
  }

  static Future createUserGoogleSignIn(MyUser user) async {
    if (! await userExists(user)) {
      // Reference to a document
      final docUser = FirebaseFirestore.instance.collection('users').doc();
      user.id = docUser.id;
      // Create document and write data to Firebase
      await docUser.set(user.toJson());
    }
  }
  static Future<bool> userExists(MyUser user) async {
    final QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('users')
        .where("username", isEqualTo: user.username)
        .where("email", isEqualTo: user.email)
        .get();
    return snapshot.docs.isNotEmpty;
  }
  static Future createUser(MyUser user) async {
    // Reference to a document
    final docUser = FirebaseFirestore.instance.collection('users').doc();
    user.id = docUser.id;
    // Create document and write data to Firebase
    await docUser.set(user.toJson());
  }
}
