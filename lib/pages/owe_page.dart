import 'package:flutter/material.dart';
import 'package:drift/drift.dart' as drift;
import '../database/database.dart';
import '../widgets/debt_card.dart';
import '../widgets/add_debt_bottom_sheet.dart';
import '../utils/currency_formatter.dart';

/// Detail page showing all debts for a specific person
/// 
/// Features:
/// - StreamBuilder consuming real-time debt updates
/// - Swipe actions to mark debts as paid/unpaid
/// - Floating action button to add new debts
/// - Visual distinction between paid and unpaid debts
/// - Hero animation from home page avatar
class OwePage extends StatefulWidget {
  /// The person whose debts are being displayed
  final Person person;
  
  /// Database instance (passed from home page to avoid multiple connections)
  final AppDatabase database;
  
  /// Initial total amount (for immediate display before stream updates)
  final double initialTotal;

  const OwePage({
    super.key,
    required this.person,
    required this.database,
    required this.initialTotal,
  });

  @override
  State<OwePage> createState() => _OwePageState();
}

class _OwePageState extends State<OwePage> with SingleTickerProviderStateMixin {
  late final AnimationController _fabAnimationController;

  @override
  void initState() {
    super.initState();
    
    // Setup FAB animation controller for spring animation
    _fabAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fabAnimationController.forward();
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    super.dispose();
  }

  /// Shows bottom sheet to add a new debt
  Future<void> _addDebt() async {
    final result = await showAddDebtBottomSheet(context, widget.person.name);
    
    if (result != null && mounted) {
      // Insert the new debt into the database
      await widget.database.insertDebt(
        DebtsCompanion(
          personId: drift.Value(widget.person.id),
          title: drift.Value(result['title'] as String),
          amount: drift.Value(result['amount'] as double),
          date: drift.Value(result['date'] as DateTime),
        ),
      );
      
      // Show confirmation snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Debt added'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  /// Toggles the paid status of a debt
  Future<void> _toggleDebtPaid(int debtId, bool isPaid) async {
    await widget.database.toggleDebtPaidStatus(debtId, isPaid);
  }

  /// Extracts the first letter of the name for the avatar
  String get _initial {
    return widget.person.name.isNotEmpty 
        ? widget.person.name[0].toUpperCase() 
        : '?';
  }

  /// Generates avatar color based on person's name
  Color _getAvatarColor() {
    int hash = widget.person.name.hashCode;
    
    final colors = [
      const Color(0xFF007AFF), // iOS blue
      const Color(0xFF5856D6), // iOS purple
      const Color(0xFFAF52DE), // iOS violet
      const Color(0xFFFF2D55), // iOS pink
      const Color(0xFFFF9500), // iOS orange
      const Color(0xFFFFCC00), // iOS yellow
      const Color(0xFF34C759), // iOS green
      const Color(0xFF00C7BE), // iOS teal
    ];
    
    return colors[hash.abs() % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7), // iOS-style background
      
      // AppBar with person's name and total
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF007AFF)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            // Hero animation from home page
            Hero(
              tag: 'person_avatar_${widget.person.id}',
              child: CircleAvatar(
                radius: 20,
                backgroundColor: _getAvatarColor(),
                child: Text(
                  _initial,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.person.name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.4,
                  color: Colors.black,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        
        // Display total for this person
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
            alignment: Alignment.centerLeft,
            child: StreamBuilder<double>(
              stream: widget.database.watchTotalUnpaidForPerson(widget.person.id),
              builder: (context, snapshot) {
                final total = snapshot.data ?? widget.initialTotal;
                final color = total > 0
                    ? const Color(0xFF34C759)
                    : total < 0
                        ? const Color(0xFFFF3B30)
                        : const Color(0xFF8E8E93);
                
                String label;
                if (total > 0) {
                  label = 'owes you';
                } else if (total < 0) {
                  label = 'you owe';
                } else {
                  label = 'nothing pending';
                }
                
                return Row(
                  children: [
                    Text(
                      '$label: ',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.black.withOpacity(0.6),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      CurrencyFormatter.formatAbsolute(total),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
      
      // Main content: list of debts
      body: StreamBuilder<List<Debt>>(
        stream: widget.database.watchDebtsForPerson(widget.person.id),
        builder: (context, snapshot) {
          // Loading state
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF007AFF),
              ),
            );
          }
          
          final debts = snapshot.data!;
          
          // Empty state
          if (debts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 80,
                    color: Colors.black.withOpacity(0.2),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No debts yet',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.black.withOpacity(0.3),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add one to get started',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black.withOpacity(0.4),
                    ),
                  ),
                ],
              ),
            );
          }
          
          // List of debts
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: debts.length,
            itemBuilder: (context, index) {
              final debt = debts[index];
              
              // Animate entry with slide + fade
              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: Duration(milliseconds: 300 + (index * 50)),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, 20 * (1 - value)),
                      child: child,
                    ),
                  );
                },
                child: DebtCard(
                  id: debt.id,
                  title: debt.title,
                  amount: debt.amount,
                  date: debt.date,
                  isPaid: debt.isPaid,
                  onTogglePaid: (isPaid) => _toggleDebtPaid(debt.id, isPaid),
                ),
              );
            },
          );
        },
      ),
      
      // Floating action button to add new debt
      floatingActionButton: ScaleTransition(
        scale: CurvedAnimation(
          parent: _fabAnimationController,
          curve: Curves.elasticOut,
        ),
        child: FloatingActionButton(
          onPressed: _addDebt,
          backgroundColor: const Color(0xFF007AFF),
          foregroundColor: Colors.white,
          elevation: 4,
          child: const Icon(Icons.add, size: 28),
        ),
      ),
    );
  }
}