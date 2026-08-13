import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/borrow_lend.dart';
import '../models/change_request.dart';
import '../models/pending_invite_model.dart';
import '../models/shared_entry_model.dart';
import '../providers/auth_provider.dart';
import '../providers/change_request_provider.dart';
import '../providers/invite_provider.dart';
import '../providers/shared_entry_provider.dart';
import '../theme/app_theme.dart';

/// Screen displaying pending debt entries in two sections:
/// 1. Entries the current user created (waiting for linked user to accept/reject)
/// 2. Entries others created linking to current user (needs your approval)
/// Plus invites sent to users who haven't registered yet, and change requests
/// for pending edits
class PendingRequestsScreen extends StatelessWidget {
  const PendingRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = context.read<AuthProvider>().user!.uid;
    final provider = context.watch<SharedEntryProvider>();
    final changeProvider = context.watch<ChangeRequestProvider>();
    final inviteProvider = context.watch<InviteProvider>();
    final waitingForOther = provider.pendingFromMe;
    final needsMyApproval = provider.pendingApprovals;
    final pendingInvites = inviteProvider.pendingInvites;
    final incomingChanges = changeProvider.incomingRequests;
    final outgoingChanges = changeProvider.outgoingRequests;
    final theme = Theme.of(context);

    final isEmpty = waitingForOther.isEmpty &&
        needsMyApproval.isEmpty &&
        pendingInvites.isEmpty &&
        incomingChanges.isEmpty &&
        outgoingChanges.isEmpty;

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
                if (pendingInvites.isNotEmpty) ...[
                  _SectionHeader(
                    title: 'Invites sent',
                    subtitle: 'Waiting for them to join with your code',
                    count: pendingInvites.length,
                    theme: theme,
                  ),
                  const SizedBox(height: 8),
                  ...pendingInvites.map((invite) => _InviteCard(
                        invite: invite,
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
                  const SizedBox(height: 20),
                ],
                if (incomingChanges.isNotEmpty) ...[
                  _SectionHeader(
                    title: 'Change requests',
                    subtitle: 'Edits proposed by others — accept or reject',
                    count: incomingChanges.length,
                    theme: theme,
                  ),
                  const SizedBox(height: 8),
                  ...incomingChanges.map((request) => _IncomingChangeCard(
                        request: request,
                        userId: userId,
                      )),
                  const SizedBox(height: 20),
                ],
                if (outgoingChanges.isNotEmpty) ...[
                  _SectionHeader(
                    title: 'Your change requests',
                    subtitle: 'Edits you proposed — awaiting the other person',
                    count: outgoingChanges.length,
                    theme: theme,
                  ),
                  const SizedBox(height: 8),
                  ...outgoingChanges.map((request) => _OutgoingChangeCard(
                        request: request,
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
                            'Linked to ${entry.linkedUserName ?? 'them'} — waiting for approval',
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

/// Card for a pending invite to a user who hasn't registered yet.
class _InviteCard extends StatelessWidget {
  final PendingInvite invite;

  const _InviteCard({required this.invite});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final daysLeft =
        invite.expiresAt.difference(DateTime.now()).inDays + 1;

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
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Icon(
                    Icons.person_add_alt_1,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        invite.targetPersonName,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Invited to join — waiting for signup',
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
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Text(
                    'Code: ',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    invite.inviteCode,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    daysLeft <= 1 ? 'Expires today' : 'Expires in $daysLeft days',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _copyCode(context),
                    icon: const Icon(Icons.copy, size: 18),
                    label: const Text('Copy Code'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _cancel(context),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Cancel'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                      side: BorderSide(color: theme.colorScheme.error),
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

  void _copyCode(BuildContext context) {
    Clipboard.setData(ClipboardData(text: invite.inviteCode));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Invite code copied')),
    );
  }

  Future<void> _cancel(BuildContext context) async {
    final provider = context.read<InviteProvider>();
    final success = await provider.cancelInvite(invite: invite);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? 'Invite cancelled'
              : 'Failed to cancel invite'),
        ),
      );
    }
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
                        'Created by ${entry.createdByName ?? 'Unknown'}',
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
    final success = await provider.editEntryFromMap(
      entryId: entry.id,
      data: {
        'approvalStatus': ApprovalStatus.active.name,
        'updatedAt': DateTime.now().toIso8601String(),
      },
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'Request accepted' : 'Failed to accept request',
          ),
        ),
      );
    }
  }

  Future<void> _reject(BuildContext context) async {
    final provider = context.read<SharedEntryProvider>();
    final success = await provider.editEntryFromMap(
      entryId: entry.id,
      data: {
        'approvalStatus': ApprovalStatus.rejected.name,
        'updatedAt': DateTime.now().toIso8601String(),
      },
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'Request rejected' : 'Failed to reject request',
          ),
        ),
      );
    }
  }
}

/// Card for incoming change requests — shows what changed and accept/reject buttons.
class _IncomingChangeCard extends StatelessWidget {
  final ChangeRequest request;
  final String userId;

  const _IncomingChangeCard({required this.request, required this.userId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sharedProvider = context.read<SharedEntryProvider>();

    // Find the current entry to describe changes
    final currentEntry = sharedProvider.entries
        .where((e) => e.id == request.entryId)
        .toList();

    List<String> changes = [];
    if (currentEntry.isNotEmpty) {
      changes = request.describeChanges(currentEntry.first);
    }

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
                  backgroundColor: theme.colorScheme.tertiaryContainer,
                  child: Icon(
                    Icons.edit_note,
                    color: theme.colorScheme.tertiary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${request.requestedByName} wants to edit',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Entry: ${currentEntry.isNotEmpty ? currentEntry.first.personName : 'Unknown'}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (changes.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Proposed changes:',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    ...changes.map((change) => Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            change,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        )),
                  ],
                ),
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
    final provider = context.read<ChangeRequestProvider>();
    final success = await provider.acceptRequest(request: request);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? 'Changes applied'
              : 'Failed to apply changes'),
        ),
      );
    }
  }

  Future<void> _reject(BuildContext context) async {
    final provider = context.read<ChangeRequestProvider>();
    final success = await provider.rejectRequest(request: request);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? 'Changes rejected'
              : 'Failed to reject changes'),
        ),
      );
    }
  }
}

/// Card for outgoing change requests — shows what was proposed and cancel button.
class _OutgoingChangeCard extends StatelessWidget {
  final ChangeRequest request;
  final String userId;

  const _OutgoingChangeCard({required this.request, required this.userId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sharedProvider = context.read<SharedEntryProvider>();

    // Find the current entry to describe changes
    final currentEntry = sharedProvider.entries
        .where((e) => e.id == request.entryId)
        .toList();

    List<String> changes = [];
    if (currentEntry.isNotEmpty) {
      changes = request.describeChanges(currentEntry.first);
    }

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
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Icon(
                    Icons.hourglass_top,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your edit request',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Entry: ${currentEntry.isNotEmpty ? currentEntry.first.personName : 'Unknown'} — waiting for ${request.linkedUserName}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (changes.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Proposed changes:',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    ...changes.map((change) => Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            change,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        )),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _cancel(context),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Cancel Request'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                      side: BorderSide(color: theme.colorScheme.error),
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

  Future<void> _cancel(BuildContext context) async {
    final provider = context.read<ChangeRequestProvider>();
    final success = await provider.cancelRequest(request: request);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? 'Request cancelled'
              : 'Failed to cancel request'),
        ),
      );
    }
  }
}
