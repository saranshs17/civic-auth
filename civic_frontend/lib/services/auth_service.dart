import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:uni_links/uni_links.dart';
import '../models/user_model.dart';
import '../models/wallet_model.dart';

class AuthService with ChangeNotifier {
  final FlutterSecureStorage _secureStorage;

  bool _isInitialized = false;
  bool _isLoggedIn = false;
  User? _user;
  Wallet? _wallet;
  String? _error;
  String? _token;
  double? _walletBalance;

  AuthService(this._secureStorage) {
    _initialize();
  }

  bool get isLoggedIn => _isLoggedIn;
  User? get user => _user;
  Wallet? get wallet => _wallet;
  String? get error => _error;
  bool get isInitialized => _isInitialized;
  double? get walletBalance => _walletBalance;

  Future<void> _initialize() async {
    try {
      final token = await _secureStorage.read(key: 'auth_token');
      if (token != null) {
        _token = token;
        await _fetchUserInfo();
        await _fetchWalletBalance();
      }
    } catch (e) {
      _error = 'Initialization failed: $e';
      debugPrint(_error);
    } finally {
      _isInitialized = true;
      notifyListeners();
    }

    _setupDeepLinkListener();

    try {
      final initialUri = await getInitialUri();
      if (initialUri != null) {
        await _handleDeepLink(initialUri);
      }
    } catch (e) {
      debugPrint('Error handling initial URI: $e');
    }
  }

  void _setupDeepLinkListener() {
    uriLinkStream.listen((Uri? uri) async {
      if (uri != null) {
        await _handleDeepLink(uri);
      }
    }, onError: (error) {
      debugPrint('Deep link error: $error');
    });
  }

  Future<void> _handleDeepLink(Uri uri) async {
    debugPrint('Handling deep link: $uri');
    if (uri.path == '/success') {
      final token = uri.queryParameters['token'];
      if (token != null) {
        await _secureStorage.write(key: 'auth_token', value: token);
        _token = token;
        await _fetchUserInfo();
        await _fetchWalletBalance();
        _isLoggedIn = true;
        notifyListeners();
      }
    } else if (uri.path == '/error') {
      _error = uri.queryParameters['message'] ?? 'Authentication failed';
      await _secureStorage.delete(key: 'auth_token');
      _token = null;
      _isLoggedIn = false;
      notifyListeners();
    }
  }

  Future<void> login() async {
    try {
      _error = null;
      notifyListeners();
      const String apiUrl = String.fromEnvironment('API_URL');
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        debugPrint('Login request successful');
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final String? loginUrl = data['loginUrl'] as String?;
        if (loginUrl == null || loginUrl.isEmpty) {
          throw 'Login URL missing from server response: ${response.body}';
        }
        final uri = Uri.parse(loginUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(
            uri,
            mode: LaunchMode.externalApplication,
          );
        } else {
          throw 'Could not launch login URL';
        }
      } else {
        throw Exception('Server returned ${response.statusCode}');
      }
    } catch (e) {
      _error = 'Login failed: $e';
      debugPrint(_error);
      notifyListeners();
    }
  }

  Future<void> logout() async {
    try {
      _error = null;
      await _secureStorage.delete(key: 'auth_token');
      _token = null;
      _isLoggedIn = false;
      _user = null;
      _wallet = null;
      _walletBalance = null;
      notifyListeners();

      final apiUrl = '${dotenv.env['API_URL']}/auth/logout';
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final logoutUrl = data['logoutUrl'];
        if (await canLaunchUrl(Uri.parse(logoutUrl))) {
          await launchUrl(
            Uri.parse(logoutUrl),
            mode: LaunchMode.externalApplication,
          );
        }
      }
    } catch (e) {
      _error = 'Logout failed: $e';
      debugPrint(_error);
      notifyListeners();
    }
  }

  Future<void> _fetchUserInfo() async {
    try {
      _error = null;
      if (_token == null) {
        throw 'No authentication token';
      }
      final apiUrl = '${dotenv.env['API_URL']}/api/user';
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {'Authorization': 'Bearer $_token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _user = User.fromJson(data['user']);
        _wallet = data['user']['wallet'] != null ? Wallet.fromJson(data['user']['wallet']) : null;
        _isLoggedIn = true;
      } else if (response.statusCode == 401) {
        await _secureStorage.delete(key: 'auth_token');
        _token = null;
        _isLoggedIn = false;
        _user = null;
        _wallet = null;
        _walletBalance = null;
      } else {
        throw 'Failed to fetch user info: ${response.statusCode}';
      }
    } catch (e) {
      _error = 'Failed to fetch user info: $e';
      debugPrint(_error);
    } finally {
      notifyListeners();
    }
  }

  Future<void> _fetchWalletBalance() async {
    try {
      if (_token == null) return;
      final apiUrl = '${dotenv.env['API_URL']}/api/wallet/balance';
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {'Authorization': 'Bearer $_token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _walletBalance = data['balance']?.toDouble() ?? 0.0;
      }
    } catch (e) {
      debugPrint('Failed to fetch wallet balance: $e');
    } finally {
      notifyListeners();
    }
  }

  Future<void> refreshUserData() async {
    if (_isLoggedIn) {
      await _fetchUserInfo();
      await _fetchWalletBalance();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}