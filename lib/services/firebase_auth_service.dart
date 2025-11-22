import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:job_seeker_app/models/user.dart' as app_user;

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Get current app user
  Stream<app_user.User?> get userStream {
    return _auth.authStateChanges().asyncMap((User? firebaseUser) async {
      if (firebaseUser == null) return null;

      final doc = await _firestore.collection('users').doc(firebaseUser.uid).get();
      if (doc.exists) {
        return app_user.User.fromJson({
          'id': doc.id,
          ...doc.data()!,
        });
      }
      return null;
    });
  }

  // Register
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String userType,
    String? location,
    String? address,
    String? profileImage,
  }) async {
    try {
      // Create user in Firebase Auth
      final UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create user document in Firestore
      await _firestore.collection('users').doc(credential.user!.uid).set({
        'name': name,
        'email': email,
        'phone': phone,
        'userType': userType,
        'location': location,
        'address': address,
        'profileImage': profileImage,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Update display name
      await credential.user!.updateDisplayName(name);

      return {
        'success': true,
        'message': 'Registration successful',
        'user': app_user.User(
          id: credential.user!.uid,
          name: name,
          email: email,
          phone: phone,
          userType: userType,
          location: location,
          address: address,
          profileImage: profileImage,
        ),
      };
    } on FirebaseAuthException catch (e) {
      return {
        'success': false,
        'message': _getFirebaseAuthErrorMessage(e.code),
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'An error occurred: $e',
      };
    }
  }

  // Login
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Get user data from Firestore
      final doc = await _firestore.collection('users').doc(credential.user!.uid).get();

      if (!doc.exists) {
        return {
          'success': false,
          'message': 'User data not found',
        };
      }

      final userData = doc.data()!;
      return {
        'success': true,
        'message': 'Login successful',
        'user': app_user.User.fromJson({
          'id': doc.id,
          ...userData,
        }),
      };
    } on FirebaseAuthException catch (e) {
      return {
        'success': false,
        'message': _getFirebaseAuthErrorMessage(e.code),
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'An error occurred: $e',
      };
    }
  }

  // Logout
  Future<void> logout() async {
    await _auth.signOut();
  }

  // Get current user data
  Future<app_user.User?> getCurrentUserData() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (!doc.exists) return null;

    return app_user.User.fromJson({
      'id': doc.id,
      ...doc.data()!,
    });
  }

  // Update user profile
  Future<bool> updateProfile({
    String? name,
    String? phone,
    String? location,
    String? address,
    String? profileImage,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final Map<String, dynamic> updates = {};
      if (name != null) updates['name'] = name;
      if (phone != null) updates['phone'] = phone;
      if (location != null) updates['location'] = location;
      if (address != null) updates['address'] = address;
      if (profileImage != null) updates['profileImage'] = profileImage;

      await _firestore.collection('users').doc(user.uid).update(updates);

      if (name != null) {
        await user.updateDisplayName(name);
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  // Get Firebase Auth error messages
  String _getFirebaseAuthErrorMessage(String code) {
    switch (code) {
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'email-already-in-use':
        return 'An account already exists for this email.';
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }
}
