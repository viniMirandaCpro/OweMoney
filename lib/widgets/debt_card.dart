import 'package:flutter/material.dart';
import '../utils/currency_formatter.dart';
import '../utils/date_formatter.dart';

/// A card displaying a single debt/pendência
/// 
/// Features:
/// - Title, amount, and date
/// - Visual indication of paid/unpaid status
/// - Swipe-to-toggle functionality
/// - Color-coded amounts (green/red)
/// - Reduced opacity for paid debts
class DebtCard extends StatelessWidget {
  /// The debt's unique identifier
  final int id;
  
  /// Title/description of the debt
  final String title;
  
  /// Amount (positive = they owe you, negative = you owe them)
  final double amount;
  
  /// Date the debt was incurred
  final DateTime date;
  
  /// Whether this debt has been marked as paid
  final bool isPaid;
  
  /// Callback when the paid status is toggled
  final Function(bool) onTogglePaid;

  const DebtCard({
    super.key,
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.isPaid,
    required this.onTogglePaid,
  });

  /// Determines the color based on the amount
  Color _getAmountColor() {
    if (amount > 0) {
      return const Color(0xFF34C759); // iOS green
    } else if (amount < 0) {
      return const Color(0xFFFF3B30); // iOS red
    } else {
      return const Color(0xFF8E8E93); // iOS gray
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key('debt_$id'),
      // Swipe to toggle paid/unpaid status
      confirmDismiss: (direction) async {
        // Toggle the status instead of dismissing
        onTogglePaid(!isPaid);
        return false; // Don't actually dismiss
      },
      background: Container(
        decoration: BoxDecoration(
          color: isPaid 
              ? const Color(0xFFFF9500) // Orange for "mark as unpaid"
              : const Color(0xFF34C759), // Green for "mark as paid"
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        child: Row(
          children: [
            Icon(
              isPaid ? Icons.refresh : Icons.check_circle,
              color: Colors.white,
              size: 28,
            ),
            const SizedBox(width: 8),
            Text(
              isPaid ? 'Mark unpaid' : 'Mark paid',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      secondaryBackground: Container(
        decoration: BoxDecoration(
          color: isPaid 
              ? const Color(0xFFFF9500)
              : const Color(0xFF34C759),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              isPaid ? 'Mark unpaid' : 'Mark paid',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              isPaid ? Icons.refresh : Icons.check_circle,
              color: Colors.white,
              size: 28,
            ),
          ],
        ),
      ),
      child: Opacity(
        // Reduce opacity for paid debts to show they're "done"
        opacity: isPaid ? 0.5 : 1.0,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            // Subtle shadow following Apple's design language
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                // Quick tap toggles paid status
                onTogglePaid(!isPaid);
              },
              borderRadius: BorderRadius.circular(12),
              highlightColor: Colors.black.withOpacity(0.03),
              splashColor: Colors.black.withOpacity(0.05),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Status icon
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isPaid
                            ? const Color(0xFF34C759).withOpacity(0.15)
                            : _getAmountColor().withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isPaid ? Icons.check_circle : Icons.pending_outlined,
                        color: isPaid
                            ? const Color(0xFF34C759)
                            : _getAmountColor(),
                        size: 22,
                      ),
                    ),
                    
                    const SizedBox(width: 12),
                    
                    // Title and date
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title with strikethrough if paid
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.3,
                              decoration: isPaid
                                  ? TextDecoration.lineThrough
                                  : TextDecoration.none,
                              decorationColor: Colors.black.withOpacity(0.4),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          
                          const SizedBox(height: 4),
                          
                          // Date
                          Text(
                            DateFormatter.formatRelative(date),
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black.withOpacity(0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(width: 12),
                    
                    // Amount
                    Text(
                      CurrencyFormatter.formatAbsolute(amount),
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: _getAmountColor(),
                        letterSpacing: -0.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}


