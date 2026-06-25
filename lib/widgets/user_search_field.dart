import 'dart:async';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

/// A smart searchable text field that queries Firestore users.
/// Shows autocomplete suggestions with loading, no-results, and error states.
/// Locks the field after a user is selected — clear button to search again.
/// When no users found, shows invite options via [onInviteTap].
class UserSearchField extends StatefulWidget {
  final TextEditingController? controller;
  final ValueChanged<String>? onSelected;
  final VoidCallback? onInviteTap;
  final String? hintText;
  final String? labelText;
  final String? Function(String?)? validator;

  const UserSearchField({
    super.key,
    this.controller,
    this.onSelected,
    this.onInviteTap,
    this.hintText,
    this.labelText,
    this.validator,
  });

  @override
  State<UserSearchField> createState() => _UserSearchFieldState();
}

class _UserSearchFieldState extends State<UserSearchField> {
  late final TextEditingController _controller;
  final AuthService _authService = AuthService();
  final LayerLink _layerLink = LayerLink();

  OverlayEntry? _overlayEntry;
  Timer? _debounce;

  bool _isLoading = false;
  String? _error;
  List<UserModel> _suggestions = [];
  String? _selectedUserId;
  bool _showNoResults = false;

  /// Whether a user has been selected and the field is locked.
  bool get _isLocked => _selectedUserId != null;

  /// The UID of the currently selected user, or null if none selected.
  String? get selectedUserId => _selectedUserId;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _controller.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _removeOverlay();
    _controller.removeListener(_onSearchChanged);
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_isLocked) return;
    final query = _controller.text.trim();
    _debounce?.cancel();

    if (query.length < 2) {
      _removeOverlay();
      setState(() {
        _suggestions = [];
        _error = null;
        _showNoResults = false;
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 300), () {
      _searchUsers(query);
    });
  }

  /// Queries Firestore users by displayName or email (case-insensitive).
  Future<void> _searchUsers(String query) async {
    setState(() {
      _isLoading = true;
      _error = null;
      _showNoResults = false;
    });

    try {
      final results = await _authService.searchUsers(query);
      if (!mounted) return;
      setState(() {
        _suggestions = results;
        _isLoading = false;
        _showNoResults = results.isEmpty;
      });
      _showOverlay();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Search failed. Try again.';
        _isLoading = false;
        _suggestions = [];
        _showNoResults = false;
      });
      _showOverlay();
    }
  }

  void _showOverlay() {
    _removeOverlay();
    _overlayEntry = _buildOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  OverlayEntry _buildOverlayEntry() {
    final theme = Theme.of(context);
    final borderRadius = BorderRadius.circular(12);

    return OverlayEntry(
      builder: (context) => Positioned(
        width: 360,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 56),
          child: Material(
            elevation: 4,
            borderRadius: borderRadius,
            color: theme.colorScheme.surface,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 300),
              child: _buildSuggestionList(theme),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestionList(ThemeData theme) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: theme.colorScheme.error, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _error!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_showNoResults && _suggestions.isEmpty) {
      return _buildNoResultsWithInvite(theme);
    }

    if (_suggestions.isEmpty) {
      return const SizedBox.shrink();
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 4),
      shrinkWrap: true,
      itemCount: _suggestions.length,
      itemBuilder: (context, index) {
        final user = _suggestions[index];
        return _UserSuggestionTile(
          user: user,
          onTap: () => _onUserSelected(user),
        );
      },
    );
  }

  Widget _buildNoResultsWithInvite(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.search_off,
                color: theme.colorScheme.onSurfaceVariant,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'No users found',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Invite them to join Borrow Tracker:',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    _removeOverlay();
                    widget.onInviteTap?.call();
                  },
                  icon: const Icon(Icons.qr_code, size: 18),
                  label: const Text('QR Code'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    _removeOverlay();
                    widget.onInviteTap?.call();
                  },
                  icon: const Icon(Icons.share, size: 18),
                  label: const Text('Share Link'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _onUserSelected(UserModel user) {
    _removeOverlay();
    final name = user.displayName ?? user.email;
    setState(() {
      _selectedUserId = user.uid;
      _controller.text = name;
      _suggestions = [];
      _showNoResults = false;
    });
    widget.onSelected?.call(user.uid);
  }

  /// Clears the selection and allows the user to search again.
  void _clearSelection() {
    _removeOverlay();
    _controller.clear();
    setState(() {
      _selectedUserId = null;
      _suggestions = [];
      _error = null;
      _showNoResults = false;
    });
    widget.onSelected?.call('');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CompositedTransformTarget(
      link: _layerLink,
      child: TextFormField(
        controller: _controller,
        readOnly: _isLocked,
        validator: widget.validator,
        textCapitalization: TextCapitalization.words,
        onTap: _isLocked
            ? null
            : () {
                if (_suggestions.isNotEmpty) _showOverlay();
              },
        decoration: InputDecoration(
          labelText: widget.labelText ?? 'Person',
          hintText: _isLocked
              ? ''
              : (widget.hintText ?? 'Search by name or email...'),
          prefixIcon: Icon(
            _isLocked ? Icons.person : Icons.person_search,
            color: _isLocked ? theme.colorScheme.primary : null,
          ),
          suffixIcon: _isLoading
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : _isLocked
                  ? IconButton(
                      icon: const Icon(Icons.close),
                      tooltip: 'Clear selection',
                      onPressed: _clearSelection,
                    )
                  : _controller.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _controller.clear();
                            _removeOverlay();
                            setState(() {
                              _suggestions = [];
                              _showNoResults = false;
                            });
                          },
                        )
                      : null,
          filled: _isLocked,
          fillColor: _isLocked
              ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
              : null,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}

/// A single suggestion tile showing avatar, name, and email.
class _UserSuggestionTile extends StatelessWidget {
  final UserModel user;
  final VoidCallback onTap;

  const _UserSuggestionTile({required this.user, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayName = user.displayName ?? 'Unnamed';

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Text(
                displayName.substring(0, 1).toUpperCase(),
                style: TextStyle(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    displayName,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    user.email,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
