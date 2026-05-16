import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/borrow_lend.dart';
import '../providers/auth_provider.dart';
import '../providers/entry_provider.dart';
import 'add_edit_entry_screen.dart';

class AllRecordsScreen extends StatelessWidget {
  const AllRecordsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final entryProvider = context.watch<EntryProvider>();
    final authProvider = context.read<AuthProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('All Records')),
      body: entryProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : !entryProvider.hasEntries
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.receipt_long,
                          size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text('No entries yet.',
                          style: theme.textTheme.titleMedium),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: entryProvider.entries.length,
                  itemBuilder: (context, index) {
                    final entry = entryProvider.entries[index];
                    return _EntryCard(
                      entry: entry,
                      userId: authProvider.user!.uid,
                    );
                  },
                ),
    );
  }
}

class _EntryCard extends StatelessWidget {
  final BorrowLend entry;
  final String userId;

  const _EntryCard({required this.entry, required this.userId});

  @override
  Widget build(BuildContext context) {
    final isBorrow = entry.type == EntryType.borrow;
    final amountColor = isBorrow ? Colors.orange.shade700 : Colors.teal.shade600;
    final sign = isBorrow ? '-' : '+';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: amountColor.withValues(alpha: 0.1),
          child: Icon(
            isBorrow ? Icons.arrow_downward : Icons.arrow_upward,
            color: amountColor,
            size: 20,
          ),
        ),
        title: Text(
          entry.personName,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$sign\$${entry.amount.toStringAsFixed(2)} (${entry.currency})',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: amountColor,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                if (entry.deadline != null) ...[
                  Icon(Icons.event, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(entry.deadline!),
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(width: 12),
                ],
                _StatusChip(status: entry.status),
              ],
            ),
          ],
        ),
        isThreeLine: true,
        trailing: PopupMenuButton<_Action>(
          onSelected: (action) => _handleAction(context, action),
          itemBuilder: (_) => [
            const PopupMenuItem(value: _Action.edit, child: Text('Edit')),
            PopupMenuItem(
              value: _Action.markPaid,
              child: Text(entry.status == EntryStatus.paid
                  ? 'Mark Pending'
                  : 'Mark Paid'),
            ),
            if (entry.status != EntryStatus.partial)
              const PopupMenuItem(
                  value: _Action.markPartial, child: Text('Mark Partial')),
            const PopupMenuItem(value: _Action.delete, child: Text('Delete')),
          ],
        ),
      ),
    );
  }

  Future<void> _handleAction(BuildContext context, _Action action) async {
    final entryProvider = context.read<EntryProvider>();

    switch (action) {
      case _Action.edit:
        await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (_) => AddEditEntryScreen(entry: entry),
          ),
        );
        break;

      case _Action.markPaid:
        await entryProvider.editEntry(
          userId: userId,
          entry: entry.copyWith(
            status: entry.status == EntryStatus.paid
                ? EntryStatus.pending
                : EntryStatus.paid,
          ),
        );
        break;

      case _Action.markPartial:
        await entryProvider.editEntry(
          userId: userId,
          entry: entry.copyWith(status: EntryStatus.partial),
        );
        break;

      case _Action.delete:
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete Entry'),
            content: Text(
                'Delete the entry for ${entry.personName} (\$${entry.amount.toStringAsFixed(2)})?'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel')),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
        if (confirmed == true) {
          await entryProvider.deleteEntry(
              userId: userId, entryId: entry.id);
        }
        break;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

enum _Action { edit, markPaid, markPartial, delete }

class _StatusChip extends StatelessWidget {
  final EntryStatus status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;

    switch (status) {
      case EntryStatus.pending:
        color = Colors.orange;
        label = 'Pending';
      case EntryStatus.paid:
        color = Colors.green;
        label = 'Paid';
      case EntryStatus.partial:
        color = Colors.blue;
        label = 'Partial';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label, style: TextStyle(fontSize: 11, color: color)),
    );
  }
}
