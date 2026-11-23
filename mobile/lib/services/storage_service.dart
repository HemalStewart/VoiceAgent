import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _keyBaseUrl = 'server_base_url';
  static const String _keyPersona = 'selected_persona';
  static const String _keyMode = 'selected_mode';

  static String getDefaultBaseUrl() {
    if (kIsWeb) {
      return 'http://localhost:8000';
    }
    if (Platform.isAndroid) {
      // Android emulator reaches host machine on 10.0.2.2
      return 'http://10.0.2.2:8000';
    }
    // iOS simulator or macOS desktop reaches host on localhost
    return 'http://localhost:8000';
  }

  Future<String> getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyBaseUrl) ?? getDefaultBaseUrl();
  }

  Future<void> setBaseUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    // Normalize url: remove trailing slash
    String normalized = url.trim();
    if (normalized.endsWith('/')) {
      normalized = normalized.substring(0, normalized.length - 1);
    }
    await prefs.setString(_keyBaseUrl, normalized);
  }

  Future<String> getPersona() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyPersona) ?? 'emma';
  }

  Future<void> setPersona(String personaId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPersona, personaId);
  }

  Future<String> getMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyMode) ?? 'free_chat';
  }

  Future<void> setMode(String modeId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyMode, modeId);
  }
}
