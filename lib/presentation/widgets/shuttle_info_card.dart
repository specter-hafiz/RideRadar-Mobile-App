import 'package:flutter/material.dart';
import 'package:shuttletrack/domain/entities/bus_stop.dart';
import 'package:shuttletrack/domain/entities/shuttle.dart';
import 'package:shuttletrack/domain/entities/shuttle_route.dart';
import 'package:shuttletrack/core/utils/responsive.dart';

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
      elevation: 0,
      child: Padding(
        padding: EdgeInsets.all(rs(context, 18)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: rs(context, 14),
                  height: rs(context, 14),
                  decoration: BoxDecoration(
                    color: routeColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: routeColor.withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: rs(context, 10)),
                Expanded(
                  child: Text(
                    route.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: rs(context, 10),
                    vertical: rs(context, 4),
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$activeCount active',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: rs(context, 12)),
            if (proximityMap.isNotEmpty)
              ...proximityMap.entries.map((entry) {
                final shuttle = shuttles.where((s) => s.id == entry.key).isEmpty
                    ? null
                    : shuttles.firstWhere((s) => s.id == entry.key);
                if (shuttle == null) return const SizedBox.shrink();
                return Padding(
                  padding: EdgeInsets.only(bottom: rs(context, 4)),
                  child: Row(
                    children: [
                      Container(
                        width: rs(context, 8),
                        height: rs(context, 8),
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: rs(context, 8)),
                      Expanded(
                        child: Text(
                          '${shuttle.name} at ${entry.value.name}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            height: 1.3,
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
                  height: 1.3,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
