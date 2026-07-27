import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/borrow_lend.dart';
import '../models/shared_entry_model.dart';
import '../providers/auth_provider.dart';
import '../providers/change_request_provider.dart';
import '../providers/shared_entry_provider.dart';
import '../providers/notification_provider.dart';
import '../theme/app_theme.dart';
import '../utils/constants.dart';
import '../widgets/offline_indicator.dart';
import 'add_edit_entry_screen.dart';
import 'all_records_screen.dart';
import 'appearance_settings_screen.dart';
import 'csv_preview_screen.dart';
import 'notification_settings_screen.dart';
import 'pdf_preview_screen.dart';
import 'security_settings_screen.dart';
import 'statistics_screen.dart';
import 'pending_requests_screen.dart';
import 'grouped_entries_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final userId = context.read<AuthProvider>().user!.uid;
      final sharedEntryProvider = context.read<SharedEntryProvider>();
      final notificationProvider = context.read<NotificationProvider>();

      sharedEntryProvider.listenToEntries(userId);
      context.read<ChangeRequestProvider>().listenToChangeRequests(userId);

      sharedEntryProvider.onEntriesRefreshed = () {
        if (mounted) {
          notificationProvider
              .onEntriesUpdated(sharedEntryProvider.entries);
        }
      };

      notificationProvider.initialize(userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final sharedEntryProvider = context.watch<SharedEntryProvider>();
    final theme = Theme.of(context);
    final pendingCount = sharedEntryProvider.pendingFromMe.length +
        sharedEntryProvider.pendingApprovals.length +
        context.read<ChangeRequestProvider>().incomingRequests.length;

    return Scaffold(
      appBar: AppBar(
        leading: PopupMenuButton<_MenuAction>(
          icon: const Icon(Icons.menu),
          onSelected: (action) => _handleMenuAction(context, action, sharedEntryProvider),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: _MenuAction.allRecords,
              child: _MenuTile(icon: Icons.list, title: 'All Records'),
            ),
            const PopupMenuItem(
              value: _MenuAction.groupedByPerson,
              child: _MenuTile(icon: Icons.group, title: 'Grouped by Person'),
            ),
            PopupMenuItem(
              value: _MenuAction.pendingRequests,
              child: _MenuTile(
                icon: Icons.how_to_vote,
                title: 'Pending Requests',
                badge: pendingCount > 0 ? '$pendingCount' : null,
              ),
            ),
            const PopupMenuItem(
              value: _MenuAction.statistics,
              child: _MenuTile(icon: Icons.bar_chart, title: 'Statistics'),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: _MenuAction.exportCsv,
              child: _MenuTile(icon: Icons.table_chart, title: 'Export to CSV'),
            ),
            const PopupMenuItem(
              value: _MenuAction.exportPdf,
              child: _MenuTile(icon: Icons.picture_as_pdf, title: 'Export to PDF'),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: _MenuAction.notifications,
              child: _MenuTile(
                  icon: Icons.notifications_outlined, title: 'Notifications'),
            ),
            const PopupMenuItem(
              value: _MenuAction.appearance,
              child: _MenuTile(
                  icon: Icons.palette_outlined, title: 'Appearance'),
            ),
            const PopupMenuItem(
              value: _MenuAction.security,
              child: _MenuTile(icon: Icons.shield_outlined, title: 'Security'),
            ),
          ],
        ),
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.account_balance_wallet,
              color: theme.colorScheme.primary,
              size: 28,
            ),
            const SizedBox(width: 8),
            Text(
              AppConstants.appName,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign Out',
            onPressed: () => authProvider.signOut(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const AddEditEntryScreen(),
          ),
        ),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          const OfflineIndicator(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                final userId = authProvider.user!.uid;
                context.read<SharedEntryProvider>().listenToEntries(userId);
                context.read<ChangeRequestProvider>().listenToChangeRequests(userId);
              },
              child: _buildBody(theme, sharedEntryProvider, authProvider),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
      ThemeData theme, SharedEntryProvider sharedEntryProvider, AuthProvider authProvider) {
    if (sharedEntryProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (sharedEntryProvider.error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 8),
            Text('Something went wrong', style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(sharedEntryProvider.error!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                )),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildGreeting(theme, authProvider),
        const SizedBox(height: 8),
        _buildSummaryRow(theme, sharedEntryProvider),
        const SizedBox(height: 16),
        _buildNetBalanceCard(theme, sharedEntryProvider),
        const SizedBox(height: 16),
        _buildStatsRow(theme, sharedEntryProvider),
        const SizedBox(height: 24),
        _buildRecentSection(theme, sharedEntryProvider),
      ],
    );
  }

  Widget _buildGreeting(ThemeData theme, AuthProvider provider) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        'Welcome, ${provider.user?.displayName ?? 'User'}',
        style: theme.textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSummaryRow(ThemeData theme, SharedEntryProvider provider) {
    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            title: 'Total Borrowed',
            amount: provider.totalBorrowed,
            currency: AppConstants.defaultCurrency,
            icon: Icons.arrow_downward,
            color: AppColors.borrowColor,
            theme: theme,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            title: 'Total Lent',
            amount: provider.totalLent,
            currency: AppConstants.defaultCurrency,
            icon: Icons.arrow_upward,
            color: AppColors.lendColor,
            theme: theme,
          ),
        ),
      ],
    );
  }

  Widget _buildNetBalanceCard(ThemeData theme, SharedEntryProvider provider) {
    final balance = provider.netBalance;
    final isPositive = balance > 0;
    final isZero = balance == 0;
    final color = isZero
        ? theme.colorScheme.outline
        : isPositive
            ? AppColors.lendColor
            : AppColors.borrowColor;
    final sign = isPositive ? '+' : '';
    final label = isZero
        ? 'Settled'
        : isPositive
            ? 'Others owe you'
            : 'You owe others';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.account_balance, color: color, size: 20),
                const SizedBox(width: 6),
                Text('Net Balance', style: theme.textTheme.bodySmall),
                const Spacer(),
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '$sign${balance.abs().toStringAsFixed(3)} ${AppConstants.defaultCurrency}',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(ThemeData theme, SharedEntryProvider provider) {
    return Row(
      children: [
        Expanded(
          child: _StatsCard(
            label: 'Pending',
            count: provider.pendingCount,
            icon: Icons.hourglass_empty,
            color: AppColors.statsPending,
            theme: theme,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatsCard(
            label: 'Deadlines (7d)',
            count: provider.upcomingDeadlineCount,
            icon: Icons.event,
            color: AppColors.statsDeadline,
            theme: theme,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentSection(ThemeData theme, SharedEntryProvider provider) {
    final groups = provider.groupedEntries;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'By Person',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AllRecordsScreen()),
              ),
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (groups.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Text(
                  'No entries yet.\nTap + to add your first one.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          )
        else
          ...groups.map((group) => _DashboardPersonGroup(
                group: group,
                userId: provider.currentUserId,
                theme: theme,
              )),
      ],
    );
  }

  void _handleMenuAction(
    BuildContext context,
    _MenuAction action,
    SharedEntryProvider sharedEntryProvider,
  ) {
    switch (action) {
      case _MenuAction.allRecords:
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const AllRecordsScreen()));
        break;
      case _MenuAction.groupedByPerson:
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const GroupedEntriesScreen()));
        break;
      case _MenuAction.pendingRequests:
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const PendingRequestsScreen()));
        break;
      case _MenuAction.statistics:
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const StatisticsScreen()));
        break;
      case _MenuAction.exportCsv:
        if (sharedEntryProvider.activeEntries.isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CsvPreviewScreen(
                entries: sharedEntryProvider.activeEntries,
                currentUserId: sharedEntryProvider.currentUserId,
              ),
            ),
          );
        }
        break;
      case _MenuAction.exportPdf:
        if (sharedEntryProvider.activeEntries.isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PdfPreviewScreen(
                entries: sharedEntryProvider.activeEntries,
                currentUserId: sharedEntryProvider.currentUserId,
              ),
            ),
          );
        }
        break;
      case _MenuAction.notifications:
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const NotificationSettingsScreen()));
        break;
      case _MenuAction.appearance:
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const AppearanceSettingsScreen()));
        break;
      case _MenuAction.security:
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const SecuritySettingsScreen()));
        break;
    }
  }
}

enum _MenuAction {
  allRecords,
  groupedByPerson,
  pendingRequests,
  statistics,
  exportCsv,
  exportPdf,
  notifications,
  appearance,
  security,
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? badge;

  const _MenuTile({required this.icon, required this.title, this.badge});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 22),
        const SizedBox(width: 12),
        Expanded(child: Text(title)),
        if (badge != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.error,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              badge!,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onError,
              ),
            ),
          ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final double amount;
  final String currency;
  final IconData icon;
  final Color color;
  final ThemeData theme;

  const _SummaryCard({
    required this.title,
    required this.amount,
    required this.currency,
    required this.icon,
    required this.color,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 6),
                Text(title, style: theme.textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '${amount.toStringAsFixed(3)} $currency',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  final String label;
  final int count;
  final IconData icon;
  final Color color;
  final ThemeData theme;

  const _StatsCard({
    required this.label,
    required this.count,
    required this.icon,
    required this.color,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.textTheme.bodySmall),
                Text(
                  '$count',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardPersonGroup extends StatefulWidget {
  final PersonGroup group;
  final String userId;
  final ThemeData theme;

  const _DashboardPersonGroup({
    required this.group,
    required this.userId,
    required this.theme,
  });

  @override
  State<_DashboardPersonGroup> createState() => _DashboardPersonGroupState();
}

class _DashboardPersonGroupState extends State<_DashboardPersonGroup> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final group = widget.group;
    final theme = widget.theme;
    final userId = widget.userId;
    final balanceColor = group.netBalance > 0
        ? AppColors.lendColor
        : group.netBalance < 0
            ? AppColors.borrowColor
            : theme.colorScheme.outline;
    final sign = group.netBalance > 0 ? '+' : '';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Text(
                      group.personName.isNotEmpty
                          ? group.personName[0].toUpperCase()
                          : '?',
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
                        if (group.nextDeadline != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.event,
                                size: 12,
                                color: _deadlineColor(group.nextDeadline!, theme),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _deadlineLabel(group.nextDeadline!),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: _deadlineColor(group.nextDeadline!, theme),
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
                  const SizedBox(width: 4),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: theme.colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: _DashboardEntryList(
              entries: group.entries,
              userId: userId,
              theme: theme,
            ),
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }

  Color _deadlineColor(DateTime deadline, ThemeData theme) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final deadlineDay = DateTime(deadline.year, deadline.month, deadline.day);
    final daysUntil = deadlineDay.difference(today).inDays;
    if (daysUntil < 0) return AppColors.overdue(theme.brightness);
    if (daysUntil <= 3) return AppColors.borrowColor;
    return theme.colorScheme.onSurfaceVariant;
  }

  String _deadlineLabel(DateTime deadline) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final deadlineDay = DateTime(deadline.year, deadline.month, deadline.day);
    final daysUntil = deadlineDay.difference(today).inDays;
    if (daysUntil < 0) return '${-daysUntil}d overdue';
    if (daysUntil == 0) return 'Due today';
    if (daysUntil == 1) return 'Due tomorrow';
    return 'Due in ${daysUntil}d';
  }
}

/// Entry list shown inside an expanded person group on the dashboard.
class _DashboardEntryList extends StatelessWidget {
  final List<SharedEntry> entries;
  final String userId;
  final ThemeData theme;

  const _DashboardEntryList({
    required this.entries,
    required this.userId,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: entries.map((entry) {
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
      }).toList(),
    );
  }

  String _daysAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    return '${diff.inDays} days ago';
  }
}
