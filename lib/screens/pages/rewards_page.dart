import 'package:flutter/material.dart';

/// Route-result page with two modes:
/// - List view (route-result)
/// - Map view (route-result 2) with an interactive map-like canvas.
class RewardsPage extends StatefulWidget {
  const RewardsPage({super.key});

  @override
  State<RewardsPage> createState() => _RewardsPageState();
}

class _RewardsPageState extends State<RewardsPage> {
  bool _isListView = true;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Route Options',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Heliopolis → Downtown Cairo',
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                _ModeToggleChip(
                  label: 'List',
                  icon: Icons.list_alt,
                  selected: _isListView,
                  onTap: () => setState(() => _isListView = true),
                ),
                const SizedBox(width: 8),
                _ModeToggleChip(
                  label: 'Map',
                  icon: Icons.map_outlined,
                  selected: !_isListView,
                  onTap: () => setState(() => _isListView = false),
                ),
                const Spacer(),
                const _RouteFilterChip(label: 'Time', selected: true),
                const SizedBox(width: 6),
                const _RouteFilterChip(label: 'Cost'),
                const SizedBox(width: 6),
                const _RouteFilterChip(label: 'Transport'),
              ],
            ),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _isListView
                  ? const _RouteOptionsListView(key: ValueKey('list'))
                  : const _RouteOptionsMapView(key: ValueKey('map')),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeToggleChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ModeToggleChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: selected
                ? theme.colorScheme.primary.withOpacity(0.08)
                : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? theme.colorScheme.primary : theme.dividerColor,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: selected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface.withOpacity(0.7),
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: selected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withOpacity(0.7),
                  fontWeight:
                      selected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RouteOptionsListView extends StatelessWidget {
  const _RouteOptionsListView({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      children: const [
        _RouteOptionCard(
          tag: 'Fastest',
          time: '42 min',
          price: '5 EGP',
          transfers: '2 transfers',
          walkTime: '8 min walk',
          humidity: 0.66,
          reliability: 0.9,
        ),
        SizedBox(height: 12),
        _RouteOptionCard(
          tag: 'Cheapest',
          time: '55 min',
          price: '3 EGP',
          transfers: '3 transfers',
          walkTime: '10 min walk',
          humidity: 0.72,
          reliability: 0.8,
        ),
        SizedBox(height: 12),
        _RouteOptionCard(
          tag: 'Comfort',
          time: '39 min',
          price: '8 EGP',
          transfers: '1 transfer',
          walkTime: '5 min walk',
          humidity: 0.6,
          reliability: 0.95,
        ),
      ],
    );
  }
}

/// Route-result 2: interactive map-style view.
class _RouteOptionsMapView extends StatelessWidget {
  const _RouteOptionsMapView({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: InteractiveViewer(
                minScale: 0.8,
                maxScale: 3,
                child: AspectRatio(
                  aspectRatio: 3 / 4,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F3FF),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Theme.of(context).dividerColor),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          left: 40,
                          top: 40,
                          right: 80,
                          child: Container(
                            height: 3,
                            color: const Color(0xFF42A5F5),
                          ),
                        ),
                        Positioned(
                          left: 60,
                          top: 90,
                          right: 40,
                          child: Container(
                            height: 3,
                            color: const Color(0xFF66BB6A),
                          ),
                        ),
                        Positioned(
                          left: 80,
                          top: 160,
                          right: 60,
                          child: Container(
                            height: 3,
                            color: const Color(0xFFFFB74D),
                          ),
                        ),
                        const _MapMarker(
                          label: 'Heliopolis',
                          icon: Icons.radio_button_checked,
                          color: Color(0xFF42A5F5),
                          dx: 32,
                          dy: 26,
                        ),
                        const _MapMarker(
                          label: 'Downtown',
                          icon: Icons.location_on,
                          color: Color(0xFFEF5350),
                          dx: 200,
                          dy: 26,
                        ),
                        const _MapMarker(
                          label: 'Nasr City',
                          icon: Icons.location_on_outlined,
                          color: Color(0xFF66BB6A),
                          dx: 80,
                          dy: 80,
                        ),
                        const _MapMarker(
                          label: 'Zamalek',
                          icon: Icons.location_on_outlined,
                          color: Color(0xFFFFB74D),
                          dx: 180,
                          dy: 150,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: const [
              Expanded(
                child: _MiniRouteLegendCard(
                  tag: 'Fastest',
                  time: '42 min',
                  price: '5 EGP',
                  color: Color(0xFF42A5F5),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _MiniRouteLegendCard(
                  tag: 'Cheapest',
                  time: '55 min',
                  price: '3 EGP',
                  color: Color(0xFF66BB6A),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MapMarker extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final double dx;
  final double dy;

  const _MapMarker({
    required this.label,
    required this.icon,
    required this.color,
    required this.dx,
    required this.dy,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: dx,
      top: dy,
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).shadowColor.withOpacity(0.08),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniRouteLegendCard extends StatelessWidget {
  final String tag;
  final String time;
  final String price;
  final Color color;

  const _MiniRouteLegendCard({
    required this.tag,
    required this.time,
    required this.price,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tag,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$time · $price',
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RouteFilterChip extends StatelessWidget {
  final String label;
  final bool selected;

  const _RouteFilterChip({required this.label, this.selected = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: selected
            ? theme.colorScheme.primary.withOpacity(0.1)
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: selected ? theme.colorScheme.primary : theme.dividerColor,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (selected) ...[
            Icon(Icons.check, size: 14, color: theme.colorScheme.primary),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: selected ? theme.colorScheme.primary : theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}

class _RouteOptionCard extends StatelessWidget {
  final String tag;
  final String time;
  final String price;
  final String transfers;
  final String walkTime;
  final double humidity;
  final double reliability;

  const _RouteOptionCard({
    required this.tag,
    required this.time,
    required this.price,
    required this.transfers,
    required this.walkTime,
    required this.humidity,
    required this.reliability,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
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
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  tag,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              const Spacer(),
              Icon(Icons.more_vert, size: 18, color: theme.colorScheme.onSurface.withOpacity(0.5)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.schedule, size: 18, color: theme.colorScheme.onSurface.withOpacity(0.5)),
              const SizedBox(width: 4),
              Text(
                time,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(width: 16),
              Icon(Icons.attach_money, size: 18, color: theme.colorScheme.onSurface.withOpacity(0.5)),
              const SizedBox(width: 2),
              Text(
                price,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const Spacer(),
              Text(
                transfers,
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
              Icon(Icons.directions_bus, size: 18, color: theme.colorScheme.onSurface.withOpacity(0.5)),
              const SizedBox(width: 4),
              Text(
                walkTime,
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
              Icon(Icons.water_drop, size: 16, color: theme.colorScheme.onSurface.withOpacity(0.5)),
              const SizedBox(width: 4),
              Text(
                'Humidity',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: humidity,
                    minHeight: 6,
                    backgroundColor: theme.dividerColor,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      theme.colorScheme.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.verified_user, size: 16, color: theme.colorScheme.onSurface.withOpacity(0.5)),
              const SizedBox(width: 4),
              Text(
                'Reliability',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: reliability,
                    minHeight: 6,
                    backgroundColor: theme.dividerColor,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF66BB6A),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${(reliability * 100).round()}%',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text(
                'View Details',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
