import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/borrow_lend.dart';
import '../models/shared_entry_model.dart';
import '../providers/auth_provider.dart';
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
        sharedEntryProvider.pendingApprovals.length;

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
    final recent = provider.recentEntries;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Entries',
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
        const SizedBox(height: 12),
        if (recent.isEmpty)
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
          ...recent.map((entry) => _RecentEntryTile(
                entry: entry,
                theme: theme,
                userId: provider.currentUserId,
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
      case _MenuAction.pendingRequests:
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const PendingRequestsScreen()));
        break;
      case _MenuAction.statistics:
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const StatisticsScreen()));
        break;
      case _MenuAction.exportCsv:
        if (sharedEntryProvider.entries.isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CsvPreviewScreen(entries: sharedEntryProvider.entries),
            ),
          );
        }
        break;
      case _MenuAction.exportPdf:
        if (sharedEntryProvider.entries.isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PdfPreviewScreen(entries: sharedEntryProvider.entries),
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

class _RecentEntryTile extends StatelessWidget {
  final SharedEntry entry;
  final ThemeData theme;
  final String userId;

  const _RecentEntryTile({
    required this.entry,
    required this.theme,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    final isBorrow = entry.entryTypeFor(userId) == EntryType.borrow;
    final entryColor = isBorrow ? AppColors.borrowColor : AppColors.lendColor;
    final sign = isBorrow ? '-' : '+';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: entryColor.withValues(alpha: 0.1),
          child: Icon(
            isBorrow ? Icons.arrow_downward : Icons.arrow_upward,
            color: entryColor,
            size: 20,
          ),
        ),
        title: Text(
          entry.personName,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          _daysAgo(entry.createdAt),
          style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
        ),
        trailing: Column(
          mainAxisSize: MainAxisSize.min,
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
            _StatusChip(status: entry.status),
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
      child: Text(
        label,
        style: TextStyle(fontSize: 11, color: color),
      ),
    );
  }
}
