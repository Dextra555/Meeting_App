import 'package:flutter/material.dart';

class UserProvider with ChangeNotifier {
  Map<String, dynamic>? _userData;
  String? _token;

  Map<String, dynamic>? get userData => _userData;
  String? get token => _token;

  void setUserData(Map<String, dynamic> userData, String authToken) {
    _userData = userData;
    _token = authToken;
    notifyListeners();
  }

  void setUserDataIfExists(Map<String, dynamic>? data, String? token) {
    if (data != null && token != null) {
      _userData = data;
      _token = token;
      notifyListeners();
    }
  }

  void logout() {
    _userData = null;
    _token = null;
    notifyListeners();
  }

  bool get isAdmin {
    if (_userData == null) return false;

    final role = _userData!['role']?.toString().toLowerCase();

    return role == 'admin' || role == 'superadmin' || role == 'ma';
  }

  String? get userId => _userData?['id']?.toString();
  String? get teamId => _userData?['team_id']?.toString();
  String? get userName => _userData?['name']?.toString();
  String? get userRole => _userData?['role']?.toString();
  String? get userEmail => _userData?['email']?.toString();
}
