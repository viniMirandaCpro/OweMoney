import 'package:flutter/material.dart';
import '../utils/currency_formatter.dart';

/// A WhatsApp-style tile for displaying a person in the list
/// 
/// Features:
/// - Circular avatar with person's initial
/// - Person's name in bold
/// - Total amount owed (color-coded: green if they owe you, red if you owe them)
/// - Tap ripple effect following Apple HIG touch feedback guidelines
class PersonTile extends StatelessWidget {
  /// The person's unique identifier
  final int id;
  
  /// The person's name
  final String name;
  
  /// Total amount (positive = they owe you, negative = you owe them)
  final double totalAmount;
  
  /// Callback when the tile is tapped
  final VoidCallback onTap;

  const PersonTile({
    super.key,
    required this.id,
    required this.name,
    required this.totalAmount,
    required this.onTap,
  });

  /// Extracts the first letter of the name for the avatar
  String get _initial {
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  /// Determines the color based on the amount
  /// Green = they owe you (positive)
  /// Red = you owe them (negative)
  /// Gray = balanced/zero
  Color _getAmountColor() {
    if (totalAmount > 0) {
      return const Color(0xFF34C759); // iOS green
    } else if (totalAmount < 0) {
      return const Color(0xFFFF3B30); // iOS red
    } else {
      return const Color(0xFF8E8E93); // iOS gray
    }
  }

  /// Generates a color for the avatar based on the person's name
  /// This ensures each person has a consistent, unique color
  Color _getAvatarColor() {
    // Simple hash function based on name
    int hash = name.hashCode;
    
    // List of pleasant, saturated colors following Apple's design language
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        // Apple-style highlight color (subtle, not too aggressive)
        highlightColor: Colors.black.withOpacity(0.05),
        splashColor: Colors.black.withOpacity(0.1),
        child: Padding(
          // Comfortable padding following 8px grid system
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            children: [
              // Avatar with person's initial
              Hero(
                tag: 'person_avatar_$id',
                child: CircleAvatar(
                  radius: 28, // 56x56 total, above minimum 44pt touch target
                  backgroundColor: _getAvatarColor(),
                  child: Text(
                    _initial,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Name and amount
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Person's name
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.4, // Apple-style tight tracking
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 2),
                    
                    // Amount indicator text
                    Text(
                      totalAmount > 0
                          ? 'owes you'
                          : totalAmount < 0
                              ? 'you owe'
                              : 'nothing pending',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Total amount (right-aligned)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    CurrencyFormatter.formatAbsolute(totalAmount),
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: _getAmountColor(),
                      letterSpacing: -0.4,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}


