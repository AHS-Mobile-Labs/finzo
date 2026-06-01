import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../models/transaction_model.dart';
import '../models/account_model.dart';
import '../models/category_model.dart';
import '../models/budget_model.dart';
import '../models/loan_model.dart';
import '../models/investment_model.dart';

class DatabaseService {
  static DatabaseService? _instance;
  static Database? _database;
  static String? _currentBookName;
  static bool _isInitializing = false;
  static Completer<Database>? _initCompleter;
  static const MethodChannel _storageChannel = MethodChannel(
    'com.ahsmobilelabs.finzo/storage',
  );

  DatabaseService._();
  static DatabaseService get instance => _instance ??= DatabaseService._();

  static void _log(String message) {
    if (kDebugMode) debugPrint(message);
  }

  /// The name of the currently open book
  String? get currentBookName => _currentBookName;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    // If already initializing, wait for that initialization
    if (_isInitializing) {
      if (_initCompleter != null) {
        try {
          return await _initCompleter!.future.timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw TimeoutException('Database initialization timed out');
            },
          );
        } catch (e) {
          _log('[DB] Error waiting for init: $e');
          _isInitializing = false;
          _initCompleter = null;
          rethrow;
        }
      }
    }

    if (_database != null) {
      return _database!;
    }

    _isInitializing = true;
    _initCompleter = Completer<Database>();
    try {
      _database = await _initDatabase().timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          throw TimeoutException('Database initialization exceeded 60 seconds');
        },
      );
      _log('[DB] Database initialized successfully');
      _initCompleter?.complete(_database!);
      return _database!;
    } catch (e) {
      _log('[DB] Error initializing database: $e');
      _database = null;
      _initCompleter?.completeError(e);
      rethrow;
    } finally {
      _isInitializing = false;
      _initCompleter = null;
    }
  }

  /// Returns Finzo's database directory.
  ///
  /// Android first tries the shared device Documents folder so the database is
  /// outside Android/data. iOS uses the app Documents folder, which is exposed
  /// in Files through Info.plist.
  static Future<String> get finzoDir async {
    final preferredDir = await _preferredDocumentsDirectory();
    if (preferredDir != null && await _ensureWritable(preferredDir)) {
      _log('[DB] Using Finzo documents directory: ${preferredDir.path}');
      return preferredDir.path;
    }

    final fallbackDir = await _fallbackDocumentsDirectory();
    if (await _ensureWritable(fallbackDir)) {
      _log('[DB] Using fallback documents directory: ${fallbackDir.path}');
      return fallbackDir.path;
    }

    throw FileSystemException(
      'Unable to create a writable Finzo database directory',
      fallbackDir.path,
    );
  }

  static Future<Directory?> _preferredDocumentsDirectory() async {
    if (Platform.isAndroid) {
      try {
        final root = await _storageChannel.invokeMethod<String>(
          'getDocumentsDirectory',
        );
        if (root != null && root.trim().isNotEmpty) {
          return Directory(p.join(root, 'Finzo'));
        }
      } on MissingPluginException catch (e) {
        _log('[DB] Android documents channel missing: $e');
      } on PlatformException catch (e) {
        _log('[DB] Android documents directory unavailable: ${e.message}');
      } catch (e) {
        _log('[DB] Error resolving Android documents directory: $e');
      }
    }

    if (Platform.isIOS) {
      final docs = await getApplicationDocumentsDirectory();
      return Directory(p.join(docs.path, 'Finzo'));
    }

    try {
      final docs = await getApplicationDocumentsDirectory();
      return Directory(p.join(docs.path, 'Finzo'));
    } catch (e) {
      _log('[DB] Preferred documents directory unavailable: $e');
      return null;
    }
  }

  static Future<Directory> _fallbackDocumentsDirectory() async {
    final docs = await getApplicationDocumentsDirectory();
    return Directory(p.join(docs.path, 'Finzo'));
  }

  static Future<bool> _ensureWritable(Directory dir) async {
    try {
      if (!await dir.exists()) {
        await dir.create(recursive: true);
        _log('[DB] Created Finzo directory: ${dir.path}');
      }

      final probe = File(p.join(dir.path, '.finzo_write_test'));
      await probe.writeAsString(DateTime.now().toIso8601String(), flush: true);
      if (await probe.exists()) {
        await probe.delete();
      }
      return true;
    } catch (e) {
      _log('[DB] Directory is not writable (${dir.path}): $e');
      return false;
    }
  }

  /// Migrate data from older app-scoped locations into the active documents
  /// directory.
  static Future<void> migrateToDocumentsStorage() async {
    final targetDir = Directory(await finzoDir);
    final targetPath = p.normalize(targetDir.path);
    final sources = <Directory>[];

    try {
      final docs = await getApplicationDocumentsDirectory();
      sources.add(Directory(p.join(docs.path, 'finzo')));
      sources.add(Directory(p.join(docs.path, 'Finzo')));
    } catch (e) {
      _log('[DB] Could not inspect legacy documents directory: $e');
    }

    if (Platform.isAndroid) {
      try {
        final cache = await getApplicationCacheDirectory();
        sources.add(Directory(p.join(cache.parent.path, 'files', 'finzo')));
        sources.add(Directory(p.join(cache.parent.path, 'files', 'Finzo')));
      } catch (e) {
        _log('[DB] Could not inspect legacy files directory: $e');
      }

      try {
        final externalDirs = await getExternalStorageDirectories(
          type: StorageDirectory.documents,
        );
        for (final externalDir in externalDirs ?? const <Directory>[]) {
          sources.add(Directory(p.join(externalDir.path, 'finzo')));
          sources.add(Directory(p.join(externalDir.path, 'Finzo')));
        }
      } catch (e) {
        _log('[DB] Could not inspect app-specific external directory: $e');
      }
    }

    final seen = <String>{targetPath};

    for (final sourceDir in sources) {
      final sourcePath = p.normalize(sourceDir.path);
      if (!seen.add(sourcePath)) continue;
      if (!await sourceDir.exists()) continue;

      await for (final entity in sourceDir.list()) {
        if (entity is File) {
          final name = p.basename(entity.path);
          if (!name.endsWith('.books.db') && name != '.onboarded') continue;

          final dest = File(p.join(targetDir.path, name));
          if (!await dest.exists()) {
            await entity.copy(dest.path);
          }
        }
      }
    }
  }

  static Future<void> migrateToAppStorage() => migrateToDocumentsStorage();

  /// Check if onboarding is complete (marker file in finzo dir)
  static Future<bool> isOnboarded() async {
    final dir = await finzoDir;
    final marker = File(p.join(dir, '.onboarded'));
    return marker.exists();
  }

  /// Mark onboarding as complete
  static Future<void> markOnboarded() async {
    final dir = await finzoDir;
    final marker = File(p.join(dir, '.onboarded'));
    await marker.writeAsString(DateTime.now().toIso8601String());
  }

  /// Get the full path of the currently open database
  Future<String?> get currentDbPath async {
    if (_currentBookName == null) return null;
    return pathForBook(_currentBookName!);
  }

  /// Returns the full path for a given book name
  static Future<String> pathForBook(String bookName) async {
    final dir = await finzoDir;
    final safe = bookName.replaceAll(RegExp(r'[^\w\s\-]'), '').trim();
    return p.join(dir, '$safe.books.db');
  }

  /// List all .books.db files in finzo directory
  static Future<List<String>> listBooks() async {
    final dir = Directory(await finzoDir);
    if (!await dir.exists()) return [];
    final files = await dir
        .list()
        .where((f) => f.path.endsWith('.books.db'))
        .map((f) => p.basenameWithoutExtension(f.path).replaceAll('.books', ''))
        .toList();
    return files;
  }

  /// Open a specific book database by name
  Future<void> openBook(String bookName) async {
    try {
      if (_database != null) {
        await _database!.close();
      }
    } catch (e) {
      _log('Error closing previous database: $e');
    } finally {
      _database = null;
    }
    final path = await pathForBook(bookName);
    _database = await openDatabase(
      path,
      version: 5,
      onCreate: _createTables,
      onUpgrade: _onUpgrade,
    );
    _currentBookName = bookName;
  }

  /// Create a new book database
  Future<void> createBook(String bookName) async {
    await openBook(bookName);
  }

  /// Import a .books.db file from the given source path
  static Future<String> importBook(String sourcePath) async {
    final file = File(sourcePath);
    if (!await file.exists()) throw Exception('File not found');
    final name = p
        .basenameWithoutExtension(sourcePath)
        .replaceAll('.books', '');
    final destPath = await pathForBook(name);
    await file.copy(destPath);
    return name;
  }

  /// Delete a book database by name
  Future<void> deleteBook(String bookName) async {
    // Don't delete the currently open book
    if (_currentBookName == bookName && _database != null) {
      await _database!.close();
      _database = null;
      _currentBookName = null;
    }
    final path = await pathForBook(bookName);
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<Database> _initDatabase() async {
    // Default: open first available book, or create 'default'
    try {
      final books = await listBooks();
      var bookName = books.isNotEmpty ? books.first : 'default';

      // Ensure book name is not empty
      if (bookName.isEmpty) {
        bookName = 'default';
      }

      final path = await pathForBook(bookName);
      _log('[DB] Opening database at: $path');
      _currentBookName = bookName;

      final db = await openDatabase(
        path,
        version: 5,
        onCreate: _createTables,
        onUpgrade: _onUpgrade,
      );

      _log('[DB] Database opened successfully: $bookName');
      return db;
    } catch (e) {
      _log('[DB] Fatal error initializing database: $e');
      rethrow;
    }
  }

  Future<void> _createTables(Database db, int version) async {
    try {
      _log('[DB] Creating tables version: $version');

      await db.execute('''
        CREATE TABLE accounts (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          balance REAL NOT NULL DEFAULT 0,
          color INTEGER NOT NULL,
          icon TEXT NOT NULL,
          created_at TEXT NOT NULL
        )
      ''');

      await db.execute('''
        CREATE TABLE categories (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          icon TEXT NOT NULL,
          color INTEGER NOT NULL,
          type TEXT NOT NULL,
          is_default INTEGER NOT NULL DEFAULT 0
        )
      ''');

      await db.execute('''
        CREATE TABLE transactions (
          id TEXT PRIMARY KEY,
          title TEXT NOT NULL,
          amount REAL NOT NULL,
          type TEXT NOT NULL,
          category_id TEXT NOT NULL,
          account_id TEXT NOT NULL,
          related_account_id TEXT,
          date TEXT NOT NULL,
          note TEXT,
          created_at TEXT NOT NULL,
          FOREIGN KEY (category_id) REFERENCES categories(id),
          FOREIGN KEY (account_id) REFERENCES accounts(id),
          FOREIGN KEY (related_account_id) REFERENCES accounts(id)
        )
      ''');

      // Index for faster transaction queries
      await db.execute(
        'CREATE INDEX idx_transactions_date ON transactions(date DESC)',
      );
      await db.execute(
        'CREATE INDEX idx_transactions_type ON transactions(type)',
      );

      await db.execute('''
        CREATE TABLE budgets (
          id TEXT PRIMARY KEY,
          category_id TEXT NOT NULL,
          amount REAL NOT NULL,
          spent REAL NOT NULL DEFAULT 0,
          month INTEGER NOT NULL,
          year INTEGER NOT NULL,
          FOREIGN KEY (category_id) REFERENCES categories(id)
        )
      ''');

      await _createV2Tables(db);
      await _createV3Tables(db);
      await _insertDefaultData(db);

      _log('[DB] Tables created successfully');
    } catch (e) {
      _log('[DB] Error creating tables: $e');
      rethrow;
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    try {
      _log('[DB] Upgrading database from version $oldVersion to $newVersion');

      if (oldVersion < 2) {
        await _createV2Tables(db);
      }
      if (oldVersion < 3) {
        await _createV3Tables(db);
      }
      if (oldVersion < 4) {
        await _createV4Tables(db);
      }
      if (oldVersion < 5) {
        await _migrateIconKeys(db);
      }

      _log('[DB] Database upgrade successful');
    } catch (e) {
      _log('[DB] Error upgrading database: $e');
      rethrow;
    }
  }

  Future<void> _createV3Tables(Database db) async {
    try {
      _log('[DB] Creating V3 tables (credit cards)...');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS credit_cards (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          card_number_last4 TEXT NOT NULL,
          credit_limit REAL NOT NULL,
          used_amount REAL NOT NULL DEFAULT 0,
          billing_day INTEGER NOT NULL DEFAULT 1,
          due_day INTEGER NOT NULL DEFAULT 15,
          color INTEGER NOT NULL,
          icon TEXT NOT NULL DEFAULT 'card',
          note TEXT,
          created_at TEXT NOT NULL
        )
      ''');

      _log('[DB] V3 tables created successfully');
    } catch (e) {
      _log('[DB] Error creating V3 tables: $e');
      rethrow;
    }
  }

  Future<void> _migrateIconKeys(DatabaseExecutor db) async {
    final iconMap = {
      '\u{1F4B0}': 'cash',
      '\u{1F4B5}': 'cash',
      '\u{1F3E6}': 'bank',
      '\u{1F4B3}': 'card',
      '\u{1F3E7}': 'atm',
      '\u{1FA99}': 'coin',
      '\u{1F4CA}': 'chart',
      '\u{1F4C8}': 'trending_up',
      '\u{1F354}': 'restaurant',
      '\u{1F355}': 'pizza',
      '\u{2615}': 'coffee',
      '\u{1F697}': 'car',
      '\u{2708}\u{FE0F}': 'flight',
      '\u{1F3E0}': 'home',
      '\u{1F6CD}\u{FE0F}': 'shopping',
      '\u{1F4A1}': 'utilities',
      '\u{1F3E5}': 'medical',
      '\u{1F3AE}': 'gaming',
      '\u{1F4DA}': 'books',
      '\u{1F4E6}': 'box',
      '\u{1F4BC}': 'work',
      '\u{1F4BB}': 'computer',
      '\u{1F381}': 'gift',
      '\u{1F3B5}': 'music',
      '\u{1F3CB}\u{FE0F}': 'fitness',
      '\u{1F484}': 'beauty',
      '\u{1F43E}': 'pets',
      '\u{26FD}': 'fuel',
      '\u{1F4F1}': 'phone',
      '\u{1F377}': 'bar',
      '\u{1F3AC}': 'movie',
      '\u{1F310}': 'internet',
      '\u{1F504}': 'transfer',
    };

    for (final entry in iconMap.entries) {
      await db.update(
        'categories',
        {'icon': entry.value},
        where: 'icon = ?',
        whereArgs: [entry.key],
      );
      await db.update(
        'accounts',
        {'icon': entry.value},
        where: 'icon = ?',
        whereArgs: [entry.key],
      );
      await db.update(
        'credit_cards',
        {'icon': entry.value},
        where: 'icon = ?',
        whereArgs: [entry.key],
      );
    }
  }

  Future<void> _createV4Tables(Database db) async {
    try {
      _log('[DB] Creating V4 ledger fields...');

      final transactionColumns = await db.rawQuery(
        'PRAGMA table_info(transactions)',
      );
      final hasRelatedAccount = transactionColumns.any(
        (column) => column['name'] == 'related_account_id',
      );
      if (!hasRelatedAccount) {
        await db.execute(
          'ALTER TABLE transactions ADD COLUMN related_account_id TEXT',
        );
      }

      await _upsertTransferCategory(db);

      _log('[DB] V4 ledger fields created successfully');
    } catch (e) {
      _log('[DB] Error creating V4 ledger fields: $e');
      rethrow;
    }
  }

  Future<void> _createV2Tables(Database db) async {
    try {
      _log('[DB] Creating V2 tables (loans, investments)...');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS loans (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          type TEXT NOT NULL,
          principal_amount REAL NOT NULL,
          outstanding_amount REAL NOT NULL,
          interest_rate REAL NOT NULL,
          tenure_months INTEGER NOT NULL,
          emi_amount REAL NOT NULL,
          emi_day INTEGER NOT NULL DEFAULT 1,
          start_date TEXT NOT NULL,
          end_date TEXT,
          account_id TEXT,
          auto_emi INTEGER NOT NULL DEFAULT 1,
          note TEXT,
          created_at TEXT NOT NULL,
          FOREIGN KEY (account_id) REFERENCES accounts(id)
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS investments (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          type TEXT NOT NULL,
          invested_amount REAL NOT NULL,
          current_value REAL NOT NULL,
          units REAL,
          buy_price REAL,
          current_price REAL,
          start_date TEXT NOT NULL,
          note TEXT,
          created_at TEXT NOT NULL
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS settings (
          key TEXT PRIMARY KEY,
          value TEXT NOT NULL
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS emi_log (
          id TEXT PRIMARY KEY,
          loan_id TEXT NOT NULL,
          transaction_id TEXT NOT NULL,
          month INTEGER NOT NULL,
          year INTEGER NOT NULL,
          FOREIGN KEY (loan_id) REFERENCES loans(id),
          FOREIGN KEY (transaction_id) REFERENCES transactions(id)
        )
      ''');

      // Default currency
      await db.insert('settings', {
        'key': 'currency',
        'value': 'INR',
      }, conflictAlgorithm: ConflictAlgorithm.ignore);

      _log('[DB] V2 tables created successfully');
    } catch (e) {
      _log('[DB] Error creating V2 tables: $e');
      rethrow;
    }
  }

  Future<void> _insertDefaultData(Database db) async {
    try {
      _log('[DB] Inserting default data...');
      final now = DateTime.now().toIso8601String();

      final expenseCategories = [
        {
          'id': 'cat_food',
          'name': 'Food & Dining',
          'icon': 'restaurant',
          'color': 0xFFFF6B6B,
          'type': 'expense',
          'is_default': 1,
        },
        {
          'id': 'cat_transport',
          'name': 'Transport',
          'icon': 'car',
          'color': 0xFF4ECDC4,
          'type': 'expense',
          'is_default': 1,
        },
        {
          'id': 'cat_shop',
          'name': 'Shopping',
          'icon': 'shopping',
          'color': 0xFF45B7D1,
          'type': 'expense',
          'is_default': 1,
        },
        {
          'id': 'cat_bills',
          'name': 'Bills & Utilities',
          'icon': 'utilities',
          'color': 0xFFF7DC6F,
          'type': 'expense',
          'is_default': 1,
        },
        {
          'id': 'cat_health',
          'name': 'Health',
          'icon': 'medical',
          'color': 0xFF82E0AA,
          'type': 'expense',
          'is_default': 1,
        },
        {
          'id': 'cat_entertain',
          'name': 'Entertainment',
          'icon': 'gaming',
          'color': 0xFFBB8FCE,
          'type': 'expense',
          'is_default': 1,
        },
        {
          'id': 'cat_edu',
          'name': 'Education',
          'icon': 'books',
          'color': 0xFFFF8C42,
          'type': 'expense',
          'is_default': 1,
        },
        {
          'id': 'cat_other_exp',
          'name': 'Other',
          'icon': 'box',
          'color': 0xFF95A5A6,
          'type': 'expense',
          'is_default': 1,
        },
      ];

      final incomeCategories = [
        {
          'id': 'cat_salary',
          'name': 'Salary',
          'icon': 'work',
          'color': 0xFF2ECC71,
          'type': 'income',
          'is_default': 1,
        },
        {
          'id': 'cat_freelance',
          'name': 'Freelance',
          'icon': 'computer',
          'color': 0xFF3498DB,
          'type': 'income',
          'is_default': 1,
        },
        {
          'id': 'cat_invest',
          'name': 'Investment',
          'icon': 'trending_up',
          'color': 0xFF1ABC9C,
          'type': 'income',
          'is_default': 1,
        },
        {
          'id': 'cat_gift',
          'name': 'Gift',
          'icon': 'gift',
          'color': 0xFFE91E63,
          'type': 'income',
          'is_default': 1,
        },
        {
          'id': 'cat_other_inc',
          'name': 'Other Income',
          'icon': 'cash',
          'color': 0xFFF39C12,
          'type': 'income',
          'is_default': 1,
        },
      ];

      final batch = db.batch();
      for (final cat in [...expenseCategories, ...incomeCategories]) {
        batch.insert('categories', cat);
      }
      batch.insert('categories', _transferCategoryMap());

      batch.insert('accounts', {
        'id': 'acc_cash',
        'name': 'Cash',
        'balance': 0.0,
        'color': 0xFF6C63FF,
        'icon': 'cash',
        'created_at': now,
      });

      batch.insert('accounts', {
        'id': 'acc_bank',
        'name': 'Bank Account',
        'balance': 0.0,
        'color': 0xFF4CAF50,
        'icon': 'bank',
        'created_at': now,
      });

      await batch.commit(noResult: true);
      _log('[DB] Default data inserted successfully');
    } catch (e) {
      _log('[DB] Error inserting default data: $e');
      rethrow;
    }
  }

  // ─── TRANSACTIONS ────────────────────────────────────────────────────────

  static Map<String, Object> _transferCategoryMap() {
    return {
      'id': 'cat_transfer',
      'name': 'Transfer',
      'icon': 'transfer',
      'color': 0xFF6C63FF,
      'type': 'both',
      'is_default': 1,
    };
  }

  Future<void> _upsertTransferCategory(DatabaseExecutor db) async {
    await db.insert(
      'categories',
      _transferCategoryMap(),
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Map<String, double> _accountDeltasFor(TransactionModel tx) {
    if (tx.type == 'transfer') {
      if (tx.relatedAccountId == null || tx.relatedAccountId!.isEmpty) {
        throw ArgumentError('Transfer transactions need a destination account');
      }
      if (tx.relatedAccountId == tx.accountId) {
        throw ArgumentError('Transfer source and destination must differ');
      }
      return {tx.accountId: -tx.amount, tx.relatedAccountId!: tx.amount};
    }

    return {tx.accountId: tx.type == 'income' ? tx.amount : -tx.amount};
  }

  Future<void> _applyAccountDeltas(
    Transaction txn,
    Map<String, double> deltas,
  ) async {
    for (final entry in deltas.entries) {
      await txn.rawUpdate(
        'UPDATE accounts SET balance = balance + ? WHERE id = ?',
        [entry.value, entry.key],
      );
    }
  }

  Map<String, double> _reverseDeltas(Map<String, double> deltas) {
    return deltas.map((accountId, delta) => MapEntry(accountId, -delta));
  }

  Future<List<TransactionModel>> getTransactions({
    DateTime? startDate,
    DateTime? endDate,
    String? type,
    String? accountId,
    String? categoryId,
  }) async {
    final db = await database;
    final whereParts = <String>[];
    final args = <dynamic>[];

    if (startDate != null) {
      whereParts.add('date >= ?');
      args.add(startDate.toIso8601String());
    }
    if (endDate != null) {
      whereParts.add('date <= ?');
      args.add(endDate.toIso8601String());
    }
    if (type != null) {
      whereParts.add('type = ?');
      args.add(type);
    }
    if (accountId != null) {
      whereParts.add('account_id = ?');
      args.add(accountId);
    }
    if (categoryId != null) {
      whereParts.add('category_id = ?');
      args.add(categoryId);
    }

    final maps = await db.query(
      'transactions',
      where: whereParts.isEmpty ? null : whereParts.join(' AND '),
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'date DESC, created_at DESC',
    );

    return maps.map((m) => TransactionModel.fromMap(m)).toList();
  }

  Future<String> insertTransaction(TransactionModel tx) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.insert('transactions', tx.toMap());
      await _applyAccountDeltas(txn, _accountDeltasFor(tx));

      await _updateBudgetSpentInTxn(
        txn,
        tx.categoryId,
        tx.date.month,
        tx.date.year,
      );
    });
    return tx.id;
  }

  Future<void> updateTransaction(
    TransactionModel oldTx,
    TransactionModel newTx,
  ) async {
    final db = await database;
    await db.transaction((txn) async {
      await _applyAccountDeltas(txn, _reverseDeltas(_accountDeltasFor(oldTx)));
      await _applyAccountDeltas(txn, _accountDeltasFor(newTx));

      await txn.update(
        'transactions',
        newTx.toMap(),
        where: 'id = ?',
        whereArgs: [newTx.id],
      );

      await _updateBudgetSpentInTxn(
        txn,
        oldTx.categoryId,
        oldTx.date.month,
        oldTx.date.year,
      );
      if (oldTx.categoryId != newTx.categoryId ||
          oldTx.date.month != newTx.date.month ||
          oldTx.date.year != newTx.date.year) {
        await _updateBudgetSpentInTxn(
          txn,
          newTx.categoryId,
          newTx.date.month,
          newTx.date.year,
        );
      }
    });
  }

  Future<void> deleteTransaction(TransactionModel tx) async {
    final db = await database;
    await db.transaction((txn) async {
      await _applyAccountDeltas(txn, _reverseDeltas(_accountDeltasFor(tx)));

      await txn.delete('transactions', where: 'id = ?', whereArgs: [tx.id]);
      await _updateBudgetSpentInTxn(
        txn,
        tx.categoryId,
        tx.date.month,
        tx.date.year,
      );
    });
  }

  Future<Map<String, double>> getMonthlySummary(int month, int year) async {
    final db = await database;
    final start = DateTime(year, month, 1).toIso8601String();
    final end = DateTime(year, month + 1, 1).toIso8601String();

    final incomeResult = await db.rawQuery(
      'SELECT COALESCE(SUM(amount), 0) as val FROM transactions WHERE type = ? AND date >= ? AND date < ?',
      ['income', start, end],
    );
    final expenseResult = await db.rawQuery(
      'SELECT COALESCE(SUM(amount), 0) as val FROM transactions WHERE type = ? AND date >= ? AND date < ?',
      ['expense', start, end],
    );

    return {
      'income': (incomeResult.first['val'] as num).toDouble(),
      'expense': (expenseResult.first['val'] as num).toDouble(),
    };
  }

  Future<List<Map<String, dynamic>>> getCategorySpending(
    int month,
    int year,
  ) async {
    final db = await database;
    final start = DateTime(year, month, 1).toIso8601String();
    final end = DateTime(year, month + 1, 1).toIso8601String();

    return db.rawQuery(
      '''
      SELECT c.id, c.name, c.icon, c.color, COALESCE(SUM(t.amount), 0) as total
      FROM transactions t
      JOIN categories c ON t.category_id = c.id
      WHERE t.type = ? AND t.date >= ? AND t.date < ?
      GROUP BY c.id
      ORDER BY total DESC
    ''',
      ['expense', start, end],
    );
  }

  Future<List<Map<String, dynamic>>> getLast6MonthsSummary() async {
    final db = await database;
    final results = <Map<String, dynamic>>[];
    final now = DateTime.now();

    for (int i = 5; i >= 0; i--) {
      final date = DateTime(now.year, now.month - i, 1);
      final start = date.toIso8601String();
      final end = DateTime(date.year, date.month + 1, 1).toIso8601String();

      final income = (await db.rawQuery(
        'SELECT COALESCE(SUM(amount), 0.0) as val FROM transactions WHERE type = ? AND date >= ? AND date < ?',
        ['income', start, end],
      )).first['val'];

      final expense = (await db.rawQuery(
        'SELECT COALESCE(SUM(amount), 0.0) as val FROM transactions WHERE type = ? AND date >= ? AND date < ?',
        ['expense', start, end],
      )).first['val'];

      results.add({
        'month': date.month,
        'year': date.year,
        'income': (income as num).toDouble(),
        'expense': (expense as num).toDouble(),
      });
    }

    return results;
  }

  // ─── ACCOUNTS ────────────────────────────────────────────────────────────

  Future<List<AccountModel>> getAccounts() async {
    final db = await database;
    final maps = await db.query('accounts', orderBy: 'created_at ASC');
    return maps.map((m) => AccountModel.fromMap(m)).toList();
  }

  Future<void> insertAccount(AccountModel account) async {
    final db = await database;
    await db.insert('accounts', account.toMap());
  }

  Future<void> updateAccount(AccountModel account) async {
    final db = await database;
    await db.update(
      'accounts',
      account.toMap(),
      where: 'id = ?',
      whereArgs: [account.id],
    );
  }

  Future<void> deleteAccount(String id) async {
    final db = await database;
    await db.delete('accounts', where: 'id = ?', whereArgs: [id]);
  }

  // ─── CATEGORIES ──────────────────────────────────────────────────────────

  Future<List<CategoryModel>> getCategories({String? type}) async {
    final db = await database;
    String? where;
    List<dynamic>? args;
    if (type != null) {
      where = 'type = ? OR type = ?';
      args = [type, 'both'];
    }
    final maps = await db.query(
      'categories',
      where: where,
      whereArgs: args,
      orderBy: 'is_default DESC, name ASC',
    );
    return maps.map((m) => CategoryModel.fromMap(m)).toList();
  }

  Future<void> insertCategory(CategoryModel category) async {
    final db = await database;
    await db.insert('categories', category.toMap());
  }

  Future<void> updateCategory(CategoryModel category) async {
    final db = await database;
    await db.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<void> deleteCategory(String id) async {
    final db = await database;
    await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  // ─── BUDGETS ─────────────────────────────────────────────────────────────

  Future<List<BudgetModel>> getBudgets(int month, int year) async {
    final db = await database;
    final maps = await db.query(
      'budgets',
      where: 'month = ? AND year = ?',
      whereArgs: [month, year],
    );
    return maps.map((m) => BudgetModel.fromMap(m)).toList();
  }

  Future<void> insertBudget(BudgetModel budget) async {
    final db = await database;
    await db.insert('budgets', budget.toMap());
    await _updateBudgetSpent(db, budget.categoryId, budget.month, budget.year);
  }

  Future<void> updateBudget(BudgetModel budget) async {
    final db = await database;
    await db.update(
      'budgets',
      budget.toMap(),
      where: 'id = ?',
      whereArgs: [budget.id],
    );
  }

  Future<void> deleteBudget(String id) async {
    final db = await database;
    await db.delete('budgets', where: 'id = ?', whereArgs: [id]);
  }

  // ─── HELPERS ─────────────────────────────────────────────────────────────

  Future<void> _updateBudgetSpent(
    Database db,
    String categoryId,
    int month,
    int year,
  ) async {
    final start = DateTime(year, month, 1).toIso8601String();
    final end = DateTime(year, month + 1, 1).toIso8601String();

    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(amount), 0) as total FROM transactions WHERE category_id = ? AND type = ? AND date >= ? AND date < ?',
      [categoryId, 'expense', start, end],
    );

    final total = (result.first['total'] as num).toDouble();
    await db.rawUpdate(
      'UPDATE budgets SET spent = ? WHERE category_id = ? AND month = ? AND year = ?',
      [total, categoryId, month, year],
    );
  }

  Future<void> _updateBudgetSpentInTxn(
    Transaction txn,
    String categoryId,
    int month,
    int year,
  ) async {
    final start = DateTime(year, month, 1).toIso8601String();
    final end = DateTime(year, month + 1, 1).toIso8601String();

    final result = await txn.rawQuery(
      'SELECT COALESCE(SUM(amount), 0) as total FROM transactions WHERE category_id = ? AND type = ? AND date >= ? AND date < ?',
      [categoryId, 'expense', start, end],
    );

    final total = (result.first['total'] as num).toDouble();
    await txn.rawUpdate(
      'UPDATE budgets SET spent = ? WHERE category_id = ? AND month = ? AND year = ?',
      [total, categoryId, month, year],
    );
  }

  // ─── LOANS ───────────────────────────────────────────────────────────────

  Future<List<LoanModel>> getLoans() async {
    final db = await database;
    final maps = await db.query('loans', orderBy: 'created_at DESC');
    return maps.map((m) => LoanModel.fromMap(m)).toList();
  }

  Future<void> insertLoan(LoanModel loan) async {
    final db = await database;
    await db.insert('loans', loan.toMap());
  }

  Future<void> updateLoan(LoanModel loan) async {
    final db = await database;
    await db.update(
      'loans',
      loan.toMap(),
      where: 'id = ?',
      whereArgs: [loan.id],
    );
  }

  Future<void> deleteLoan(String id) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('emi_log', where: 'loan_id = ?', whereArgs: [id]);
      await txn.delete('loans', where: 'id = ?', whereArgs: [id]);
    });
  }

  // ─── INVESTMENTS ─────────────────────────────────────────────────────────

  Future<List<InvestmentModel>> getInvestments() async {
    final db = await database;
    final maps = await db.query('investments', orderBy: 'created_at DESC');
    return maps.map((m) => InvestmentModel.fromMap(m)).toList();
  }

  Future<void> insertInvestment(InvestmentModel inv) async {
    final db = await database;
    await db.insert('investments', inv.toMap());
  }

  Future<void> updateInvestment(InvestmentModel inv) async {
    final db = await database;
    await db.update(
      'investments',
      inv.toMap(),
      where: 'id = ?',
      whereArgs: [inv.id],
    );
  }

  Future<void> deleteInvestment(String id) async {
    final db = await database;
    await db.delete('investments', where: 'id = ?', whereArgs: [id]);
  }

  // ─── SETTINGS ────────────────────────────────────────────────────────────

  Future<String?> getSetting(String key) async {
    final db = await database;
    final maps = await db.query('settings', where: 'key = ?', whereArgs: [key]);
    if (maps.isEmpty) return null;
    return maps.first['value'] as String;
  }

  Future<void> setSetting(String key, String value) async {
    final db = await database;
    await db.insert('settings', {
      'key': key,
      'value': value,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // ─── AUTO EMI ────────────────────────────────────────────────────────────

  Future<bool> hasEmiForMonth(String loanId, int month, int year) async {
    final db = await database;
    final result = await db.query(
      'emi_log',
      where: 'loan_id = ? AND month = ? AND year = ?',
      whereArgs: [loanId, month, year],
    );
    return result.isNotEmpty;
  }

  Future<void> processAutoEmis() async {
    final db = await database;
    final now = DateTime.now();
    final month = now.month;
    final year = now.year;

    final loans = await getLoans();
    const uuid = Uuid();

    for (final loan in loans) {
      if (!loan.autoEmi) continue;
      if (loan.outstandingAmount <= 0) continue;
      if (loan.accountId == null) continue;
      if (now.day < loan.emiDay) continue;

      final already = await hasEmiForMonth(loan.id, month, year);
      if (already) continue;

      final txId = uuid.v4();
      final tx = TransactionModel(
        id: txId,
        title: 'EMI - ${loan.name}',
        amount: loan.emiAmount,
        type: 'expense',
        categoryId: 'cat_bills',
        accountId: loan.accountId!,
        date: DateTime(year, month, loan.emiDay),
        note: 'Auto EMI for ${loan.type.label}',
        createdAt: now,
      );

      await db.transaction((txn) async {
        await txn.insert('transactions', tx.toMap());

        await txn.rawUpdate(
          'UPDATE accounts SET balance = balance - ? WHERE id = ?',
          [loan.emiAmount, loan.accountId],
        );

        final newOutstanding = (loan.outstandingAmount - loan.emiAmount).clamp(
          0.0,
          double.infinity,
        );
        await txn.rawUpdate(
          'UPDATE loans SET outstanding_amount = ? WHERE id = ?',
          [newOutstanding, loan.id],
        );

        await txn.insert('emi_log', {
          'id': uuid.v4(),
          'loan_id': loan.id,
          'transaction_id': txId,
          'month': month,
          'year': year,
        });

        await _updateBudgetSpentInTxn(txn, 'cat_bills', month, year);
      });
    }
  }

  // ─── CREDIT CARDS ────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getCreditCards() async {
    final db = await database;
    return db.query('credit_cards', orderBy: 'created_at DESC');
  }

  Future<void> insertCreditCard(Map<String, dynamic> card) async {
    final db = await database;
    await db.insert('credit_cards', card);
  }

  Future<void> updateCreditCard(Map<String, dynamic> card) async {
    final db = await database;
    await db.update(
      'credit_cards',
      card,
      where: 'id = ?',
      whereArgs: [card['id']],
    );
  }

  Future<void> deleteCreditCard(String id) async {
    final db = await database;
    await db.delete('credit_cards', where: 'id = ?', whereArgs: [id]);
  }
}
