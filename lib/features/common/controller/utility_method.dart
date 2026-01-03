import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl/intl.dart';

final FirebaseFirestore firestore = FirebaseFirestore.instance;
GoogleAuthProvider authProvider = GoogleAuthProvider();
GoogleSignInAccount? googleSignInAccount;
GoogleSignIn googleSignIn = GoogleSignIn.instance;
GoogleSignInAuthentication? googleSignInAuthentication;
UserCredential? userCredential;
User? user;

DocumentSnapshot? userProfile;
bool isFlutterLocalNotificationsInitialized = false;

Future<DocumentSnapshot> getUserProfile(String uid) async {
  userProfile = await firestore.collection('user').doc(uid).get();
  return await firestore.collection('user').doc(uid).get();
}

String dateFormatter({required DateTime? date, String format = 'yyyy-MM-dd'}) {
  if (date == null) return 'unknown_date';
  return DateFormat(format).format(date);
}
