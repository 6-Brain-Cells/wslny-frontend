import 'package:flutter/material.dart';
import 'package:wslny/models/route_addon_models.dart';
import 'package:wslny/services/route_service.dart';

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

  String _formatFare(double? fare) {
    if (fare == null) return 'N/A';
    return '${fare.toStringAsFixed(2)} EGP';
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final hour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
    final amPm = date.hour >= 12 ? 'PM' : 'AM';
    final min = date.minute.toString().padLeft(2, '0');
    return '${months[date.month - 1]} ${date.day}, ${date.year} – $hour:$min $amPm';
  }

  String _formatFilter(String filter) {
    switch (filter) {
      case '1': return 'Optimal';
      case '2': return 'Fastest';
      case '3': return 'Cheapest';
      case '4': return 'Bus Only';
      case '5': return 'Microbus Only';
      case '6': return 'Metro Only';
      default: return filter;
    }
  }

  void _showDetails(RouteHistoryItem item) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final theme = Theme.of(context);
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Icon(Icons.history, color: theme.colorScheme.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Route Details',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _detailRow(theme, 'From', item.originName ?? 'N/A', Icons.trip_origin),
              const SizedBox(height: 12),
              _detailRow(theme, 'To', item.destinationName ?? 'N/A', Icons.location_on),
              if (item.inputText != null) ...[
                const SizedBox(height: 12),
                _detailRow(theme, 'Request', item.inputText!, Icons.search),
              ],
              const Divider(height: 32),
              Row(
                children: [
                  _miniBadge(theme, Icons.schedule, _formatDuration(item.totalDurationSeconds)),
                  const SizedBox(width: 12),
                  _miniBadge(theme, Icons.straighten, _formatDistance(item.totalDistanceMeters)),
                  const SizedBox(width: 12),
                  _miniBadge(theme, Icons.attach_money, _formatFare(item.estimatedFare)),
                ],
              ),
              const Divider(height: 32),
              _detailRow(theme, 'Filter', _formatFilter(item.filter), Icons.tune),
              const SizedBox(height: 12),
              _detailRow(theme, 'Status', item.status, Icons.info_outline),
              if (item.errorCode != null) ...[
                const SizedBox(height: 12),
                _detailRow(theme, 'Error', item.errorCode!, Icons.error_outline),
              ],
              const SizedBox(height: 12),
      _detailRow(
        theme,
        'Date',
        _formatDate(item.createdAt),
        Icons.calendar_today,
      ),
            ],
          ),
        );
      },
    );
  }

  Widget _detailRow(ThemeData theme, String label, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.primary),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: theme.colorScheme.onSurface.withOpacity(0.5),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _miniBadge(ThemeData theme, IconData icon, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: theme.colorScheme.primary),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
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
                            onTap: () => _showDetails(item),
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
                    'View Details',
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
