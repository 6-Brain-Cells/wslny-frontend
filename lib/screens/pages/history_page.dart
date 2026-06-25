import 'package:flutter/material.dart';
import 'package:wslny/models/route_addon_models.dart';
import 'package:wslny/models/route_models.dart';
import 'package:wslny/services/route_service.dart';
import 'route_results_page.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final RouteService _routeService = RouteService();
  List<RouteHistoryItem> _historyItems = [];
  bool _isLoading = true;
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final items = await _routeService.getRouteHistory();
      setState(() {
        _historyItems = items;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading route history: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<RouteHistoryItem> get _filteredItems {
    if (_searchQuery.isEmpty) return _historyItems;
    return _historyItems.where((item) {
      final origin = item.originName?.toLowerCase() ?? '';
      final destination = item.destinationName?.toLowerCase() ?? '';
      final input = item.inputText?.toLowerCase() ?? '';
      return origin.contains(_searchQuery.toLowerCase()) ||
          destination.contains(_searchQuery.toLowerCase()) ||
          input.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  RouteFilter _parseFilter(String filter) {
    switch (filter) {
      case '1': return RouteFilter.optimal;
      case '2': return RouteFilter.fastest;
      case '3': return RouteFilter.cheapest;
      case '4': return RouteFilter.busOnly;
      case '5': return RouteFilter.microbusOnly;
      case '6': return RouteFilter.metroOnly;
      default: return RouteFilter.optimal;
    }
  }

  Future<void> _navigateToRoute(RouteHistoryItem item) async {
    final text = item.inputText;
    if (text == null || text.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cannot load route: no search query available')),
        );
      }
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final filter = _parseFilter(item.filter);
      final routeResponse = await _routeService.getRouteByText(
        text: text,
        filter: filter,
      );

      if (mounted) {
        Navigator.pop(context); // dismiss loading
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RouteResultsPage(routeResponse: routeResponse),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error fetching route from history: $e');
      if (mounted) {
        Navigator.pop(context); // dismiss loading
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load route. Please try again.')),
        );
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Text(
                  'History',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_historyItems.length} routes',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _SearchBar(
              hint: 'Search route history...',
              onChanged: (query) {
                setState(() {
                  _searchQuery = query;
                });
              },
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: theme.colorScheme.primary))
                : _filteredItems.isEmpty
                ? const _EmptyHistory()
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                    children: _filteredItems
                        .map(
                          (item) => _HistoryCard(
                            item: item,
                            onTap: () => _navigateToRoute(item),
                          ),
                        )
                        .toList(),
                  ),
          ),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final String hint;
  final ValueChanged<String>? onChanged;

  const _SearchBar({required this.hint, this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          Icon(Icons.search, size: 20, color: theme.colorScheme.onSurface.withOpacity(0.5)),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              style: TextStyle(color: theme.colorScheme.onSurface),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.4)),
                border: InputBorder.none,
                isDense: true,
              ),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final RouteHistoryItem item;
  final VoidCallback onTap;

  const _HistoryCard({required this.item, required this.onTap});

  String _formatDuration(double? seconds) {
    if (seconds == null) return 'N/A';
    final minutes = (seconds / 60).round();
    if (minutes < 60) return '${minutes}m';
    final hours = (minutes / 60).floor();
    final rem = minutes % 60;
    return '${hours}h ${rem}m';
  }

  String _formatDistance(double? meters) {
    if (meters == null) return 'N/A';
    if (meters < 1000) return '${meters.toInt()}m';
    final km = (meters / 1000).toStringAsFixed(1);
    return '${km}km';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fromName = item.originName ?? 'Origin';
    final toName = item.destinationName ?? 'Destination';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.history, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'from: $fromName to: $toName',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            item.status == 'completed' ? 'Completed' : item.status,
            style: TextStyle(
              fontSize: 12,
              color: item.status == 'completed'
                  ? Colors.green
                  : theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.schedule, size: 16, color: theme.colorScheme.onSurface.withOpacity(0.5)),
              const SizedBox(width: 4),
              Text(
                _formatDuration(item.totalDurationSeconds),
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(width: 12),
              Icon(Icons.attach_money, size: 16, color: theme.colorScheme.onSurface.withOpacity(0.5)),
              const SizedBox(width: 4),
              Text(
                item.estimatedFare != null
                    ? '${item.estimatedFare!.toStringAsFixed(2)} EGP'
                    : 'N/A',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(width: 12),
              Icon(Icons.straighten, size: 16, color: theme.colorScheme.onSurface.withOpacity(0.5)),
              const SizedBox(width: 4),
              Text(
                _formatDistance(item.totalDistanceMeters),
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: onTap,
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  child: Text(
                    'View Route',
                    style: TextStyle(color: theme.colorScheme.onPrimary, fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 64, color: theme.colorScheme.onSurface.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(
            'No route history yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Routes you search for will appear here',
            style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurface.withOpacity(0.5)),
          ),
        ],
      ),
    );
  }
}
