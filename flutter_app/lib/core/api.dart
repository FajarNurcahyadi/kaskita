import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiException implements Exception {
  final String message;
  final int? status;
  final Map<String, dynamic>? body;
  ApiException(this.message, {this.status, this.body});
  @override
  String toString() => message;
}

class Api {
  /// Emulator Android -> 10.0.2.2, iOS simulator/web -> localhost.
  /// HP fisik: pakai IP laptop lu, mis.
  ///   flutter run --dart-define=API_URL=http://192.168.1.10:3000
  static const _override = String.fromEnvironment('API_URL');
  static String get baseUrl {
    if (_override.isNotEmpty) return _override;
    if (!kIsWeb && Platform.isAndroid) return 'http://10.0.2.2:3000';
    return 'http://localhost:3000';
  }

  static Future<Map<String, dynamic>> _post(
      String path, Map<String, dynamic> data) async {
    try {
      final res = await http
          .post(Uri.parse('$baseUrl$path'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(data))
          .timeout(const Duration(seconds: 15));
      final body = res.body.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode >= 400) {
        throw ApiException(body['message']?.toString() ?? 'Terjadi kesalahan',
            status: res.statusCode, body: body);
      }
      return body;
    } on ApiException {
      rethrow;
    } on FormatException {
      throw ApiException(
          'Server membalas dengan data tak terduga. Kemungkinan backend belum di-update: jalankan "docker compose up -d --build api".');
    } catch (_) {
      throw ApiException(
          'Tidak bisa terhubung ke server. Pastikan backend Docker sudah jalan.');
    }
  }

  static Future<void> register(String name, String email, String password) =>
      _post('/auth/register',
          {'name': name, 'email': email, 'password': password});

  static Future<void> verifyOtp(String email, String code) async {
    final r = await _post('/auth/verify-otp', {'email': email, 'code': code});
    await _saveToken(r['token'] as String);
  }

  static Future<String> verifyResetOtp(String email, String code) async {
    final r =
        await _post('/auth/verify-reset-otp', {'email': email, 'code': code});
    return r['resetToken'] as String;
  }

  static Future<void> resendOtp(String email, String purpose) =>
      _post('/auth/resend-otp', {'email': email, 'purpose': purpose});

  static Future<void> login(String email, String password) async {
    final r =
        await _post('/auth/login', {'email': email, 'password': password});
    await _saveToken(r['token'] as String);
  }

  static Future<void> forgotPassword(String email) =>
      _post('/auth/forgot-password', {'email': email});

  static Future<void> resetPassword(String resetToken, String newPassword) =>
      _post('/auth/reset-password',
          {'resetToken': resetToken, 'newPassword': newPassword});

  static Future<void> _saveToken(String token) async {
    final p = await SharedPreferences.getInstance();
    await p.setString('token', token);
  }

  static Future<String?> token() async =>
      (await SharedPreferences.getInstance()).getString('token');

  static Future<void> logout() async =>
      (await SharedPreferences.getInstance()).remove('token');

  /// Dipanggil saat token ditolak server (401). Di-set di main.dart.
  static void Function()? onUnauthorized;

  static Future<Map<String, dynamic>> _authed(String method, String path,
      {Map<String, dynamic>? body, Map<String, String>? query}) async {
    final token = await Api.token();
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: query);
    final headers = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
    try {
      final http.Response res;
      switch (method) {
        case 'POST':
          res = await http.post(uri,
              headers: headers, body: jsonEncode(body ?? {}));
          break;
        case 'PUT':
          res = await http.put(uri,
              headers: headers, body: jsonEncode(body ?? {}));
          break;
        case 'DELETE':
          res = await http.delete(uri, headers: headers);
          break;
        default:
          res = await http.get(uri, headers: headers);
      }
      final decoded = res.body.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 401) {
        await logout();
        onUnauthorized?.call();
        throw ApiException('Sesi berakhir, silakan login lagi', status: 401);
      }
      if (res.statusCode >= 400) {
        throw ApiException(
            decoded['message']?.toString() ?? 'Terjadi kesalahan',
            status: res.statusCode);
      }
      return decoded;
    } on ApiException {
      rethrow;
    } on FormatException {
      throw ApiException(
          'Server membalas dengan data tak terduga. Kemungkinan backend belum di-update: jalankan "docker compose up -d --build api".');
    } catch (_) {
      throw ApiException(
          'Tidak bisa terhubung ke server. Pastikan backend Docker sudah jalan.');
    }
  }

  static Future<Map<String, dynamic>> dashboard(String today) =>
      _authed('GET', '/dashboard', query: {'today': today});

  static Future<List<Map<String, dynamic>>> targets() async {
    final response = await _authed('GET', '/targets');
    return (response['items'] as List).cast<Map<String, dynamic>>();
  }

  static Future<Map<String, dynamic>> createTarget({
    required String name,
    required int targetAmount,
    required String deadline,
    int initialAmount = 0,
  }) async {
    final response = await _authed('POST', '/targets', body: {
      'name': name,
      'targetAmount': targetAmount,
      'initialAmount': initialAmount,
      'deadline': deadline,
    });
    return response['target'] as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> targetDetail(int id) =>
      _authed('GET', '/targets/$id');

  static Future<Map<String, dynamic>> depositToTarget(
    int id, {
    required int amount,
    String note = '',
  }) =>
      _authed('POST', '/targets/$id/deposits',
          body: {'amount': amount, 'note': note});

  static Future<Map<String, dynamic>> withdrawFromTarget(
    int id, {
    required int amount,
    String note = '',
  }) =>
      _authed('POST', '/targets/$id/withdrawals',
          body: {'amount': amount, 'note': note});

  static Future<Map<String, dynamic>> transactions(String month,
          {String type = 'all'}) =>
      _authed('GET', '/transactions', query: {'month': month, 'type': type});

  static Future<void> addTransaction({
    required String type,
    required int amount,
    required String category,
    required String date,
    String note = '',
  }) =>
      _authed('POST', '/transactions', body: {
        'type': type,
        'amount': amount,
        'category': category,
        'date': date,
        'note': note
      });

  static Future<void> deleteTransaction(int id) =>
      _authed('DELETE', '/transactions/$id');

  // ---------------- Komunitas ----------------
  static String imageUrl(String path) =>
      path.startsWith('http') ? path : '$baseUrl$path';

  static Future<List<Map<String, dynamic>>> posts({String q = ''}) async {
    final r =
        await _authed('GET', '/posts', query: q.isEmpty ? null : {'q': q});
    return (r['items'] as List).cast<Map<String, dynamic>>();
  }

  static Future<Map<String, dynamic>> postDetail(int id) =>
      _authed('GET', '/posts/$id');

  static Future<void> createPost(String body, {List<int>? imageBytes}) =>
      _authed('POST', '/posts', body: {
        'body': body,
        if (imageBytes != null) 'imageBase64': base64Encode(imageBytes)
      });

  static Future<void> deletePost(int id) => _authed('DELETE', '/posts/$id');

  static Future<Map<String, dynamic>> toggleLike(int id) =>
      _authed('POST', '/posts/$id/like');

  static Future<void> addComment(int id, String body) =>
      _authed('POST', '/posts/$id/comments', body: {'body': body});

  static Future<void> deleteComment(int id) =>
      _authed('DELETE', '/comments/$id');

  // ---------------- Profil & keamanan ----------------
  static Future<void> verifyLoginOtp(String email, String code) async {
    final r =
        await _post('/auth/verify-login-otp', {'email': email, 'code': code});
    await _saveToken(r['token'] as String);
  }

  static Future<Map<String, dynamic>> profile() => _authed('GET', '/profile');

  static Future<Map<String, dynamic>> updateProfile(
          Map<String, dynamic> data) =>
      _authed('PUT', '/profile', body: data);

  static Future<void> changePassword(String current, String next) =>
      _authed('POST', '/profile/password',
          body: {'currentPassword': current, 'newPassword': next});

  static Future<void> setPin(String pin, {String? currentPin}) =>
      _authed('POST', '/profile/pin',
          body: {'pin': pin, if (currentPin != null) 'currentPin': currentPin});

  static Future<Map<String, dynamic>> updateSecurity(
          {bool? biometric, bool? twoFactor}) =>
      _authed('PUT', '/profile/security', body: {
        if (biometric != null) 'biometric': biometric,
        if (twoFactor != null) 'twoFactor': twoFactor
      });

  static Future<List<Map<String, dynamic>>> logins() async {
    final r = await _authed('GET', '/profile/logins');
    return (r['items'] as List).cast<Map<String, dynamic>>();
  }

  static Future<void> deleteAccount(String password, {String? pin}) async {
    await _authed('POST', '/profile/delete',
        body: {'password': password, if (pin != null) 'pin': pin});
    await logout();
  }
}
