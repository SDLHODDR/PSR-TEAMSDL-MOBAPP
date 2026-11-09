import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  TokenStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const _accessTokenKey = 'sdl_access_token';
  static const _accessTokenExpiryKey = 'sdl_access_token_expires_at';
  // Used only to remove credentials left by older app versions. It is never
  // read or written by the JWT-only release.
  static const _legacyRefreshTokenKey = 'sdl_refresh_token';

  final FlutterSecureStorage _storage;

  Future<String?> readAccessToken() => _storage.read(key: _accessTokenKey);

  Future<DateTime?> readAccessTokenExpiry() async {
    final value = await _storage.read(key: _accessTokenExpiryKey);
    if (value == null || value.isEmpty) return null;
    return DateTime.tryParse(value)?.toUtc();
  }

  Future<void> saveAccessToken({
    required String accessToken,
    required DateTime expiresAt,
  }) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(
      key: _accessTokenExpiryKey,
      value: expiresAt.toUtc().toIso8601String(),
    );
  }

  Future<void> clear() async {
    await Future.wait([
      _storage.delete(key: _accessTokenKey),
      _storage.delete(key: _accessTokenExpiryKey),
      _storage.delete(key: _legacyRefreshTokenKey),
    ]);
  }
}
