import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/borrow_lend.dart';
import '../models/shared_entry_model.dart';
import '../providers/auth_provider.dart';
import '../providers/shared_entry_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/offline_indicator.dart';
import 'add_edit_entry_screen.dart';
import 'csv_preview_screen.dart';
import 'pdf_preview_screen.dart';

class AllRecordsScreen extends StatefulWidget {
  const AllRecordsScreen({super.key});

  @override
  State<AllRecordsScreen> createState() => _AllRecordsScreenState();
}

class _AllRecordsScreenState extends State<AllRecordsScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      context.read<SharedEntryProvider>().setSearchQuery(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sharedEntryProvider = context.watch<SharedEntryProvider>();
    final authProvider = context.read<AuthProvider>();
    final theme = Theme.of(context);
    final filtered = sharedEntryProvider.filteredEntries;

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Records'),
        actions: [
          IconButton(
            icon: const Icon(Icons.table_chart),
            tooltip: 'Export to CSV',
            onPressed: filtered.isEmpty
                ? null
                : () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CsvPreviewScreen(entries: filtered),
                      ),
                    ),
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Export to PDF',
            onPressed: filtered.isEmpty
                ? null
                : () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PdfPreviewScreen(entries: filtered),
                      ),
                    ),
          ),
          if (sharedEntryProvider.filtersActive)
            IconButton(
              icon: const Icon(Icons.filter_alt_off),
              tooltip: 'Clear filters',
              onPressed: () {
                _searchController.clear();
                sharedEntryProvider.clearFilters();
              },
            ),
        ],
      ),
      body: Column(
        children: [
          const OfflineIndicator(),
          _buildSearchBar(theme),
          _buildFilterChips(theme, sharedEntryProvider),
          const Divider(height: 1),
          Expanded(
            child: sharedEntryProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? _buildEmptyState(theme, sharedEntryProvider)
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final entry = filtered[index];
                          return _EntryCard(
                            entry: entry,
                            currentUserId: authProvider.user!.uid,
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search by person name...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    context.read<SharedEntryProvider>().setSearchQuery('');
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
        ),
      ),
    );
  }

  Widget _buildFilterChips(ThemeData theme, SharedEntryProvider provider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _FilterChip(
              label: 'Status',
              active: provider.statusFilter != null,
              activeLabel: provider.statusFilter?.name ?? '',
              onTap: () => _showStatusPicker(provider),
            ),
            const SizedBox(width: 8),
            _FilterChip(
              label: 'Type',
              active: provider.typeFilter != null,
              activeLabel: provider.typeFilter?.name ?? '',
              onTap: () => _showTypePicker(provider),
            ),
            const SizedBox(width: 8),
            _FilterChip(
              label: 'Currency',
              active: provider.currencyFilter != null,
              activeLabel: provider.currencyFilter ?? '',
              onTap: () => _showCurrencyPicker(provider),
            ),
            const SizedBox(width: 8),
            _FilterChip(
              label: 'Deadline',
              active: provider.deadlineFilter != SharedDeadlineFilter.all,
              activeLabel: _deadlineLabel(provider.deadlineFilter),
              onTap: () => _showDeadlinePicker(provider),
            ),
          ],
        ),
      ),
    );
  }

  String _deadlineLabel(SharedDeadlineFilter filter) {
    switch (filter) {
      case SharedDeadlineFilter.hasDeadline:
        return 'Has deadline';
      case SharedDeadlineFilter.noDeadline:
        return 'No deadline';
      case SharedDeadlineFilter.overdue:
        return 'Overdue';
      case SharedDeadlineFilter.upcoming:
        return 'Next 7 days';
      case SharedDeadlineFilter.all:
        return '';
    }
  }

  void _showStatusPicker(SharedEntryProvider provider) {
    _showFilterOptions(
      title: 'Filter by Status',
      options: EntryStatus.values,
      labelOf: (s) => s.name,
      selected: provider.statusFilter,
      onSelected: (v) => provider.setStatusFilter(v),
    );
  }

  void _showTypePicker(SharedEntryProvider provider) {
    _showFilterOptions(
      title: 'Filter by Type',
      options: EntryType.values,
      labelOf: (t) => t.name == 'borrow' ? 'I Borrowed' : 'I Lent',
      selected: provider.typeFilter,
      onSelected: (v) => provider.setTypeFilter(v),
    );
  }

  void _showCurrencyPicker(SharedEntryProvider provider) {
    final currencies = provider.usedCurrencies.toList()..sort();
    _showFilterOptions(
      title: 'Filter by Currency',
      options: currencies,
      labelOf: (c) => c.toString(),
      selected: provider.currencyFilter,
      onSelected: (v) => provider.setCurrencyFilter(v),
    );
  }

  void _showDeadlinePicker(SharedEntryProvider provider) {
    final options = SharedDeadlineFilter.values;
    _showFilterOptions(
      title: 'Filter by Deadline',
      options: options,
      labelOf: (f) => _deadlineLabel(f),
      selected: provider.deadlineFilter == SharedDeadlineFilter.all
          ? null
          : provider.deadlineFilter,
      onSelected: (v) => provider.setDeadlineFilter(v ?? SharedDeadlineFilter.all),
    );
  }

  void _showFilterOptions<T>({
    required String title,
    required List<T> options,
    required String Function(T) labelOf,
    required T? selected,
    required void Function(T?) onSelected,
  }) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                title,
                style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            const Divider(height: 1),
            ...options.map(
              (option) => ListTile(
                title: Text(labelOf(option)),
                trailing: selected == option
                    ? Icon(Icons.check, color: Theme.of(ctx).colorScheme.primary)
                    : null,
                onTap: () {
                  Navigator.pop(ctx);
                  onSelected(selected == option ? null : option);
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, SharedEntryProvider provider) {
    if (!provider.hasEntries) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long, size: 64, color: theme.colorScheme.outline),
            const SizedBox(height: 16),
            Text('No entries yet.', style: theme.textTheme.titleMedium),
          ],
        ),
      );
    }
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off, size: 64, color: theme.colorScheme.outline),
          const SizedBox(height: 16),
          Text(
            'No entries match your filters.',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          TextButton(
            onPressed: () {
              _searchController.clear();
              context.read<SharedEntryProvider>().clearFilters();
            },
            child: const Text('Clear filters'),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool active;
  final String activeLabel;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.active,
    required this.activeLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return ActionChip(
      label: Text(
        active ? '$label: $activeLabel' : label,
        style: TextStyle(
          color: active ? colorScheme.onPrimary : null,
          fontSize: 13,
        ),
      ),
      backgroundColor:
          active ? colorScheme.primary : null,
      onPressed: onTap,
      avatar: Icon(
        active ? Icons.filter_alt : Icons.filter_list,
        size: 18,
        color: active ? colorScheme.onPrimary : null,
      ),
    );
  }
}

class _EntryCard extends StatelessWidget {
  final SharedEntry entry;
  final String currentUserId;

  const _EntryCard({required this.entry, required this.currentUserId});

  bool get _canDelete => entry.createdBy == currentUserId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isBorrow = entry.type == EntryType.borrow;
    final amountColor = isBorrow ? AppColors.borrowColor : AppColors.lendColor;
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
        title: Row(
          children: [
            Expanded(
              child: Text(
                entry.personName,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            if (entry.participants.length > 1)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.group, size: 12, color: theme.colorScheme.onPrimaryContainer),
                    const SizedBox(width: 2),
                    Text(
                      '${entry.participants.length}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$sign${entry.amount.toStringAsFixed(3)} ${entry.currency}',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: amountColor,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                if (entry.deadline != null) ...[
                  Icon(Icons.event, size: 14, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(entry.deadline!),
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
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
            if (_canDelete)
              const PopupMenuItem(value: _Action.delete, child: Text('Delete')),
          ],
        ),
      ),
    );
  }

  Future<void> _handleAction(BuildContext context, _Action action) async {
    final sharedEntryProvider = context.read<SharedEntryProvider>();

    switch (action) {
      case _Action.edit:
        await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (_) => AddEditEntryScreen(entry: entry),
          ),
        );
      case _Action.markPaid:
        await sharedEntryProvider.editEntry(
          entry: entry.copyWith(
            status: entry.status == EntryStatus.paid
                ? EntryStatus.pending
                : EntryStatus.paid,
          ),
        );
      case _Action.markPartial:
        await sharedEntryProvider.editEntry(
          entry: entry.copyWith(status: EntryStatus.partial),
        );
      case _Action.delete:
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete Entry'),
            content: Text(
                'Delete the entry for ${entry.personName} (${entry.amount.toStringAsFixed(3)} ${entry.currency})?'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel')),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text('Delete',
                    style: TextStyle(color: Theme.of(ctx).colorScheme.error)),
              ),
            ],
          ),
        );
        if (confirmed == true) {
          await sharedEntryProvider.deleteEntry(entryId: entry.id);
        }
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
    final brightness = Theme.of(context).brightness;
    final color = AppColors.forStatus(status, brightness);

    final label = switch (status) {
      EntryStatus.pending => 'Pending',
      EntryStatus.paid => 'Paid',
      EntryStatus.partial => 'Partial',
    };

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
