import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/currency_formatter.dart';
import '../utils/date_formatter.dart';

/// Bottom sheet for adding a new debt/pendência
/// 
/// Features:
/// - Title input
/// - Currency input with real-time formatting
/// - Date picker (defaults to today)
/// - Direction toggle (you owe / they owe you)
/// - Apple-style design with spring animation
class AddDebtBottomSheet extends StatefulWidget {
  /// The name of the person this debt belongs to
  final String personName;

  const AddDebtBottomSheet({
    super.key,
    required this.personName,
  });

  @override
  State<AddDebtBottomSheet> createState() => _AddDebtBottomSheetState();
}

class _AddDebtBottomSheetState extends State<AddDebtBottomSheet> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final FocusNode _titleFocus = FocusNode();
  
  DateTime _selectedDate = DateFormatter.today();
  bool _theyOweYou = true; // true = positive, false = negative
  
  String? _titleError;
  String? _amountError;

  @override
  void initState() {
    super.initState();
    // Auto-focus the title field when sheet appears
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _titleFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _titleFocus.dispose();
    super.dispose();
  }

  /// Validates all inputs and returns the debt data if valid
  /// Returns null if validation fails
  Map<String, dynamic>? _validateAndGetData() {
    final title = _titleController.text.trim();
    final amountText = _amountController.text.trim();
    
    bool hasError = false;
    
    // Validate title
    if (title.isEmpty) {
      setState(() {
        _titleError = 'Enter a title';
      });
      hasError = true;
    }
    
    // Validate amount
    if (amountText.isEmpty) {
      setState(() {
        _amountError = 'Enter an amount';
      });
      hasError = true;
    } else {
      final amount = CurrencyFormatter.parse(amountText);
      if (amount == null || amount <= 0) {
        setState(() {
          _amountError = 'Invalid amount';
        });
        hasError = true;
      }
    }
    
    if (hasError) return null;
    
    // Parse the amount and apply direction
    double amount = CurrencyFormatter.parse(amountText)!;
    if (!_theyOweYou) {
      amount = -amount; // Negative if you owe them
    }
    
    return {
      'title': title,
      'amount': amount,
      'date': _selectedDate,
    };
  }

  /// Handles the add button press
  void _handleAdd() {
    final data = _validateAndGetData();
    if (data != null) {
      Navigator.of(context).pop(data);
    }
  }

  /// Shows the date picker
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF007AFF), // iOS blue
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar (visual indicator for draggable sheet)
              Center(
                child: Container(
                  width: 36,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Title
              Text(
                'New Debt',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.6,
                ),
              ),
              
              Text(
                widget.personName,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black.withOpacity(0.5),
                  fontWeight: FontWeight.w500,
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Title input
              TextField(
                controller: _titleController,
                focusNode: _titleFocus,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: 'Title',
                  hintText: 'e.g., Lunch, Loan...',
                  errorText: _titleError,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF007AFF),
                      width: 2,
                    ),
                  ),
                ),
                onChanged: (_) {
                  if (_titleError != null) {
                    setState(() => _titleError = null);
                  }
                },
              ),
              
              const SizedBox(height: 16),
              
              // Amount input
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                decoration: InputDecoration(
                  labelText: 'Amount',
                  hintText: 'R\$ 0,00',
                  errorText: _amountError,
                  prefixIcon: const Icon(Icons.attach_money),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF007AFF),
                      width: 2,
                    ),
                  ),
                ),
                onChanged: (value) {
                  if (_amountError != null) {
                    setState(() => _amountError = null);
                  }
                  
                  // Format the input as currency
                  if (value.isNotEmpty) {
                    final formatted = CurrencyFormatter.formatInput(value);
                    if (formatted != value) {
                      _amountController.value = TextEditingValue(
                        text: formatted,
                        selection: TextSelection.collapsed(
                          offset: formatted.length,
                        ),
                      );
                    }
                  }
                },
              ),
              
              const SizedBox(height: 16),
              
              // Date picker button
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.black.withOpacity(0.2),
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        'Date: ${DateFormatter.format(_selectedDate)}',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Direction toggle
              Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _DirectionButton(
                        label: '${widget.personName} owes',
                        icon: Icons.arrow_downward,
                        isSelected: _theyOweYou,
                        color: const Color(0xFF34C759),
                        onTap: () => setState(() => _theyOweYou = true),
                      ),
                    ),
                    Expanded(
                      child: _DirectionButton(
                        label: 'You owe',
                        icon: Icons.arrow_upward,
                        isSelected: !_theyOweYou,
                        color: const Color(0xFFFF3B30),
                        onTap: () => setState(() => _theyOweYou = false),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Add button
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _handleAdd,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF007AFF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Add Debt',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

/// A button for selecting the debt direction (they owe / you owe)
class _DirectionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _DirectionButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? color : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : Colors.black.withOpacity(0.5),
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black.withOpacity(0.5),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shows the add debt bottom sheet and returns the debt data if added
/// 
/// Returns null if cancelled
/// Returns Map with keys: 'title', 'amount', 'date'
Future<Map<String, dynamic>?> showAddDebtBottomSheet(
  BuildContext context,
  String personName,
) {
  return showModalBottomSheet<Map<String, dynamic>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => AddDebtBottomSheet(personName: personName),
  );
}


