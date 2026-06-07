import 'package:flutter/material.dart';
import 'package:shuttletrack/domain/entities/shuttle_route.dart';
import 'package:shuttletrack/core/utils/responsive.dart';

class RouteCard extends StatelessWidget {
  final ShuttleRoute route;
  final bool isSelected;
  final VoidCallback onTap;

  const RouteCard({
    super.key,
    required this.route,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isSelected
            ? BorderSide(color: theme.colorScheme.primary, width: 1.6)
            : BorderSide(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.12),
              ),
      ),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(color: theme.colorScheme.surface),
          child: Padding(
            padding: EdgeInsets.all(rs(context, 18)),
            child: Row(
              children: [
                Container(
                  width: rs(context, 48),
                  height: rs(context, 48),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceVariant.withValues(
                      alpha: 0.6,
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: theme.colorScheme.outlineVariant.withValues(
                        alpha: 0.14,
                      ),
                    ),
                  ),
                  child: Center(
                    child: Container(
                      width: rs(context, 20),
                      height: rs(context, 20),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.14,
                        ),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: rs(context, 16)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        route.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                        ),
                      ),
                      SizedBox(height: rs(context, 4)),
                      Text(
                        route.description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.35,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                SizedBox(width: rs(context, 12)),
                Column(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: rs(context, 10),
                        vertical: rs(context, 5),
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${route.stops.length} stop${route.stops.length > 1 ? 's' : ''}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (isSelected) ...[
                      SizedBox(height: rs(context, 8)),
                      Icon(
                        Icons.check_circle_rounded,
                        color: theme.colorScheme.primary,
                        size: rs(context, 20),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
