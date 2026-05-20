import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/borrow_lend.dart';
import '../providers/auth_provider.dart';
import '../providers/entry_provider.dart';
import '../providers/notification_provider.dart';
import '../utils/constants.dart';
import 'add_edit_entry_screen.dart';
import 'all_records_screen.dart';
import 'notification_settings_screen.dart';
import 'statistics_screen.dart';

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
      final entryProvider = context.read<EntryProvider>();
      final notificationProvider = context.read<NotificationProvider>();

      entryProvider.listenToEntries(userId);

      entryProvider.onEntriesRefreshed = () {
        if (mounted) {
          notificationProvider
              .onEntriesUpdated(entryProvider.entries);
        }
      };

      notificationProvider.initialize(userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final entryProvider = context.watch<EntryProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        actions: [
          IconButton(
            icon: const Icon(Icons.list),
            tooltip: 'All Records',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AllRecordsScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart),
            tooltip: 'Statistics',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const StatisticsScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            tooltip: 'Notifications',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const NotificationSettingsScreen()),
            ),
          ),
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
      body: RefreshIndicator(
        onRefresh: () async {
          final userId = authProvider.user!.uid;
          context.read<EntryProvider>().listenToEntries(userId);
        },
        child: _buildBody(theme, entryProvider, authProvider),
      ),
    );
  }

  Widget _buildBody(
      ThemeData theme, EntryProvider entryProvider, AuthProvider authProvider) {
    if (entryProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (entryProvider.error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 8),
            Text('Something went wrong', style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(entryProvider.error!, style: theme.textTheme.bodySmall),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildGreeting(theme, authProvider),
        const SizedBox(height: 8),
        _buildSummaryRow(theme, entryProvider),
        const SizedBox(height: 16),
        _buildStatsRow(theme, entryProvider),
        const SizedBox(height: 24),
        _buildRecentSection(theme, entryProvider),
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

  Widget _buildSummaryRow(ThemeData theme, EntryProvider provider) {
    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            title: 'Total Borrowed',
            amount: provider.totalBorrowed,
            icon: Icons.arrow_downward,
            color: Colors.orange.shade700,
            theme: theme,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            title: 'Total Lent',
            amount: provider.totalLent,
            icon: Icons.arrow_upward,
            color: Colors.teal.shade600,
            theme: theme,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow(ThemeData theme, EntryProvider provider) {
    return Row(
      children: [
        Expanded(
          child: _StatsCard(
            label: 'Pending',
            count: provider.pendingCount,
            icon: Icons.hourglass_empty,
            color: Colors.indigo,
            theme: theme,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatsCard(
            label: 'Deadlines (7d)',
            count: provider.upcomingDeadlineCount,
            icon: Icons.event,
            color: Colors.purple,
            theme: theme,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentSection(ThemeData theme, EntryProvider provider) {
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
                    color: Colors.grey[500],
                  ),
                ),
              ),
            ),
          )
        else
          ...recent.map((entry) => _RecentEntryTile(entry: entry, theme: theme)),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final double amount;
  final IconData icon;
  final Color color;
  final ThemeData theme;

  const _SummaryCard({
    required this.title,
    required this.amount,
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
              '\$${amount.toStringAsFixed(2)}',
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
  final BorrowLend entry;
  final ThemeData theme;

  const _RecentEntryTile({required this.entry, required this.theme});

  @override
  Widget build(BuildContext context) {
    final isBorrow = entry.type == EntryType.borrow;
    final entryColor = isBorrow ? Colors.orange.shade700 : Colors.teal.shade600;
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
        subtitle: Text(_daysAgo(entry.createdAt)),
        trailing: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '$sign\$${entry.amount.toStringAsFixed(2)}',
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
      child: Text(
        label,
        style: TextStyle(fontSize: 11, color: color),
      ),
    );
  }
}
