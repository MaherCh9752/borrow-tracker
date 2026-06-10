import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/borrow_lend.dart';
import '../providers/auth_provider.dart';
import '../providers/entry_provider.dart';

class AddEditEntryScreen extends StatefulWidget {
  final BorrowLend? entry;

  const AddEditEntryScreen({super.key, this.entry});

  bool get isEditing => entry != null;

  @override
  State<AddEditEntryScreen> createState() => _AddEditEntryScreenState();
}

class _AddEditEntryScreenState extends State<AddEditEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _personNameController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  late EntryType _type;
  late String _currency;
  late EntryStatus _status;
  late DateTime _createdAt;
  DateTime? _deadline;
  bool _isSaving = false;

  static const List<String> _currencies = ['USD', 'EUR', 'GBP', 'TND'];

  @override
  void initState() {
    super.initState();
    final e = widget.entry;
    _personNameController.text = e?.personName ?? '';
    _amountController.text = e != null ? e.amount.toStringAsFixed(3) : '';
    _notesController.text = e?.notes ?? '';
    _type = e?.type ?? EntryType.borrow;
    _currency = e?.currency ?? 'TND';
    _status = e?.status ?? EntryStatus.pending;
    _createdAt = e?.createdAt ?? DateTime.now();
    _deadline = e?.deadline;
  }

  @override
  void dispose() {
    _personNameController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isDeadline}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isDeadline
          ? (_deadline ?? _createdAt.add(const Duration(days: 7)))
          : _createdAt,
      firstDate: isDeadline ? _createdAt : DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isDeadline) {
          _deadline = picked;
        } else {
          _createdAt = picked;
        }
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isSaving) return;

    setState(() => _isSaving = true);

    try {
      final userId = context.read<AuthProvider>().user!.uid;
      final entryProvider = context.read<EntryProvider>();

      final entry = BorrowLend(
        id: widget.entry?.id ?? '',
        personName: _personNameController.text.trim(),
        amount: double.parse(_amountController.text.trim()),
        currency: _currency,
        type: _type,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        createdAt: _createdAt,
        deadline: _deadline,
        status: _status,
      );

      bool success;
      if (widget.isEditing) {
        success = await entryProvider
            .editEntry(userId: userId, entry: entry)
            .timeout(const Duration(milliseconds: 500));
      } else {
        success = await entryProvider
            .addEntry(userId: userId, entry: entry)
            .timeout(const Duration(milliseconds: 500));
      }

      if (success && mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      // Timeout or error — Firestore still queued the write locally.
      debugPrint('[AddEditEntry] _save: $e');
      if (mounted) {
        Navigator.pop(context, true);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Entry' : 'Add Entry'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSectionLabel(theme, 'Person'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _personNameController,
                decoration: const InputDecoration(
                  labelText: 'Person Name',
                  hintText: 'Enter the person\'s name',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Name is required.';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              _buildSectionLabel(theme, 'Type'),
              const SizedBox(height: 8),
              SegmentedButton<EntryType>(
                segments: const [
                  ButtonSegment(
                    value: EntryType.borrow,
                    label: Text('I Borrowed'),
                    icon: Icon(Icons.arrow_downward),
                  ),
                  ButtonSegment(
                    value: EntryType.lend,
                    label: Text('I Lent'),
                    icon: Icon(Icons.arrow_upward),
                  ),
                ],
                selected: {_type},
                onSelectionChanged: (v) => setState(() => _type = v.first),
              ),
              const SizedBox(height: 20),
              _buildSectionLabel(theme, 'Amount'),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _amountController,
                      decoration: const InputDecoration(
                        labelText: 'Amount',
                        hintText: '0.000',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Amount is required.';
                        }
                        final amount = double.tryParse(v.trim());
                        if (amount == null || amount <= 0) {
                          return 'Enter a valid amount.';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      initialValue: _currency,
                      decoration: const InputDecoration(
                        labelText: 'Currency',
                        border: OutlineInputBorder(),
                      ),
                      items: _currencies
                          .map(
                            (c) => DropdownMenuItem(value: c, child: Text(c)),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v != null) _currency = v;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildSectionLabel(theme, 'Status'),
              const SizedBox(height: 8),
              DropdownButtonFormField<EntryStatus>(
                initialValue: _status,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(
                    value: EntryStatus.pending,
                    child: Text('Pending'),
                  ),
                  DropdownMenuItem(
                    value: EntryStatus.paid,
                    child: Text('Paid'),
                  ),
                  DropdownMenuItem(
                    value: EntryStatus.partial,
                    child: Text('Partial'),
                  ),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _status = v);
                },
              ),
              const SizedBox(height: 20),
              _buildSectionLabel(theme, 'Dates'),
              const SizedBox(height: 8),
              _DateRow(
                label: 'Date',
                date: _createdAt,
                icon: Icons.calendar_today,
                onTap: () => _pickDate(isDeadline: false),
              ),
              const SizedBox(height: 12),
              _DateRow(
                label: 'Deadline',
                date: _deadline,
                icon: Icons.event,
                hint: 'No deadline set',
                onTap: () => _pickDate(isDeadline: true),
                trailing: _deadline != null
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () => setState(() => _deadline = null),
                      )
                    : null,
              ),
              const SizedBox(height: 20),
              _buildSectionLabel(theme, 'Notes'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  hintText: 'Optional notes...',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 32),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  child: _isSaving
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          widget.isEditing ? 'Update Entry' : 'Add Entry',
                          style: const TextStyle(fontSize: 16),
                        ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(ThemeData theme, String label) {
    return Text(
      label,
      style: theme.textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w600,
        color: theme.colorScheme.primary,
      ),
    );
  }
}

class _DateRow extends StatelessWidget {
  final String label;
  final DateTime? date;
  final IconData icon;
  final String? hint;
  final VoidCallback onTap;
  final Widget? trailing;

  const _DateRow({
    required this.label,
    required this.date,
    required this.icon,
    this.hint,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: const OutlineInputBorder(),
          suffixIcon: trailing,
        ),
        child: Text(
          date != null
              ? '${date!.day}/${date!.month}/${date!.year}'
              : (hint ?? 'Not set'),
          style: TextStyle(color: date != null ? null : Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      ),
    );
  }
}
