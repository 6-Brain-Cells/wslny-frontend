import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/route_models.dart';

class ChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final RouteResponse? routeResponse;
  final bool showConfirmation;
  final bool isFavorite;

  ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.routeResponse,
    this.showConfirmation = false,
    this.isFavorite = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'isUser': isUser,
      'timestamp': timestamp.toIso8601String(),
      'routeResponse': routeResponse?.toJson(),
      'showConfirmation': showConfirmation,
      'isFavorite': isFavorite,
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      text: json['text'] as String,
      isUser: json['isUser'] as bool,
      timestamp: DateTime.parse(json['timestamp'] as String),
      routeResponse: json['routeResponse'] != null
          ? RouteResponse.fromJson(json['routeResponse'] as Map<String, dynamic>)
          : null,
      showConfirmation: json['showConfirmation'] as bool? ?? false,
      isFavorite: json['isFavorite'] as bool? ?? false,
    );
  }
}

class ChatStorageService {
  static const String _chatHistoryKey = 'chat_history';
  static const String _favoriteRoutesKey = 'favorite_routes';

  // Save chat messages
  static Future<void> saveChatMessages(List<ChatMessage> messages) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final messagesJson = messages.map((m) => m.toJson()).toList();
      await prefs.setString(_chatHistoryKey, jsonEncode(messagesJson));
      print('✅ Chat messages saved successfully');
    } catch (e) {
      print('❌ Failed to save chat messages: $e');
    }
  }

  // Load chat messages
  static Future<List<ChatMessage>> loadChatMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final messagesJson = prefs.getString(_chatHistoryKey);
      
      if (messagesJson != null) {
        final messagesList = jsonDecode(messagesJson) as List<dynamic>;
        return messagesList
            .map((json) => ChatMessage.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      print('❌ Failed to load chat messages: $e');
      return [];
    }
  }

  // Clear chat history
  static Future<void> clearChatHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_chatHistoryKey);
      print('✅ Chat history cleared');
    } catch (e) {
      print('❌ Failed to clear chat history: $e');
    }
  }

  // Save favorite route
  static Future<void> saveFavoriteRoute(RouteResponse routeResponse, String customName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favoritesJson = prefs.getString(_favoriteRoutesKey) ?? '[]';
      final favoritesList = jsonDecode(favoritesJson) as List<dynamic>;
      
      // Check if route already exists
      final existingIndex = favoritesList.indexWhere(
        (fav) => fav['id'] == routeResponse.requestId,
      );
      
      final favoriteData = {
        'id': routeResponse.requestId,
        'customName': customName,
        'routeResponse': routeResponse.toJson(),
        'savedAt': DateTime.now().toIso8601String(),
      };
      
      if (existingIndex != -1) {
        // Update existing favorite
        favoritesList[existingIndex] = favoriteData;
      } else {
        // Add new favorite
        favoritesList.add(favoriteData);
      }
      
      await prefs.setString(_favoriteRoutesKey, jsonEncode(favoritesList));
      print('✅ Favorite route saved: $customName');
    } catch (e) {
      print('❌ Failed to save favorite route: $e');
    }
  }

  // Load favorite routes
  static Future<List<Map<String, dynamic>>> loadFavoriteRoutes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favoritesJson = prefs.getString(_favoriteRoutesKey) ?? '[]';
      final favoritesList = jsonDecode(favoritesJson) as List<dynamic>;
      
      return favoritesList.cast<Map<String, dynamic>>();
    } catch (e) {
      print('❌ Failed to load favorite routes: $e');
      return [];
    }
  }

  // Remove favorite route
  static Future<void> removeFavoriteRoute(String requestId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favoritesJson = prefs.getString(_favoriteRoutesKey) ?? '[]';
      final favoritesList = jsonDecode(favoritesJson) as List<dynamic>;
      
      favoritesList.removeWhere((fav) => fav['id'] == requestId);
      
      await prefs.setString(_favoriteRoutesKey, jsonEncode(favoritesList));
      print('✅ Favorite route removed: $requestId');
    } catch (e) {
      print('❌ Failed to remove favorite route: $e');
    }
  }

  // Check if route is favorite
  static Future<bool> isRouteFavorite(String requestId) async {
    try {
      final favorites = await loadFavoriteRoutes();
      return favorites.any((fav) => fav['id'] == requestId);
    } catch (e) {
      print('❌ Failed to check favorite status: $e');
      return false;
    }
  }
}
