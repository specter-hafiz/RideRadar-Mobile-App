import 'package:flutter/material.dart';
import 'package:shuttletrack/domain/entities/bus_stop.dart';
import 'package:shuttletrack/domain/entities/shuttle.dart';
import 'package:shuttletrack/domain/entities/shuttle_route.dart';

class ShuttleInfoCard extends StatelessWidget {
  final ShuttleRoute route;
  final List<Shuttle> shuttles;
  final Map<String, BusStop> proximityMap;

  const ShuttleInfoCard({
    super.key,
    required this.route,
    required this.shuttles,
    required this.proximityMap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final routeColor = Color(int.parse(route.colorHex, radix: 16));
    final activeCount = shuttles.where((s) => s.isActive).length;

    return Card(
      color: theme.colorScheme.surface,
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: routeColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    route.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$activeCount active',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (proximityMap.isNotEmpty)
              ...proximityMap.entries.map((entry) {
                final shuttle = shuttles
                    .where((s) => s.id == entry.key)
                    .firstOrNull;
                if (shuttle == null) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${shuttle.name} at ${entry.value.name}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              })
            else
              Text(
                'Tracking $activeCount shuttle${activeCount == 1 ? '' : 's'}...',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
