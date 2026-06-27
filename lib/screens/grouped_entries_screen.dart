import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/borrow_lend.dart';
import '../models/shared_entry_model.dart';
import '../providers/auth_provider.dart';
import '../providers/shared_entry_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/offline_indicator.dart';
import 'add_edit_entry_screen.dart';

/// Screen displaying entries grouped by linked person with expandable lists.
class GroupedEntriesScreen extends StatefulWidget {
  const GroupedEntriesScreen({super.key});

  @override
  State<GroupedEntriesScreen> createState() => _GroupedEntriesScreenState();
}

class _GroupedEntriesScreenState extends State<GroupedEntriesScreen> {
  final _searchController = TextEditingController();
  final Set<String> _expandedPersons = {};

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
    final provider = context.watch<SharedEntryProvider>();
    final authProvider = context.read<AuthProvider>();
    final theme = Theme.of(context);
    final groups = provider.groupedEntries;
    final userId = authProvider.user!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Grouped by Person'),
        actions: [
          if (provider.filtersActive)
            IconButton(
              icon: const Icon(Icons.filter_alt_off),
              tooltip: 'Clear filters',
              onPressed: () {
                _searchController.clear();
                provider.clearFilters();
              },
            ),
        ],
      ),
      body: Column(
        children: [
          const OfflineIndicator(),
          _buildSearchBar(theme, provider),
          _buildFilterChips(theme, provider),
          const Divider(height: 1),
          Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : groups.isEmpty
                    ? _buildEmptyState(theme, provider)
                    : _buildGroupList(groups, userId, theme),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(ThemeData theme, SharedEntryProvider provider) {
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
                    provider.setSearchQuery('');
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

  Widget _buildGroupList(
    List<PersonGroup> groups,
    String userId,
    ThemeData theme,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      itemCount: groups.length,
      itemBuilder: (context, index) {
        final group = groups[index];
        final isExpanded = _expandedPersons.contains(group.personId);

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              InkWell(
                onTap: () {
                  setState(() {
                    if (isExpanded) {
                      _expandedPersons.remove(group.personId);
                    } else {
                      _expandedPersons.add(group.personId);
                    }
                  });
                },
                child: _PersonGroupHeader(
                  group: group,
                  userId: userId,
                  isExpanded: isExpanded,
                  theme: theme,
                ),
              ),
              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: _PersonGroupEntries(
                  entries: group.entries,
                  userId: userId,
                  theme: theme,
                ),
                crossFadeState: isExpanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 200),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(ThemeData theme, SharedEntryProvider provider) {
    if (!provider.hasEntries) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.group, size: 64, color: theme.colorScheme.outline),
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
              provider.clearFilters();
            },
            child: const Text('Clear filters'),
          ),
        ],
      ),
    );
  }
}

/// Header widget for a person group showing name, totals, and expand icon.
class _PersonGroupHeader extends StatelessWidget {
  final PersonGroup group;
  final String userId;
  final bool isExpanded;
  final ThemeData theme;

  const _PersonGroupHeader({
    required this.group,
    required this.userId,
    required this.isExpanded,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final balanceColor = group.netBalance > 0
        ? AppColors.lendColor
        : group.netBalance < 0
            ? AppColors.borrowColor
            : theme.colorScheme.outline;
    final sign = group.netBalance > 0 ? '+' : '';

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: theme.colorScheme.primaryContainer,
            child: Text(
              group.personName.isNotEmpty ? group.personName[0].toUpperCase() : '?',
              style: TextStyle(
                color: theme.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  group.personName,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (group.totalLent > 0) ...[
                      Text(
                        'Lent: ${group.totalLent.toStringAsFixed(3)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.lendColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (group.totalBorrowed > 0)
                      Text(
                        'Borrowed: ${group.totalBorrowed.toStringAsFixed(3)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.borrowColor,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$sign${group.netBalance.abs().toStringAsFixed(3)}',
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: balanceColor,
                ),
              ),
              Text(
                'Net',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          Icon(
            isExpanded ? Icons.expand_less : Icons.expand_more,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}

/// List of entries within a person group.
class _PersonGroupEntries extends StatelessWidget {
  final List<SharedEntry> entries;
  final String userId;
  final ThemeData theme;

  const _PersonGroupEntries({
    required this.entries,
    required this.userId,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: entries.map((entry) => _EntryTile(
        entry: entry,
        userId: userId,
        theme: theme,
      )).toList(),
    );
  }
}

/// Single entry tile within a group.
class _EntryTile extends StatelessWidget {
  final SharedEntry entry;
  final String userId;
  final ThemeData theme;

  const _EntryTile({
    required this.entry,
    required this.userId,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final isBorrow = entry.entryTypeFor(userId) == EntryType.borrow;
    final entryColor = isBorrow ? AppColors.borrowColor : AppColors.lendColor;
    final sign = isBorrow ? '-' : '+';

    final brightness = Theme.of(context).brightness;
    final statusColor = AppColors.forStatus(entry.status, brightness);
    final statusLabel = switch (entry.status) {
      EntryStatus.pending => 'Pending',
      EntryStatus.paid => 'Paid',
      EntryStatus.partial => 'Partial',
    };

    return InkWell(
      onTap: () async {
        await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (_) => AddEditEntryScreen(entry: entry),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 3,
              height: 40,
              decoration: BoxDecoration(
                color: entryColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _daysAgo(entry.createdAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (entry.deadline != null) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.event, size: 12, color: theme.colorScheme.onSurfaceVariant),
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$sign${entry.amount.toStringAsFixed(3)} ${entry.currency}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: entryColor,
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(fontSize: 11, color: statusColor),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _daysAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    return '${diff.inDays} days ago';
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
