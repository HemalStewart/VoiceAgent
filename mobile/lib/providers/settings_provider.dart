import 'package:flutter/material.dart';
import '../models/tutor_persona.dart';
import '../models/lesson_mode.dart';
import '../services/storage_service.dart';
import '../services/api_service.dart';

class SettingsProvider extends ChangeNotifier {
  final StorageService _storageService;
  final ApiService _apiService;

  String _baseUrl = '';
  TutorPersona _selectedPersona = TutorPersona.all.first;
  LessonMode _selectedMode = LessonMode.all.first;

  bool _isCheckingConnection = false;
  bool _isConnected = false;
  String? _connectionError;
  Map<String, dynamic>? _serverHealthInfo;

  SettingsProvider({
    StorageService? storageService,
    ApiService? apiService,
  })  : _storageService = storageService ?? StorageService(),
        _apiService = apiService ?? ApiService() {
    _loadSettings();
  }

  String get baseUrl => _baseUrl;
  TutorPersona get selectedPersona => _selectedPersona;
  LessonMode get selectedMode => _selectedMode;
  bool get isCheckingConnection => _isCheckingConnection;
  bool get isConnected => _isConnected;
  String? get connectionError => _connectionError;
  Map<String, dynamic>? get serverHealthInfo => _serverHealthInfo;

  Future<void> _loadSettings() async {
    _baseUrl = await _storageService.getBaseUrl();
    final personaId = await _storageService.getPersona();
    final modeId = await _storageService.getMode();

    _selectedPersona = TutorPersona.fromId(personaId);
    _selectedMode = LessonMode.fromId(modeId);

    notifyListeners();
    checkConnection();
  }

  Future<void> setBaseUrl(String url) async {
    _baseUrl = url.trim();
    await _storageService.setBaseUrl(_baseUrl);
    notifyListeners();
    checkConnection();
  }

  Future<void> setPersona(TutorPersona persona) async {
    _selectedPersona = persona;
    await _storageService.setPersona(persona.id);
    notifyListeners();
  }

  Future<void> setMode(LessonMode mode) async {
    _selectedMode = mode;
    await _storageService.setMode(mode.id);
    notifyListeners();
  }

  Future<bool> checkConnection() async {
    _isCheckingConnection = true;
    _connectionError = null;
    notifyListeners();

    final response = await _apiService.checkHealth();
    _isCheckingConnection = false;

    if (response.success && response.data != null) {
      _isConnected = true;
      _serverHealthInfo = response.data;
      _connectionError = null;
    } else {
      _isConnected = false;
      _serverHealthInfo = null;
      _connectionError = response.error ?? 'Unknown connection error';
    }

    notifyListeners();
    return _isConnected;
  }
}
