import 'package:flutter/material.dart';
import 'package:wslny/config/routes.dart';
import 'package:wslny/models/route_models.dart';
import 'package:wslny/services/location_service.dart';
import 'package:wslny/services/route_service.dart';
import 'package:wslny/services/chat_storage_service.dart';
import 'package:speech_to_text/speech_to_text.dart';

class ChatbotPage extends StatefulWidget {
  const ChatbotPage({super.key});

  @override
  State<ChatbotPage> createState() => _ChatbotPageState();
}

class _ChatbotPageState extends State<ChatbotPage> {
  final SpeechToText _speechToText = SpeechToText();
  final RouteService _routeService = RouteService();
  final LocationService _locationService = LocationService();
  final TextEditingController _textController = TextEditingController();
  final List<ChatMessage> _messages = [];

  bool _speechEnabled = false;
  bool _isListening = false;
  bool _isProcessingRoute = false;
  String _lastWords = '';
  double? _currentLat;
  double? _currentLng;

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _loadChatHistory();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    final pos = await _locationService.getCurrentPosition();
    if (mounted && pos != null) {
      setState(() {
        _currentLat = pos.latitude;
        _currentLng = pos.longitude;
      });
    }
  }

  Future<void> _loadChatHistory() async {
    final savedMessages = await ChatStorageService.loadChatMessages();
    if (mounted) {
      setState(() {
        _messages.clear();
        _messages.addAll(savedMessages);
      });

      // Add welcome message if chat is empty
      if (_messages.isEmpty) {
        _addBotMessage(
          'Hi! I can help you find the best routes and nearby stations. You can ask me things like:\n\n• "من مصر الجديدة إلى وسط البلد"\n• "How to get from Zamalek to Maadi"\n• "Route from airport to downtown"\n\nWhat do you need today?',
        );
      }
    }
  }

  Future<void> _saveChatHistory() async {
    await ChatStorageService.saveChatMessages(_messages);
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _initSpeech() async {
    _speechEnabled = await _speechToText.initialize(
      onError: (val) => debugPrint('Error: $val'),
      onStatus: (val) => debugPrint('Status: $val'),
    );
    setState(() {});
  }

  void _startListening() async {
    if (_speechEnabled) {
      await _speechToText.listen(
        onResult: (result) {
          setState(() {
            _lastWords = result.recognizedWords;
            _textController.text = _lastWords;
          });
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        localeId: 'ar_SA', // Arabic locale
      );
      setState(() {
        _isListening = true;
      });
    }
  }

  void _stopListening() async {
    await _speechToText.stop();
    setState(() {
      _isListening = false;
    });
  }

  void _addBotMessage(String text) {
    final message = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      isUser: false,
      timestamp: DateTime.now(),
    );
    setState(() {
      _messages.add(message);
    });
    _saveChatHistory();
  }

  void _addUserMessage(String text) {
    final message = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    );
    setState(() {
      _messages.add(message);
    });
    _saveChatHistory();
  }

  void _navigateToRouteResults(RouteResponse routeResponse) {
    Navigator.pushNamed(
      context,
      AppRoutes.routeResults,
      arguments: routeResponse,
    );
  }

  void _cancelRoute() {
    _addBotMessage('Route cancelled. Feel free to ask for a different route!');
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _isProcessingRoute) return;

    _addUserMessage(text);
    _textController.clear();

    // Show route filter selection dialog
    final filter = await _showRouteFilterDialog();
    if (filter == null) {
      _addBotMessage('Route request cancelled. Feel free to ask again!');
      return;
    }

    setState(() {
      _isProcessingRoute = true;
    });

    _addBotMessage(
      'Looking for the best route with ${filter.displayName} preference...',
    );

    try {
      final routeResponse = await _routeService.getRouteByText(
        text: text,
        filter: filter,
        currentLatitude: _currentLat,
        currentLongitude: _currentLng,
      );

      // Show confirmation message with Yes/No buttons
      _addBotMessage(
        'I found a route from "${routeResponse.fromName ?? 'Start Location'}" "" to "${routeResponse.toName ?? 'Destination'}":\n\n'
        '🕐 Duration: ${routeResponse.route?.totalDurationFormatted ?? 'N/A'}\n'
        '📍 Distance: ${routeResponse.route?.totalDistanceMeters ?? 0}m\n'
        '💰 Fare: ${routeResponse.route?.estimatedFareFormatted ?? 'N/A'}\n'
        '🚌 Segments: ${routeResponse.route?.segments.length ?? 0}\n\n'
        'Is this the correct route?',
      );

      // Add confirmation message with Yes/No buttons
      final confirmationMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: 'Route Confirmation',
        isUser: false,
        timestamp: DateTime.now(),
        routeResponse: routeResponse,
        showConfirmation: true,
      );
      setState(() {
        _messages.add(confirmationMessage);
      });
      await _saveChatHistory();
    } catch (e) {
      _addBotMessage(
        'Sorry, I couldn\'t find a route for that request. Please try rephrasing your question or check if the locations are correct.',
      );
      debugPrint('Route request error: $e');
    } finally {
      setState(() {
        _isProcessingRoute = false;
      });
    }
  }

  Future<RouteFilter?> _showRouteFilterDialog() async {
    return showDialog<RouteFilter>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Route Preference'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: RouteFilter.values.map((filter) {
            return ListTile(
              title: Text(filter.displayName),
              subtitle: Text(_getFilterDescription(filter)),
              onTap: () => Navigator.of(context).pop(filter),
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  String _getFilterDescription(RouteFilter filter) {
    switch (filter) {
      case RouteFilter.optimal:
        return 'Best balance of time, cost, and comfort';
      case RouteFilter.fastest:
        return 'Shortest travel time';
      case RouteFilter.cheapest:
        return 'Lowest cost option';
      case RouteFilter.busOnly:
        return 'Use buses only';
      case RouteFilter.microbusOnly:
        return 'Use microbuses only';
      case RouteFilter.metroOnly:
        return 'Use metro/subway only';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.chat_bubble_outline,
                  size: 18,
                  color: theme.colorScheme.onPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Text('Wslny', style: TextStyle(color: theme.colorScheme.onSurface)),
            ],
          ),
          centerTitle: false,
          actions: const [],
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  return message.isUser
                      ? _UserBubble(text: message.text)
                      : message.showConfirmation
                      ? _ConfirmationBubble(
                          routeResponse: message.routeResponse!,
                          onYes: () =>
                              _navigateToRouteResults(message.routeResponse!),
                          onNo: () => _cancelRoute(),
                        )
                      : message.routeResponse != null
                      ? _RouteBubble(
                          routeResponse: message.routeResponse!,
                          onTap: () => Navigator.pushNamed(
                            context,
                            AppRoutes.routeResults,
                            arguments: message.routeResponse,
                          ),
                        )
                      : _BotBubble(text: message.text);
                },
              ),
            ),
            _ChatInputBar(
              controller: _textController,
              isListening: _isListening,
              speechEnabled: _speechEnabled,
              isProcessing: _isProcessingRoute,
              onStartListening: _startListening,
              onStopListening: _stopListening,
              onSend: _sendMessage,
            ),
          ],
        ),
      ),
    );
  }
}

class _BotBubble extends StatelessWidget {
  final String text;

  const _BotBubble({required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          text,
          style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface),
        ),
      ),
    );
  }
}

class _UserBubble extends StatelessWidget {
  final String text;

  const _UserBubble({required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          text,
          style: const TextStyle(fontSize: 13, color: Colors.white),
        ),
      ),
    );
  }
}

class _RouteBubble extends StatelessWidget {
  final RouteResponse routeResponse;
  final VoidCallback onTap;

  const _RouteBubble({required this.routeResponse, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final route = routeResponse.route;
    final fromName = routeResponse.fromName ?? 'Origin';
    final toName = routeResponse.toName ?? 'Destination';

    return Align(
      alignment: Alignment.centerLeft,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.colorScheme.primary.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.route, color: theme.colorScheme.primary, size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'from: $fromName to: $toName',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _RouteInfoItem(
                    icon: Icons.access_time,
                    text: route?.totalDurationFormatted ?? 'N/A',
                  ),
                  const SizedBox(width: 12),
                  _RouteInfoItem(
                    icon: Icons.attach_money,
                    text: route?.estimatedFareFormatted ?? 'N/A',
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'View Details',
                  style: TextStyle(
                    color: theme.colorScheme.onPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RouteInfoItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _RouteInfoItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: theme.colorScheme.primary),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withOpacity(0.7)),
        ),
      ],
    );
  }
}

class _ChatInputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool isListening;
  final bool speechEnabled;
  final bool isProcessing;
  final VoidCallback onStartListening;
  final VoidCallback onStopListening;
  final VoidCallback onSend;

  const _ChatInputBar({
    required this.controller,
    required this.isListening,
    required this.speechEnabled,
    required this.isProcessing,
    required this.onStartListening,
    required this.onStopListening,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              enabled: !isProcessing,
              style: TextStyle(color: theme.colorScheme.onSurface),
              decoration: InputDecoration(
                hintText: isProcessing
                    ? 'Processing your request...'
                    : 'Ask about routes or stations...',
                hintStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5)),
                fillColor: isDark ? const Color(0xFF0F1A1C) : Colors.white,
                filled: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: theme.dividerColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: theme.dividerColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(
                    color: theme.colorScheme.primary,
                    width: 1.5,
                  ),
                ),
              ),
              onSubmitted: (_) => onSend(),
            ),
          ),
          const SizedBox(height: 0, width: 8),
          if (speechEnabled)
            GestureDetector(
              onTap: isListening ? onStopListening : onStartListening,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isListening ? const Color(0xFFEF9A9A) : theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isListening ? Icons.stop : Icons.mic,
                  size: 20,
                  color: theme.colorScheme.onPrimary,
                ),
              ),
            ),
          if (!speechEnabled)
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.mic_off, size: 20, color: theme.colorScheme.onSurface.withOpacity(0.5)),
            ),
          const SizedBox(height: 0, width: 8),
          GestureDetector(
            onTap: isProcessing ? null : onSend,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isProcessing ? theme.colorScheme.onSurface.withOpacity(0.2) : theme.colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: isProcessing
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: theme.colorScheme.onPrimary,
                      ),
                    )
                  : Icon(
                      Icons.send_rounded,
                      size: 20,
                      color: theme.colorScheme.onPrimary,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfirmationBubble extends StatefulWidget {
  final RouteResponse routeResponse;
  final VoidCallback onYes;
  final VoidCallback onNo;

  const _ConfirmationBubble({
    required this.routeResponse,
    required this.onYes,
    required this.onNo,
  });

  @override
  State<_ConfirmationBubble> createState() => _ConfirmationBubbleState();
}

class _ConfirmationBubbleState extends State<_ConfirmationBubble> {
  bool _isFavorite = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _checkFavoriteStatus();
  }

  Future<void> _checkFavoriteStatus() async {
    final isFavorite = await ChatStorageService.isRouteFavorite(
      widget.routeResponse.requestId,
    );
    if (mounted) {
      setState(() {
        _isFavorite = isFavorite;
      });
    }
  }

  Future<void> _toggleFavorite() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final routeName =
          'from: ${widget.routeResponse.fromName ?? "Start"} to: ${widget.routeResponse.toName ?? "Destination"}';

      if (_isFavorite) {
        await ChatStorageService.removeFavoriteRoute(
          widget.routeResponse.requestId,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Route removed from favorites')),
          );
        }
      } else {
        await ChatStorageService.saveFavoriteRoute(
          widget.routeResponse,
          routeName,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Route added to favorites')),
          );
        }
      }

      if (mounted) {
        setState(() {
          _isFavorite = !_isFavorite;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update favorites')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final route = widget.routeResponse.route;
    final fromName = widget.routeResponse.fromName ?? 'Origin';
    final toName = widget.routeResponse.toName ?? 'Destination';

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.colorScheme.primary.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.help_outline, color: theme.colorScheme.primary, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Confirm Route',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _isSaving ? null : _toggleFavorite,
                  icon: _isSaving
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: theme.colorScheme.primary,
                          ),
                        )
                      : Icon(
                          _isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: _isFavorite ? const Color(0xFFEF9A9A) : theme.colorScheme.primary,
                          size: 20,
                        ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'from: $fromName to: $toName',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                _RouteInfoItem(
                  icon: Icons.access_time,
                  text: route?.totalDurationFormatted ?? 'N/A',
                ),
                const SizedBox(width: 12),
                _RouteInfoItem(
                  icon: Icons.attach_money,
                  text: route?.estimatedFareFormatted ?? 'N/A',
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: widget.onNo,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: theme.colorScheme.primary.withOpacity(0.5),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    child: Text(
                      'No',
                      style: TextStyle(color: theme.colorScheme.primary, fontSize: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    onPressed: widget.onYes,
                    style: FilledButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    child: Text(
                      'Yes',
                      style: TextStyle(color: theme.colorScheme.onPrimary, fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
