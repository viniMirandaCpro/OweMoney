import 'package:flutter/material.dart';
import 'package:drift/drift.dart' as drift;
import '../database/database.dart';
import '../widgets/person_tile.dart';
import '../widgets/add_person_dialog.dart';
import '../utils/currency_formatter.dart';
import 'owe_page.dart';

/// Main page displaying the list of people (WhatsApp-style)
/// 
/// Features:
/// - StreamBuilder consuming real-time database updates
/// - Floating action button to add new people
/// - Total balance display in AppBar
/// - Smooth animations following Apple HIG
/// - Navigation to detail page
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  late final AppDatabase _database;
  late final AnimationController _fabAnimationController;

  @override
  void initState() {
    super.initState();
    
    // Initialize the database
    _database = AppDatabase();
    
    // Setup FAB animation controller for spring animation
    _fabAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fabAnimationController.forward();
  }

  @override
  void dispose() {
    _database.close();
    _fabAnimationController.dispose();
    super.dispose();
  }

  /// Shows dialog to add a new person
  Future<void> _addPerson() async {
    final name = await showAddPersonDialog(context);
    
    if (name != null && mounted) {
      // Insert the new person into the database
      await _database.insertPerson(
        PeopleCompanion(
          name: drift.Value(name),
        ),
      );
      
      // Show confirmation snackbar with Apple-style design
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$name added'),
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

  /// Navigates to the detail page for a person
  void _navigateToPersonDetail(Person person, double totalAmount) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => OwePage(
          person: person,
          database: _database,
          initialTotal: totalAmount,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7), // iOS-style background
      
      // AppBar with total balance
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Text(
          'OweMoney',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.6,
            color: Colors.black,
          ),
        ),
        
        // Display grand total in the AppBar
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
            alignment: Alignment.centerLeft,
            child: StreamBuilder<double>(
              stream: _database.watchGrandTotal(),
              builder: (context, snapshot) {
                final total = snapshot.data ?? 0.0;
                final color = total > 0
                    ? const Color(0xFF34C759)
                    : total < 0
                        ? const Color(0xFFFF3B30)
                        : const Color(0xFF8E8E93);
                
                return Row(
                  children: [
                    Text(
                      'Total balance: ',
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
      
      // Main content: list of people
      body: StreamBuilder<List<Person>>(
        stream: _database.watchAllPeople(),
        builder: (context, snapshot) {
          // Loading state
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF007AFF),
              ),
            );
          }
          
          final people = snapshot.data!;
          
          // Empty state
          if (people.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 80,
                    color: Colors.black.withOpacity(0.2),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No one here yet',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.black.withOpacity(0.3),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add someone to get started',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black.withOpacity(0.4),
                    ),
                  ),
                ],
              ),
            );
          }
          
          // List of people with calculated totals
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: people.length,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              indent: 72,
              color: Colors.black.withOpacity(0.1),
            ),
            itemBuilder: (context, index) {
              final person = people[index];
              
              // Calculate total for this person using StreamBuilder for real-time updates
              return StreamBuilder<double>(
                stream: _database.watchTotalUnpaidForPerson(person.id),
                builder: (context, totalSnapshot) {
                  final total = totalSnapshot.data ?? 0.0;
                  
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
                    child: Container(
                      color: Colors.white,
                      child: PersonTile(
                        id: person.id,
                        name: person.name,
                        totalAmount: total,
                        onTap: () => _navigateToPersonDetail(person, total),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      
      // Floating action button to add new person
      floatingActionButton: ScaleTransition(
        scale: CurvedAnimation(
          parent: _fabAnimationController,
          curve: Curves.elasticOut,
        ),
        child: FloatingActionButton(
          onPressed: _addPerson,
          backgroundColor: const Color(0xFF007AFF),
          foregroundColor: Colors.white,
          elevation: 4,
          child: const Icon(Icons.person_add, size: 28),
        ),
      ),
    );
  }
}


