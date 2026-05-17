import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_profile.dart';
import 'firebase_bootstrap.dart';

class LocalBackendService {
  CollectionReference<Map<String, dynamic>> get _accounts =>
      FirebaseFirestore.instance.collection('accounts');

  Future<UserProfile> signUp({
    required String username,
    required String email,
    required String password,
  }) async {
    if (!FirebaseBootstrap.isReady) {
      throw Exception(
        'Firebase is not ready. Configure Firebase before signing up.',
      );
    }

    final String normalizedUsername = username.trim();
    final String normalizedEmail = email.trim().toLowerCase();
    final String authPassword = _authPasswordForInput(password);
    final FirebaseAuth auth = FirebaseAuth.instance;

    try {
      await auth.createUserWithEmailAndPassword(
        email: normalizedEmail,
        password: authPassword,
      );
      await auth.currentUser?.updateDisplayName(normalizedUsername);
    } on FirebaseAuthException catch (e) {
      throw Exception(_mapSignUpAuthError(e));
    }

    final UserProfile profile = UserProfile(
      username: normalizedUsername,
      coins: 300,
      hullLevel: 1,
      cannonLevel: 1,
      friends: <String>[],
    );

    await _accounts.doc(normalizedUsername).set(<String, dynamic>{
      'email': normalizedEmail,
      'authEmail': normalizedEmail,
      'authUid': auth.currentUser?.uid,
      'profile': profile.toJson(),
      'incomingRequests': <String>[],
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return profile;
  }

  Future<UserProfile> login({
    required String username,
    required String password,
  }) async {
    if (!FirebaseBootstrap.isReady) {
      throw Exception(
        'Firebase is not ready. Configure Firebase before logging in.',
      );
    }

    final String normalizedUsername = username.trim();
    final DocumentSnapshot<Map<String, dynamic>> snap = await _accounts
        .doc(normalizedUsername)
        .get();

    if (!snap.exists) {
      throw Exception('No account found for this username.');
    }

    final Map<String, dynamic> data = snap.data() ?? <String, dynamic>{};
    final String authEmail = _readAuthEmail(data);
    if (authEmail.isEmpty) {
      throw Exception('This account is missing a sign-in email.');
    }

    final String authPassword = _authPasswordForInput(password);
    final FirebaseAuth auth = FirebaseAuth.instance;

    try {
      await auth.signInWithEmailAndPassword(
        email: authEmail,
        password: authPassword,
      );
    } on FirebaseAuthException catch (e) {
      throw Exception(_mapLoginAuthError(e));
    }

    if (auth.currentUser == null) {
      throw Exception('Login failed. Please try again.');
    }

    final Map<String, dynamic> profileJson =
        (data['profile'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    return UserProfile.fromJson(profileJson);
  }

  Future<List<String>> getIncomingRequests(String username) async {
    if (!FirebaseBootstrap.isReady || FirebaseAuth.instance.currentUser == null) {
      return <String>[];
    }

    final DocumentSnapshot<Map<String, dynamic>> snap = await _accounts
        .doc(username)
        .get();
    if (!snap.exists) {
      return <String>[];
    }

    final Map<String, dynamic> data = snap.data() ?? <String, dynamic>{};
    return ((data['incomingRequests'] as List<dynamic>?) ?? <dynamic>[])
        .map((dynamic item) => item.toString())
        .toList();
  }

  String _mapLoginAuthError(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-email':
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Invalid username or password.';
      case 'operation-not-allowed':
        return 'Enable Email/Password sign-in in Firebase Authentication.';
      case 'network-request-failed':
        return 'Network error while logging in. Check internet and try again.';
      case 'app-not-authorized':
        return 'This app is not authorized for Firebase Auth. Verify package name and Firebase config files.';
      case 'invalid-api-key':
        return 'Invalid Firebase API key configuration.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'internal-error':
        final String details = error.message ?? '';
        if (details.contains('CONFIGURATION_NOT_FOUND')) {
          return 'Firebase Auth Email/Password configuration missing. In Firebase Console -> Authentication -> Sign-in method, enable Email/Password and try again.';
        }
        return 'Authentication internal error (${error.message ?? 'no details'}).';
      default:
        return error.message ?? 'Login failed. Please try again.';
    }
  }

  String _mapSignUpAuthError(FirebaseAuthException error) {
    switch (error.code) {
      case 'email-already-in-use':
        return 'Username already exists.';
      case 'weak-password':
        return 'Password is too weak.';
      case 'operation-not-allowed':
        return 'Enable Email/Password sign-in in Firebase Authentication.';
      case 'network-request-failed':
        return 'Network error while signing up. Check internet and try again.';
      case 'app-not-authorized':
        return 'This app is not authorized for Firebase Auth. Verify package name and Firebase config files.';
      case 'invalid-api-key':
        return 'Invalid Firebase API key configuration.';
      case 'internal-error':
        final String details = error.message ?? '';
        if (details.contains('CONFIGURATION_NOT_FOUND')) {
          return 'Firebase Auth Email/Password configuration missing. In Firebase Console -> Authentication -> Sign-in method, enable Email/Password and try again.';
        }
        return 'Authentication internal error (${error.message ?? 'no details'}).';
      default:
        return error.message ?? 'Sign up failed. Please try again.';
    }
  }

  String _readAuthEmail(Map<String, dynamic> data) {
    final String authEmail = data['authEmail']?.toString().trim() ?? '';
    if (authEmail.isNotEmpty) {
      return authEmail.toLowerCase();
    }
    return data['email']?.toString().trim().toLowerCase() ?? '';
  }

  String _authPasswordForInput(String password) {
    if (password.length >= 6) {
      return password;
    }

    return '${password}_bb_test_pw';
  }

  Future<void> sendFriendRequest({
    required String fromUsername,
    required String toUsername,
  }) async {
    if (!FirebaseBootstrap.isReady) {
      throw Exception('Firebase is not ready. Configure Firebase first.');
    }

    await FirebaseFirestore.instance.runTransaction((Transaction tx) async {
      final DocumentReference<Map<String, dynamic>> senderRef = _accounts.doc(
        fromUsername,
      );
      final DocumentReference<Map<String, dynamic>> receiverRef = _accounts.doc(
        toUsername,
      );

      final DocumentSnapshot<Map<String, dynamic>> senderSnap = await tx.get(
        senderRef,
      );
      final DocumentSnapshot<Map<String, dynamic>> receiverSnap = await tx.get(
        receiverRef,
      );

      if (!senderSnap.exists || !receiverSnap.exists) {
        throw Exception('Player not found.');
      }
      if (fromUsername == toUsername) {
        throw Exception('You cannot add yourself.');
      }

      final Map<String, dynamic> sender = senderSnap.data() ?? <String, dynamic>{};
      final Map<String, dynamic> receiver = receiverSnap.data() ?? <String, dynamic>{};
      final UserProfile senderProfile = UserProfile.fromJson(
        (sender['profile'] as Map<String, dynamic>?) ?? <String, dynamic>{},
      );

      if (senderProfile.friends.contains(toUsername)) {
        throw Exception('You are already friends.');
      }

      final List<String> incoming =
          ((receiver['incomingRequests'] as List<dynamic>?) ?? <dynamic>[])
              .map((dynamic item) => item.toString())
              .toList();

      if (!incoming.contains(fromUsername)) {
        incoming.add(fromUsername);
        tx.update(receiverRef, <String, dynamic>{
          'incomingRequests': incoming,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  Future<UserProfile> acceptFriendRequest({
    required String currentUser,
    required String requester,
  }) async {
    if (!FirebaseBootstrap.isReady) {
      throw Exception('Firebase is not ready. Configure Firebase first.');
    }

    return FirebaseFirestore.instance.runTransaction((Transaction tx) async {
      final DocumentReference<Map<String, dynamic>> userRef = _accounts.doc(
        currentUser,
      );
      final DocumentReference<Map<String, dynamic>> requesterRef = _accounts.doc(
        requester,
      );

      final DocumentSnapshot<Map<String, dynamic>> userSnap = await tx.get(
        userRef,
      );
      final DocumentSnapshot<Map<String, dynamic>> requesterSnap = await tx.get(
        requesterRef,
      );

      if (!userSnap.exists || !requesterSnap.exists) {
        throw Exception('Account does not exist.');
      }

      final Map<String, dynamic> userData = userSnap.data() ?? <String, dynamic>{};
      final Map<String, dynamic> requesterData = requesterSnap.data() ?? <String, dynamic>{};

      final UserProfile userProfile = UserProfile.fromJson(
        (userData['profile'] as Map<String, dynamic>?) ?? <String, dynamic>{},
      );
      final UserProfile requesterProfile = UserProfile.fromJson(
        (requesterData['profile'] as Map<String, dynamic>?) ?? <String, dynamic>{},
      );

      final List<String> incoming =
          ((userData['incomingRequests'] as List<dynamic>?) ?? <dynamic>[])
              .map((dynamic item) => item.toString())
              .toList();
      incoming.remove(requester);

      final List<String> userFriends = List<String>.from(userProfile.friends);
      final List<String> requesterFriends = List<String>.from(
        requesterProfile.friends,
      );

      if (!userFriends.contains(requester)) {
        userFriends.add(requester);
      }
      if (!requesterFriends.contains(currentUser)) {
        requesterFriends.add(currentUser);
      }

      final UserProfile updatedUser = userProfile.copyWith(friends: userFriends);
      final UserProfile updatedRequester = requesterProfile.copyWith(
        friends: requesterFriends,
      );

      tx.update(userRef, <String, dynamic>{
        'incomingRequests': incoming,
        'profile': updatedUser.toJson(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      tx.update(requesterRef, <String, dynamic>{
        'profile': updatedRequester.toJson(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return updatedUser;
    });
  }

  Future<void> rejectFriendRequest({
    required String currentUser,
    required String requester,
  }) async {
    if (!FirebaseBootstrap.isReady) {
      throw Exception('Firebase is not ready. Configure Firebase first.');
    }

    await FirebaseFirestore.instance.runTransaction((Transaction tx) async {
      final DocumentReference<Map<String, dynamic>> userRef = _accounts.doc(
        currentUser,
      );
      final DocumentSnapshot<Map<String, dynamic>> userSnap = await tx.get(
        userRef,
      );
      if (!userSnap.exists) {
        throw Exception('Account does not exist.');
      }

      final Map<String, dynamic> userData = userSnap.data() ?? <String, dynamic>{};
      final List<String> incoming =
          ((userData['incomingRequests'] as List<dynamic>?) ?? <dynamic>[])
              .map((dynamic item) => item.toString())
              .toList();

      incoming.remove(requester);
      tx.update(userRef, <String, dynamic>{
        'incomingRequests': incoming,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> updateProfile(UserProfile profile) async {
    if (!FirebaseBootstrap.isReady) {
      throw Exception('Firebase is not ready. Configure Firebase first.');
    }

    await _accounts.doc(profile.username).set(<String, dynamic>{
      'profile': profile.toJson(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> resetPassword({
    required String username,
    required String email,
  }) async {
    if (!FirebaseBootstrap.isReady) {
      throw Exception(
        'Firebase is not ready. Configure Firebase before requesting a reset email.',
      );
    }

    final String normalizedUsername = username.trim();
    final String normalizedEmail = email.trim().toLowerCase();
    final DocumentReference<Map<String, dynamic>> doc = _accounts.doc(
      normalizedUsername,
    );
    final DocumentSnapshot<Map<String, dynamic>> snap = await doc.get();

    if (!snap.exists) {
      throw Exception('No account found for this username.');
    }

    final Map<String, dynamic> data = snap.data() ?? <String, dynamic>{};
    final String storedEmail = data['email']?.toString().toLowerCase() ?? '';
    final String authEmail = _readAuthEmail(data);

    if (storedEmail.isEmpty || storedEmail != normalizedEmail) {
      throw Exception('Username and email do not match.');
    }

    if (authEmail.isEmpty || authEmail != storedEmail) {
      throw Exception(
        'This account was created with an older sign-in email and cannot use email reset yet. Please sign in once and update the account to your real email.',
      );
    }

    await FirebaseAuth.instance.sendPasswordResetEmail(email: storedEmail);
  }
}
