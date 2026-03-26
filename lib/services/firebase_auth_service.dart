import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:job_seeker_app/models/user.dart' as app_user;

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Get current app user
  Stream<app_user.User?> get userStream {
    return _auth.authStateChanges().asyncMap((User? firebaseUser) async {
      if (firebaseUser == null) return null;

      final doc =
          await _firestore.collection('users').doc(firebaseUser.uid).get();
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
    String? location,
    String? address,
    String? profileImage,
    String? gender,
    String? dateOfBirth,
  }) async {
    try {
      // Create user in Firebase Auth
      final UserCredential credential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create user document in Firestore
      final userData = <String, dynamic>{
        'name': name,
        'email': email,
        'phone': phone,
        'location': location,
        'address': address,
        'profileImage': profileImage,
        'gender': gender,
        'dateOfBirth': dateOfBirth,
        'profileCompleted': true,
        'createdAt': FieldValue.serverTimestamp(),
      };
      userData.removeWhere((_, value) => value == null);

      await _firestore
          .collection('users')
          .doc(credential.user!.uid)
          .set(userData);

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
          location: location,
          address: address,
          profileImage: profileImage,
          gender: gender,
          dateOfBirth: dateOfBirth,
          profileCompleted: true,
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

  // Complete a social account profile after the first sign-in.
  Future<bool> completeProfile({
    required String name,
    required String phone,
    String? location,
    String? address,
    String? profileImage,
    String? gender,
    String? dateOfBirth,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final Map<String, dynamic> updates = {
        'name': name,
        'phone': phone,
        'location': location,
        'address': address,
        'profileImage': profileImage,
        'gender': gender,
        'dateOfBirth': dateOfBirth,
        'profileCompleted': true,
      };

      updates.removeWhere((_, value) => value == null);

      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(updates, SetOptions(merge: true));

      await user.updateDisplayName(name);
      return true;
    } catch (e) {
      return false;
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
      final doc =
          await _firestore.collection('users').doc(credential.user!.uid).get();

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

  // Sign in with Google
  Future<Map<String, dynamic>> signInWithGoogle({
    bool forceAccountSelection = false,
  }) async {
    try {
      if (forceAccountSelection) {
        try {
          await _googleSignIn.signOut();
        } catch (_) {}
      }

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        return {
          'success': false,
          'message': 'Google sign-in was cancelled',
        };
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      if (googleAuth.idToken == null) {
        return {
          'success': false,
          'message':
              'Failed to get Google auth token. Check Firebase Google Sign-In setup and google-services.json.',
        };
      }

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);
      final User? firebaseUser = userCredential.user;

      if (firebaseUser == null) {
        return {
          'success': false,
          'message': 'Google sign-in failed',
        };
      }

      await _ensureUserDocument(firebaseUser);

      final doc =
          await _firestore.collection('users').doc(firebaseUser.uid).get();
      if (!doc.exists) {
        return {
          'success': false,
          'message': 'User data not found after Google sign-in',
        };
      }

      final requiresProfileCompletion = await this.requiresProfileCompletion();

      return {
        'success': true,
        'message': 'Google sign-in successful',
        'requiresProfileCompletion': requiresProfileCompletion,
        'user': app_user.User.fromJson({
          'id': doc.id,
          ...doc.data()!,
        }),
      };
    } on FirebaseAuthException catch (e) {
      return {
        'success': false,
        'message': _getFirebaseAuthErrorMessage(e.code),
      };
    } on PlatformException catch (e) {
      final isApi10 = e.code == 'sign_in_failed' &&
          (e.message?.contains('ApiException: 10') ?? false);
      return {
        'success': false,
        'message': isApi10
            ? 'Google Sign-In configuration error (ApiException: 10). Add SHA-1/SHA-256 in Firebase for this app, then download a new google-services.json.'
            : 'Google sign-in failed: ${e.message ?? e.code}',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Google sign-in failed: $e',
      };
    }
  }

  // Sign in with Facebook
  Future<Map<String, dynamic>> signInWithFacebook() async {
    try {
      final LoginResult loginResult = await FacebookAuth.instance.login(
        permissions: const ['email', 'public_profile'],
      );

      switch (loginResult.status) {
        case LoginStatus.success:
          final AccessToken? accessToken = loginResult.accessToken;
          if (accessToken == null || accessToken.tokenString.isEmpty) {
            return {
              'success': false,
              'message': 'Failed to get Facebook access token',
            };
          }

          final OAuthCredential credential = FacebookAuthProvider.credential(
            accessToken.tokenString,
          );

          final UserCredential userCredential =
              await _auth.signInWithCredential(credential);
          final User? firebaseUser = userCredential.user;

          if (firebaseUser == null) {
            return {
              'success': false,
              'message': 'Facebook sign-in failed',
            };
          }

          await _ensureUserDocument(firebaseUser);

          final doc =
              await _firestore.collection('users').doc(firebaseUser.uid).get();
          if (!doc.exists) {
            return {
              'success': false,
              'message': 'User data not found after Facebook sign-in',
            };
          }

          final requiresProfileCompletion =
              await this.requiresProfileCompletion();

          return {
            'success': true,
            'message': 'Facebook sign-in successful',
            'requiresProfileCompletion': requiresProfileCompletion,
            'user': app_user.User.fromJson({
              'id': doc.id,
              ...doc.data()!,
            }),
          };
        case LoginStatus.cancelled:
          return {
            'success': false,
            'message': 'Facebook sign-in was cancelled',
          };
        case LoginStatus.failed:
          final errorMessage = loginResult.message;
          return {
            'success': false,
            'message': (errorMessage == null || errorMessage.isEmpty)
                ? 'Facebook sign-in failed'
                : 'Facebook sign-in failed: $errorMessage',
          };
        case LoginStatus.operationInProgress:
          return {
            'success': false,
            'message': 'Facebook sign-in is already in progress',
          };
      }
    } on FirebaseAuthException catch (e) {
      return {
        'success': false,
        'message': _getFirebaseAuthErrorMessage(e.code),
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Facebook sign-in failed: $e',
      };
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}

    try {
      await FacebookAuth.instance.logOut();
    } catch (_) {}

    await _auth.signOut();
  }

  // Get current user data
  Future<app_user.User?> getCurrentUserData() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) {
        return _firebaseUserToAppUser(user);
      }

      return app_user.User.fromJson({
        'id': doc.id,
        ...doc.data()!,
      });
    } on FirebaseException catch (e) {
      debugPrint(
        'Firestore unavailable while loading current user (${e.code}). Falling back to FirebaseAuth profile.',
      );
      return _firebaseUserToAppUser(user);
    } catch (e) {
      debugPrint(
        'Unexpected error while loading current user. Falling back to FirebaseAuth profile: $e',
      );
      return _firebaseUserToAppUser(user);
    }
  }

  Future<app_user.User?> getUserById(String uid) async {
    if (uid.isEmpty) return null;

    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) {
        return null;
      }

      return app_user.User.fromJson({
        'id': doc.id,
        ...doc.data()!,
      });
    } on FirebaseException catch (e) {
      debugPrint(
        'Firestore unavailable while loading user $uid (${e.code}).',
      );
      return null;
    } catch (e) {
      debugPrint(
        'Unexpected error while loading user $uid: $e',
      );
      return null;
    }
  }

  // Update user profile
  Future<bool> updateProfile({
    String? name,
    String? phone,
    String? location,
    String? address,
    String? profileImage,
    String? gender,
    String? dateOfBirth,
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
      if (gender != null) updates['gender'] = gender;
      if (dateOfBirth != null) updates['dateOfBirth'] = dateOfBirth;

      if (updates.isEmpty) return true;

      await _firestore.collection('users').doc(user.uid).update(updates);

      if (name != null) {
        await user.updateDisplayName(name);
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> requiresProfileCompletion() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) {
        return true;
      }

      final data = doc.data();
      if (data == null) {
        return true;
      }

      if (!data.containsKey('profileCompleted')) {
        return false;
      }

      return data['profileCompleted'] == false;
    } on FirebaseException catch (e) {
      debugPrint(
        'Firestore unavailable while checking profile completion (${e.code}).',
      );
      return false;
    } catch (e) {
      debugPrint(
        'Unexpected error while checking profile completion: $e',
      );
      return false;
    }
  }

  // Ensure a Firestore profile exists for OAuth users.
  Future<void> _ensureUserDocument(User firebaseUser) async {
    final userRef = _firestore.collection('users').doc(firebaseUser.uid);
    final userDoc = await userRef.get();

    final fallbackName = firebaseUser.displayName?.trim();
    final nameToUse = (fallbackName != null && fallbackName.isNotEmpty)
        ? fallbackName
        : 'User';

    if (!userDoc.exists) {
      await userRef.set({
        'name': nameToUse,
        'email': firebaseUser.email ?? '',
        'phone': firebaseUser.phoneNumber ?? '',
        'location': null,
        'address': null,
        'gender': null,
        'dateOfBirth': null,
        'profileImage': firebaseUser.photoURL,
        'profileCompleted': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return;
    }

    final data = userDoc.data() ?? {};
    final Map<String, dynamic> updates = {};

    final currentName = data['name'] as String?;
    final currentEmail = data['email'] as String?;
    final currentPhone = data['phone'] as String?;
    final currentProfileImage = data['profileImage'] as String?;

    if (currentName == null || currentName.trim().isEmpty) {
      updates['name'] = nameToUse;
    }

    if ((currentEmail == null || currentEmail.trim().isEmpty) &&
        firebaseUser.email != null) {
      updates['email'] = firebaseUser.email;
    }

    if ((currentPhone == null || currentPhone.trim().isEmpty) &&
        firebaseUser.phoneNumber != null) {
      updates['phone'] = firebaseUser.phoneNumber;
    }

    if ((currentProfileImage == null || currentProfileImage.trim().isEmpty) &&
        firebaseUser.photoURL != null) {
      updates['profileImage'] = firebaseUser.photoURL;
    }

    if (!data.containsKey('createdAt')) {
      updates['createdAt'] = FieldValue.serverTimestamp();
    }

    if (updates.isNotEmpty) {
      await userRef.update(updates);
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
      case 'account-exists-with-different-credential':
        return 'An account already exists with a different sign-in method.';
      case 'invalid-credential':
        return 'The credential is invalid or has expired.';
      case 'operation-not-allowed':
        return 'This sign-in provider is not enabled in Firebase.';
      case 'network-request-failed':
        return 'Network error. Please check your connection and try again.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }

  app_user.User _firebaseUserToAppUser(User user) {
    return app_user.User(
      id: user.uid,
      name: _fallbackName(user),
      email: user.email ?? '',
      phone: user.phoneNumber ?? '',
      profileImage: user.photoURL,
      location: null,
      address: null,
      gender: null,
      dateOfBirth: null,
      profileCompleted: null,
    );
  }

  String _fallbackName(User user) {
    final displayName = user.displayName?.trim();
    if (displayName != null && displayName.isNotEmpty) {
      return displayName;
    }

    final email = user.email?.trim() ?? '';
    if (email.contains('@')) {
      final localPart = email.split('@').first.trim();
      if (localPart.isNotEmpty) {
        return localPart;
      }
    }

    return 'User';
  }
}
