import 'package:flutter/material.dart';
import 'package:shuttletrack/domain/entities/shuttle_alert.dart';
import 'package:shuttletrack/core/utils/responsive.dart';

class AlertTile extends StatelessWidget {
  final ShuttleAlert alert;

  const AlertTile({super.key, required this.alert});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.symmetric(
        horizontal: rs(context, 16),
        vertical: rs(context, 6),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Icon(
            Icons.notifications_active_rounded,
            color: theme.colorScheme.onPrimaryContainer,
            size: rs(context, 20),
          ),
        ),
        title: Text(
          alert.message,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(
          '${alert.routeName} · ${_formatRelativeTime(alert.timestamp)}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.3,
          ),
        ),
      ),
    );
  }

  String _formatRelativeTime(DateTime timestamp) {
    final diff = DateTime.now().difference(timestamp);

    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hr ago';
    return '${diff.inDays} day${diff.inDays == 1 ? '' : 's'} ago';
  }
}
