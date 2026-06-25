import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/borrow_lend.dart';
import '../models/shared_entry_model.dart';
import '../providers/auth_provider.dart';
import '../providers/shared_entry_provider.dart';
import '../theme/app_theme.dart';

/// Screen displaying pending debt entries in two sections:
/// 1. Entries the current user created (waiting for linked user to accept/reject)
/// 2. Entries others created linking to current user (needs your approval)
class PendingRequestsScreen extends StatelessWidget {
  const PendingRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = context.read<AuthProvider>().user!.uid;
    final provider = context.watch<SharedEntryProvider>();
    final waitingForOther = provider.pendingFromMe;
    final needsMyApproval = provider.pendingApprovals;
    final theme = Theme.of(context);

    final isEmpty = waitingForOther.isEmpty && needsMyApproval.isEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Pending Requests')),
      body: isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 64,
                    color: theme.colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No pending requests',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Debts linked to you will appear here.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(12),
              children: [
                if (waitingForOther.isNotEmpty) ...[
                  _SectionHeader(
                    title: 'Waiting for approval',
                    subtitle: 'Your entries — awaiting the other person',
                    count: waitingForOther.length,
                    theme: theme,
                  ),
                  const SizedBox(height: 8),
                  ...waitingForOther.map((entry) => _WaitingCard(
                        entry: entry,
                        userId: userId,
                      )),
                  const SizedBox(height: 20),
                ],
                if (needsMyApproval.isNotEmpty) ...[
                  _SectionHeader(
                    title: 'Needs your approval',
                    subtitle: 'Entries linked to you — accept or reject',
                    count: needsMyApproval.length,
                    theme: theme,
                  ),
                  const SizedBox(height: 8),
                  ...needsMyApproval.map((entry) => _ApprovalCard(
                        entry: entry,
                        userId: userId,
                      )),
                ],
              ],
            ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final int count;
  final ThemeData theme;

  const _SectionHeader({
    required this.title,
    required this.subtitle,
    required this.count,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
        ),
      ],
    );
  }
}

/// Card for entries the current user created — shows "Waiting for {linkedUser}".
class _WaitingCard extends StatelessWidget {
  final SharedEntry entry;
  final String userId;

  const _WaitingCard({required this.entry, required this.userId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayType = entry.entryTypeFor(userId);
    final isBorrow = displayType == EntryType.borrow;
    final amountColor = isBorrow ? AppColors.borrowColor : AppColors.lendColor;
    final sign = isBorrow ? '-' : '+';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: amountColor.withValues(alpha: 0.1),
                  child: Icon(
                    isBorrow ? Icons.arrow_downward : Icons.arrow_upward,
                    color: amountColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.personName,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Waiting for ${entry.linkedUserName ?? 'them'} to approve',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.hourglass_top,
                  color: theme.colorScheme.onSurfaceVariant,
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '$sign${entry.amount.toStringAsFixed(3)} ${entry.currency}',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: amountColor,
              ),
            ),
            if (entry.deadline != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.event,
                    size: 14,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Due ${entry.deadline!.day}/${entry.deadline!.month}/${entry.deadline!.year}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Card for entries others created linking to current user — accept/reject.
class _ApprovalCard extends StatelessWidget {
  final SharedEntry entry;
  final String userId;

  const _ApprovalCard({required this.entry, required this.userId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayType = entry.entryTypeFor(userId);
    final isBorrow = displayType == EntryType.borrow;
    final amountColor = isBorrow ? AppColors.borrowColor : AppColors.lendColor;
    final sign = isBorrow ? '-' : '+';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: amountColor.withValues(alpha: 0.1),
                  child: Icon(
                    isBorrow ? Icons.arrow_downward : Icons.arrow_upward,
                    color: amountColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.personName,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Created by ${entry.linkedUserName ?? 'Unknown'}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '$sign${entry.amount.toStringAsFixed(3)} ${entry.currency}',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: amountColor,
              ),
            ),
            if (entry.deadline != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.event,
                    size: 14,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Due ${entry.deadline!.day}/${entry.deadline!.month}/${entry.deadline!.year}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
            if (entry.notes != null && entry.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                entry.notes!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _reject(context),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                      side: BorderSide(color: theme.colorScheme.error),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _accept(context),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Accept'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _accept(BuildContext context) async {
    final provider = context.read<SharedEntryProvider>();
    await provider.editEntry(
      entry: entry.copyWith(approvalStatus: ApprovalStatus.active),
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request accepted')),
      );
    }
  }

  Future<void> _reject(BuildContext context) async {
    final provider = context.read<SharedEntryProvider>();
    await provider.editEntry(
      entry: entry.copyWith(approvalStatus: ApprovalStatus.rejected),
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request rejected')),
      );
    }
  }
}
