import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ── Providers ──────────────────────────────────────

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(
    ref.watch(firebaseAuthProvider),
    FirebaseFirestore.instance,
  );
});

final inviteCodeProvider = FutureProvider<String?>((ref) async {
  return ref.watch(authServiceProvider).getInviteCode();
});

/// Streams the household ID for the currently logged-in user.
/// Returns null if the user has no household yet.
final householdIdProvider = StreamProvider<String?>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value(null);

  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .snapshots()
      .map((snap) => snap.data()?['householdId'] as String?);
});

// ── Service ───────────────────────────────────────

class AuthService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  AuthService(this._auth, this._db);

  User? get currentUser => _auth.currentUser;

  /// Register with email + password.
  Future<UserCredential> register(String email, String password) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Sign in with email + password.
  Future<UserCredential> signIn(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Sign out.
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Create a new household for the current user.
  /// Returns the generated invite code.
  Future<String> createHousehold() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Utente non autenticato');

    final inviteCode = _generateInviteCode();
    final householdRef = _db.collection('households').doc();

    await _db.runTransaction((tx) async {
      tx.set(householdRef, {
        'members': [user.uid],
        'inviteCode': inviteCode,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': user.uid,
      });
      tx.set(_db.collection('users').doc(user.uid), {
        'householdId': householdRef.id,
        'email': user.email,
        'joinedAt': FieldValue.serverTimestamp(),
      });
    });

    return inviteCode;
  }

  /// Join a household using an invite code.
  Future<void> joinHousehold(String inviteCode) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Utente non autenticato');

    final code = inviteCode.trim().toUpperCase();
    final query = await _db
        .collection('households')
        .where('inviteCode', isEqualTo: code)
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      throw Exception('Codice invito non valido');
    }

    final householdDoc = query.docs.first;

    await _db.runTransaction((tx) async {
      tx.update(householdDoc.reference, {
        'members': FieldValue.arrayUnion([user.uid]),
      });
      tx.set(_db.collection('users').doc(user.uid), {
        'householdId': householdDoc.id,
        'email': user.email,
        'joinedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  /// Get the invite code for the current user's household.
  Future<String?> getInviteCode() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final userDoc = await _db.collection('users').doc(user.uid).get();
    final householdId = userDoc.data()?['householdId'] as String?;
    if (householdId == null) return null;

    final householdDoc =
        await _db.collection('households').doc(householdId).get();
    return householdDoc.data()?['inviteCode'] as String?;
  }

  /// Leave the current household.
  Future<void> leaveHousehold() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final userDoc = await _db.collection('users').doc(user.uid).get();
    final householdId = userDoc.data()?['householdId'] as String?;
    if (householdId == null) return;

    await _db.runTransaction((tx) async {
      tx.update(_db.collection('households').doc(householdId), {
        'members': FieldValue.arrayRemove([user.uid]),
      });
      tx.update(_db.collection('users').doc(user.uid), {
        'householdId': FieldValue.delete(),
      });
    });
  }

  String _generateInviteCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rng = Random.secure();
    return List.generate(6, (_) => chars[rng.nextInt(chars.length)]).join();
  }
}
