import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../models/pending_invite_model.dart';

/// Screen showing the generated invite QR code and shareable invite code.
class InvitePreviewScreen extends StatelessWidget {
  final PendingInvite invite;
  final String targetPersonName;

  const InvitePreviewScreen({
    super.key,
    required this.invite,
    required this.targetPersonName,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final qrData = 'https://borrowtracker.app/download';

    return Scaffold(
      appBar: AppBar(title: const Text('Invite')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Invite $targetPersonName',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Share this invite so they can join Borrow Tracker and start tracking debts with you.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 32),
          Center(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: QrImageView(
                data: qrData,
                version: QrVersions.auto,
                size: 200,
                backgroundColor: Colors.white,
                foregroundColor: theme.colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Scan this QR code to download the app',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 32),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    'Or share this invite code',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    invite.inviteCode,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Expires in 7 days',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
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
                child: FilledButton.icon(
                  onPressed: () => _shareInvite(context),
                  icon: const Icon(Icons.share, size: 18),
                  label: const Text('Share Invite'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _copyCode(BuildContext context) {
    Clipboard.setData(ClipboardData(text: invite.inviteCode));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Invite code copied')),
    );
  }

  void _shareInvite(BuildContext context) {
    final text = 'Hey! Join me on Borrow Tracker.\n\n'
        'Use invite code: ${invite.inviteCode}\n\n'
        'Download the app at https://borrowtracker.app/download '
        'and enter this code when signing up.';
    Share.share(text);
  }
}
