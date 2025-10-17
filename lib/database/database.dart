import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'database.g.dart';

// Type aliases for easier use throughout the app
typedef Person = PeopleData;

/// Table definition for people/contacts who owe or are owed money
/// 
/// Each person represents a contact in the WhatsApp-style list
/// The actual debt amounts are calculated from the Debts table
class People extends Table {
  // Auto-incrementing primary key
  IntColumn get id => integer().autoIncrement()();
  
  // Person's name (required, cannot be empty)
  TextColumn get name => text().withLength(min: 1, max: 100)();
  
  // Timestamp when this person was added to the database
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// Table definition for individual debts/pendências
/// 
/// Each debt belongs to a person and can be marked as paid or unpaid
/// Positive amounts = they owe you
/// Negative amounts = you owe them
class Debts extends Table {
  // Auto-incrementing primary key
  IntColumn get id => integer().autoIncrement()();
  
  // Foreign key to People table
  IntColumn get personId => integer().references(People, #id, onDelete: KeyAction.cascade)();
  
  // Title/description of the debt
  TextColumn get title => text().withLength(min: 1, max: 200)();
  
  // Amount (positive = they owe you, negative = you owe them)
  RealColumn get amount => real()();
  
  // Date of the debt (when it was incurred)
  DateTimeColumn get date => dateTime()();
  
  // Whether this debt has been marked as paid
  BoolColumn get isPaid => boolean().withDefault(const Constant(false))();
  
  // Timestamp when this debt was created in the database
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// Main database class using Drift ORM
/// 
/// This database manages all data persistence for the OweMoney app
/// using SQLite with Drift as the abstraction layer
@DriftDatabase(tables: [People, Debts])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  // ============================================================
  // PEOPLE QUERIES
  // ============================================================

  /// Get all people ordered by name
  /// 
  /// Returns a stream that automatically updates when data changes
  Stream<List<Person>> watchAllPeople() {
    return select(people).watch();
  }

  /// Get a single person by ID
  Future<Person> getPerson(int id) {
    return (select(people)..where((p) => p.id.equals(id))).getSingle();
  }

  /// Insert a new person
  /// 
  /// Returns the ID of the newly created person
  Future<int> insertPerson(PeopleCompanion person) {
    return into(people).insert(person);
  }

  /// Update an existing person
  Future<bool> updatePerson(Person person) {
    return update(people).replace(person);
  }

  /// Delete a person (and all their debts due to cascade)
  Future<int> deletePerson(int id) {
    return (delete(people)..where((p) => p.id.equals(id))).go();
  }

  // ============================================================
  // DEBTS QUERIES
  // ============================================================

  /// Get all debts for a specific person, ordered by date (newest first)
  /// 
  /// Returns a stream that automatically updates when data changes
  Stream<List<Debt>> watchDebtsForPerson(int personId) {
    return (select(debts)
          ..where((d) => d.personId.equals(personId))
          ..orderBy([(d) => OrderingTerm.desc(d.date)]))
        .watch();
  }

  /// Get unpaid debts only for a specific person
  Stream<List<Debt>> watchUnpaidDebtsForPerson(int personId) {
    return (select(debts)
          ..where((d) => d.personId.equals(personId) & d.isPaid.equals(false))
          ..orderBy([(d) => OrderingTerm.desc(d.date)]))
        .watch();
  }

  /// Insert a new debt
  /// 
  /// Returns the ID of the newly created debt
  Future<int> insertDebt(DebtsCompanion debt) {
    return into(debts).insert(debt);
  }

  /// Update an existing debt
  Future<bool> updateDebt(Debt debt) {
    return update(debts).replace(debt);
  }

  /// Toggle the paid status of a debt
  /// 
  /// Convenience method for marking debts as paid/unpaid
  Future<int> toggleDebtPaidStatus(int debtId, bool isPaid) {
    return (update(debts)..where((d) => d.id.equals(debtId)))
        .write(DebtsCompanion(isPaid: Value(isPaid)));
  }

  /// Delete a debt
  Future<int> deleteDebt(int id) {
    return (delete(debts)..where((d) => d.id.equals(id))).go();
  }

  // ============================================================
  // AGGREGATION QUERIES
  // ============================================================

  /// Calculate total unpaid debt for a specific person
  /// 
  /// Positive = they owe you
  /// Negative = you owe them
  Future<double> getTotalUnpaidForPerson(int personId) async {
    final result = await (select(debts)
          ..where((d) => d.personId.equals(personId) & d.isPaid.equals(false)))
        .get();

    // Sum up all unpaid debt amounts
    return result.fold<double>(0, (sum, debt) => sum + debt.amount);
  }

  /// Calculate total of ALL debts for a specific person (including paid)
  Future<double> getTotalForPerson(int personId) async {
    final result = await (select(debts)
          ..where((d) => d.personId.equals(personId)))
        .get();

    return result.fold<double>(0, (sum, debt) => sum + debt.amount);
  }

  /// Calculate grand total across all people (unpaid only)
  Future<double> getGrandTotal() async {
    final result = await (select(debts)
          ..where((d) => d.isPaid.equals(false)))
        .get();

    return result.fold<double>(0, (sum, debt) => sum + debt.amount);
  }

  // ============================================================
  // STREAM AGGREGATION QUERIES (for real-time updates)
  // ============================================================

  /// Watch total unpaid debt for a specific person (Stream version)
  /// 
  /// This stream automatically updates when debts change
  Stream<double> watchTotalUnpaidForPerson(int personId) {
    return (select(debts)
          ..where((d) => d.personId.equals(personId) & d.isPaid.equals(false)))
        .watch()
        .map((debts) => debts.fold<double>(0, (sum, debt) => sum + debt.amount));
  }

  /// Watch grand total across all people (Stream version)
  /// 
  /// This stream automatically updates when any debt changes
  Stream<double> watchGrandTotal() {
    return (select(debts)..where((d) => d.isPaid.equals(false)))
        .watch()
        .map((debts) => debts.fold<double>(0, (sum, debt) => sum + debt.amount));
  }
}

/// Helper function to open the database connection
/// 
/// Uses DriftFlutter for optimal performance on mobile platforms
QueryExecutor _openConnection() {
  return driftDatabase(name: 'owemoney_db');
}

