import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FavoritesManager extends ChangeNotifier {
  FavoritesManager._internal() {
    _watchAuthState();
  }
  static final FavoritesManager instance = FavoritesManager._internal();

  final List<Map<String, dynamic>> _favorites = [];
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  StreamSubscription<DocumentSnapshot>? _favoritesSub;

  // Maximum number of favorites allowed
  static const int maxFavorites = 50;

  List<Map<String, dynamic>> get favorites => List.unmodifiable(_favorites);

  bool contains(String id) => _favorites.any((v) => v['id'] == id);

  /// Add a video to favorites
  Future<void> addFavorite(Map<String, dynamic> video) async {
    final user = _auth.currentUser;
    if (user == null || video['id'] == null) return;

    if (!contains(video['id']!)) {
      _favorites.insert(0, Map<String, dynamic>.from(video));

      // Enforce limit: remove oldest if exceeding max
      if (_favorites.length > maxFavorites) {
        _favorites.removeLast();
      }

      notifyListeners();

      await _firestore.collection('favorites').doc(user.uid).set({
        'videos': _favorites,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  /// Remove a video from favorites
  Future<void> removeFavorite(String id) async {
    final user = _auth.currentUser;
    if (user == null) return;

    _favorites.removeWhere((v) => v['id'] == id);
    notifyListeners();

    await _firestore.collection('favorites').doc(user.uid).set({
      'videos': _favorites,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Listen for auth changes and switch favorites accordingly
  void _watchAuthState() {
    _auth.authStateChanges().listen((user) {
      // Cancel old subscription if any
      _favoritesSub?.cancel();
      _favorites.clear();
      notifyListeners();

      if (user != null) {
        _listenToFavorites(user.uid);
      }
    });
  }

  /// Listen to Firestore for real-time favorites updates
  void _listenToFavorites(String uid) {
    _favoritesSub =
        _firestore.collection('favorites').doc(uid).snapshots().listen((doc) {
      if (doc.exists) {
        final data = doc.data()!;
        final List<dynamic> fromCloud = data['videos'] ?? [];
        _favorites
          ..clear()
          ..addAll(fromCloud.map((e) => Map<String, dynamic>.from(e)));
      } else {
        _favorites.clear();
      }
      notifyListeners();
    });
  }

  /// Cleanup (optional: call when app closes)
  void disposeManager() {
    _favoritesSub?.cancel();
  }

  isFavorite(String videoUrl) {}

  isDisliked(String videoUrl) {}

  removeDislike(String videoUrl) {}

  addDislike(String videoUrl) {}
}
