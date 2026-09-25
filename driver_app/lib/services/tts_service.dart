import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  static final TtsService _instance = TtsService._internal();
  factory TtsService() => _instance;
  TtsService._internal();

  FlutterTts? _flutterTts;
  bool _isInitialized = false;

  Future<void> _ensureInitialized() async {
    if (_isInitialized && _flutterTts != null) return;
    try {
      _flutterTts = FlutterTts();
      await _flutterTts!.setLanguage("en-US");
      await _flutterTts!.setSpeechRate(0.5);
      await _flutterTts!.setVolume(1.0);
      await _flutterTts!.setPitch(1.0);
      await _flutterTts!.awaitSpeakCompletion(false);
      _isInitialized = true;
      debugPrint('[TtsService] Initialized text-to-speech service');
    } catch (e) {
      debugPrint('[TtsService] Initialization error: $e');
    }
  }

  Future<void> speakAction(String action) async {
    final cleanAction = action.trim().toUpperCase().replaceAll('ACTIONTYPE.', '');
    String? message;

    switch (cleanAction) {
      case 'MOVE_LEFT':
        message = 'Emergency vehicle approaching. Move left when safe.';
        break;
      case 'MOVE_RIGHT':
        message = 'Emergency vehicle approaching. Move right when safe.';
        break;
      case 'SLOW_DOWN':
        message = 'Emergency vehicle approaching. Slow down and keep clear.';
        break;
      case 'STAY':
        message = 'Emergency vehicle approaching. Stay in your lane.';
        break;
      default:
        // Do not speak for unrecognized actions or NO_ALERT
        return;
    }

    try {
      await _ensureInitialized();
      if (_flutterTts != null) {
        await _flutterTts!.stop();
        debugPrint('[TtsService] Speaking instruction for action: $cleanAction');
        await _flutterTts!.speak(message);
      }
    } catch (e) {
      debugPrint('[TtsService] Error speaking action ($cleanAction): $e');
    }
  }

  Future<void> stop() async {
    try {
      if (_flutterTts != null) {
        await _flutterTts!.stop();
      }
    } catch (e) {
      debugPrint('[TtsService] Error stopping TTS: $e');
    }
  }
}
