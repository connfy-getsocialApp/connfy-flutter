import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'dart:convert';

class ContentFilter {
  static final ContentFilter _instance = ContentFilter._internal();
  factory ContentFilter() => _instance;
  ContentFilter._internal();

  late Map<String, dynamic> _bannedWords;
  bool _isInitialized = false;

  Future<void> initialize() async {
    try {
      final data = await rootBundle.loadString('assets/json/banned_words.json');
      _bannedWords = json.decode(data);
      _isInitialized = true;
      debugPrint('ContentFilter initialized with ${_bannedWords.length} categories');
    } catch (e) {
      debugPrint('ContentFilter initialization failed: $e');
      _bannedWords = {};
    }
  }

  String filterMessage(String message) {
    if (!_isInitialized || _bannedWords.isEmpty) return message;

    final allBannedWords = _bannedWords.values
        .expand((list) => List<String>.from(list))
        .toList();

    String filtered = message;
    for (final word in allBannedWords) {
      // Enhanced regex to catch more variations
      final pattern = RegExp(
        r'(^|\W)' + word + r'($|\W)',
        caseSensitive: false,
        multiLine: true,
      );
      filtered = filtered.replaceAllMapped(pattern, (match) {
        // Preserve surrounding whitespace/punctuation
        return '${match.group(1)}***${match.group(2)}';
      });
    }
    return filtered;
  }

  bool isMessageAllowed(String message) {
    if (!_isInitialized) return true;

    final allBannedWords = _bannedWords.values
        .expand((list) => List<String>.from(list))
        .toList();

    final normalized = message.toLowerCase();
    return !allBannedWords.any((word) => normalized.contains(word.toLowerCase()));
  }
}