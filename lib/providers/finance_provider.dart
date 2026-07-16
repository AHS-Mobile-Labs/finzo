import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/transaction_model.dart';
import '../models/transaction_split_model.dart';
import '../models/account_model.dart';
import '../models/category_model.dart';
import '../models/budget_model.dart';
import '../models/loan_model.dart';
import '../models/investment_model.dart';
import '../models/currency_model.dart';
import '../models/credit_card_model.dart';
import '../services/database_service.dart';
import '../utils/formatters.dart';

void _logFinance(String message) {
  if (kDebugMode) debugPrint(message);
}

class FinanceProvider extends ChangeNotifier {
  final _db = DatabaseService.instance;

  List<TransactionModel> _transactions = [];
  List<AccountModel> _accounts = [];
  List<CategoryModel> _categories = [];
  List<BudgetModel> _budgets = [];
  List<LoanModel> _loans = [];
  List<InvestmentModel> _investments = [];
  List<CreditCardModel> _creditCards = [];
  List<Map<String, dynamic>> _last6Months = [];
  List<Map<String, dynamic>> _categorySpending = [];
  List<String> _recentExpenseIds = [];
  List<String> _recentIncomeIds = [];
  Map<String, String> _receiptCategoryMemory = {};

  bool _isLoading = false;
  DateTime _selectedMonth = DateTime.now();
  CurrencyModel _currency = CurrencyModel.supported.first;
  String _userName = '';

  // ─── GETTERS ─────────────────────────────────────────────────────────────

  List<TransactionModel> get transactions => _transactions;
  List<AccountModel> get accounts => _accounts;
  List<CategoryModel> get categories => _categories;
  List<BudgetModel> get budgets => _budgets;
  List<LoanModel> get loans => _loans;
  List<InvestmentModel> get investments => _investments;
  List<CreditCardModel> get creditCards => _creditCards;
  List<Map<String, dynamic>> get last6Months => _last6Months;
  List<Map<String, dynamic>> get categorySpending => _categorySpending;
  bool get isLoading => _isLoading;
  DateTime get selectedMonth => _selectedMonth;
  CurrencyModel get currency => _currency;
  String get userName => _userName;

  double get totalBalance => _accounts.fold(0.0, (sum, a) => sum + a.balance);

  double get totalLoanOutstanding =>
      _loans.fold(0.0, (sum, l) => sum + l.outstandingAmount);

  double get totalInvestedAmount =>
      _investments.fold(0.0, (sum, i) => sum + i.investedAmount);

  double get totalInvestmentValue =>
      _investments.fold(0.0, (sum, i) => sum + i.currentValue);

  double get netWorth =>
      totalBalance + totalInvestmentValue - totalLoanOutstanding;

  double get monthlyIncome => _transactions
      .where(
        (t) =>
            t.type == 'income' &&
            t.date.month == _selectedMonth.month &&
            t.date.year == _selectedMonth.year,
      )
      .fold(0.0, (sum, t) => sum + t.amount);

  double get monthlyExpense => _transactions
      .where(
        (t) =>
            t.type == 'expense' &&
            t.date.month == _selectedMonth.month &&
            t.date.year == _selectedMonth.year,
      )
      .fold(0.0, (sum, t) => sum + t.amount);

  double get monthlySavings => monthlyIncome - monthlyExpense;

  double get savingsRate =>
      monthlyIncome > 0 ? (monthlySavings / monthlyIncome) * 100 : 0;

  double get expenseRatio => monthlyIncome > 0
      ? (monthlyExpense / monthlyIncome).clamp(0.0, 9.99).toDouble()
      : 0;

  double get totalBudget => _budgets.fold(0.0, (sum, b) => sum + b.amount);

  double get totalBudgetSpent => _budgets.fold(0.0, (sum, b) => sum + b.spent);

  double get budgetUsage => totalBudget > 0
      ? (totalBudgetSpent / totalBudget).clamp(0.0, 1.0).toDouble()
      : 0;

  int get overBudgetCount => _budgets.where((b) => b.isOverBudget).length;

  Map<String, dynamic>? get topSpendingCategory =>
      _categorySpending.isEmpty ? null : _categorySpending.first;

  double get averageDailyExpense {
    final now = DateTime.now();
    final daysElapsed =
        _selectedMonth.year == now.year && _selectedMonth.month == now.month
        ? now.day
        : DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0).day;
    return daysElapsed > 0 ? monthlyExpense / daysElapsed : 0;
  }

  double get projectedMonthlyExpense {
    final daysInMonth = DateTime(
      _selectedMonth.year,
      _selectedMonth.month + 1,
      0,
    ).day;
    return averageDailyExpense * daysInMonth;
  }

  double get cashflowMomentum {
    if (_last6Months.length < 2) return 0;
    final current = _last6Months.last;
    final previous = _last6Months[_last6Months.length - 2];
    final currentSavings =
        (current['income'] as double) - (current['expense'] as double);
    final previousSavings =
        (previous['income'] as double) - (previous['expense'] as double);
    if (previousSavings == 0) return currentSavings == 0 ? 0 : 100;
    return ((currentSavings - previousSavings) / previousSavings.abs()) * 100;
  }

  List<Map<String, dynamic>> get accountDistribution {
    if (totalBalance <= 0) return [];
    return _accounts
        .where((a) => a.balance > 0)
        .map(
          (a) => {
            'name': a.name,
            'icon': a.icon,
            'color': a.color,
            'balance': a.balance,
            'percentage': a.balance / totalBalance,
          },
        )
        .toList()
      ..sort(
        (a, b) => (b['balance'] as double).compareTo(a['balance'] as double),
      );
  }

  List<TransactionModel> get recentTransactions =>
      _transactions.take(20).toList();

  List<TransactionModel> get currentMonthTransactions => _transactions
      .where(
        (t) =>
            t.date.month == _selectedMonth.month &&
            t.date.year == _selectedMonth.year,
      )
      .toList();

  CategoryModel? getCategoryById(String id) {
    try {
      return _categories.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  String categoryDisplayName(CategoryModel? category) {
    if (category == null) return 'Unknown';
    if (category.parentCategoryId == null) return category.name;
    final parent = getCategoryById(category.parentCategoryId!);
    return parent == null ? category.name : '${parent.name} / ${category.name}';
  }

  AccountModel? getAccountById(String id) {
    try {
      return _accounts.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }

  CategoryModel? guessReceiptCategory(String merchantName) {
    final merchant = _normaliseMerchantKey(merchantName);
    if (merchant.isEmpty) return _fallbackExpenseCategory();

    final remembered = _rememberedReceiptCategory(merchant);
    if (remembered != null) return remembered;

    CategoryModel? byNames(List<String> names) {
      for (final name in names) {
        for (final category in _categories) {
          final displayName = categoryDisplayName(category).toLowerCase();
          if ((category.type == 'expense' || category.type == 'both') &&
              (category.name.toLowerCase() == name.toLowerCase() ||
                  displayName == name.toLowerCase())) {
            return category;
          }
        }
      }
      return null;
    }

    bool hasAny(List<String> keywords) {
      return keywords.any((keyword) => merchant.contains(keyword));
    }

    if (hasAny([
      'reliance fresh',
      'dmart',
      'big bazaar',
      'more',
      'grocery',
      'supermarket',
      'fresh',
      'mart',
    ])) {
      return byNames(['Groceries', 'Grocery', 'Food & Dining', 'Shopping']) ??
          _fallbackExpenseCategory();
    }
    if (hasAny([
      'zomato',
      'swiggy',
      'restaurant',
      'cafe',
      'coffee',
      'pizza',
      'domino',
      'kfc',
      'mcdonald',
    ])) {
      return byNames(['Food & Dining']) ?? _fallbackExpenseCategory();
    }
    if (hasAny([
      'uber',
      'ola',
      'rapido',
      'metro',
      'rail',
      'bus',
      'fuel',
      'petrol',
      'diesel',
    ])) {
      return byNames(['Transport']) ?? _fallbackExpenseCategory();
    }
    if (hasAny([
      'apollo',
      'medplus',
      'pharmacy',
      'medical',
      'hospital',
      'clinic',
    ])) {
      return byNames(['Health']) ?? _fallbackExpenseCategory();
    }
    if (hasAny([
      'electric',
      'water',
      'gas',
      'broadband',
      'internet',
      'mobile',
      'airtel',
      'jio',
      'vi ',
    ])) {
      return byNames(['Bills & Utilities']) ?? _fallbackExpenseCategory();
    }
    if (hasAny(['amazon', 'flipkart', 'myntra', 'store', 'mall', 'shop'])) {
      return byNames(['Shopping']) ?? _fallbackExpenseCategory();
    }

    return _fallbackExpenseCategory();
  }

  Future<void> rememberReceiptCategory(
    String merchantName,
    String categoryId,
  ) async {
    final merchant = _normaliseMerchantKey(merchantName);
    if (merchant.isEmpty || categoryId.isEmpty) return;
    _receiptCategoryMemory[merchant] = categoryId;
    await _db.setSetting('receipt_category_$merchant', categoryId);
  }

  List<TransactionModel> findPotentialDuplicateExpense({
    required String merchantName,
    required double amount,
    required DateTime date,
    String? excludeId,
  }) {
    final merchant = _normaliseMerchantKey(merchantName);
    final day = DateTime(date.year, date.month, date.day);

    final scored = <({TransactionModel tx, int score})>[];
    for (final tx in _transactions) {
      if (tx.id == excludeId || tx.type != 'expense') continue;
      if ((tx.amount - amount).abs() > 0.01) continue;

      final txDay = DateTime(tx.date.year, tx.date.month, tx.date.day);
      final dayDelta = txDay.difference(day).inDays.abs();
      if (dayDelta > 1) continue;

      var score = dayDelta == 0 ? 3 : 1;
      final title = _normaliseMerchantKey(tx.title);
      if (merchant.isNotEmpty &&
          (title == merchant ||
              title.contains(merchant) ||
              merchant.contains(title))) {
        score += 4;
      }
      if (tx.receiptPath != null && tx.receiptPath!.isNotEmpty) {
        score += 1;
      }
      scored.add((tx: tx, score: score));
    }

    scored.sort((a, b) => b.score.compareTo(a.score));
    return scored.take(3).map((entry) => entry.tx).toList();
  }

  CategoryModel? _rememberedReceiptCategory(String normalisedMerchant) {
    final categoryId = _receiptCategoryMemory[normalisedMerchant];
    if (categoryId == null) return null;
    final category = getCategoryById(categoryId);
    if (category == null) return null;
    if (category.type != 'expense' && category.type != 'both') return null;
    return category;
  }

  CategoryModel? _fallbackExpenseCategory() {
    for (final id in ['cat_other_exp', 'cat_food', 'cat_shop']) {
      final category = getCategoryById(id);
      if (category != null) return category;
    }
    for (final category in _categories) {
      if (category.type == 'expense' || category.type == 'both') {
        return category;
      }
    }
    return null;
  }

  String _normaliseMerchantKey(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  // ─── INIT ─────────────────────────────────────────────────────────────────

  Future<void> init() async {
    try {
      _isLoading = true;
      notifyListeners();

      _logFinance('[FinanceProvider] Initializing...');

      await _loadCurrency().catchError((e) {
        _logFinance('[FinanceProvider] Error loading currency: $e');
      });

      await _loadUserName().catchError((e) {
        _logFinance('[FinanceProvider] Error loading user name: $e');
      });

      await _loadRecentCategories().catchError((e) {
        _logFinance('[FinanceProvider] Error loading recent categories: $e');
      });

      await _loadReceiptCategoryMemory().catchError((e) {
        _logFinance(
          '[FinanceProvider] Error loading receipt category memory: $e',
        );
      });

      // Load all data with timeout
      try {
        await _loadAll().timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            _logFinance('[FinanceProvider] Timeout loading data (30s)');
            throw TimeoutException('Data loading timed out');
          },
        );
      } catch (e) {
        _logFinance('[FinanceProvider] Error loading all data: $e');
        // Continue anyway to show loading screen message
      }

      await _db.processAutoEmis().catchError((e) {
        _logFinance('[FinanceProvider] Error processing auto EMIs: $e');
      });
      await _loadAll().catchError((e) {
        _logFinance('[FinanceProvider] Error reloading after auto EMIs: $e');
      });

      _logFinance('[FinanceProvider] Initialization complete');

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _logFinance('[FinanceProvider] Fatal error during initialization: $e');
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> _loadUserName() async {
    _userName = (await _db.getSetting('user_name')) ?? '';
  }

  Future<void> _loadRecentCategories() async {
    try {
      final expenseJson =
          (await _db.getSetting('recent_categories_expense')) ?? '';
      _recentExpenseIds = expenseJson.isEmpty
          ? []
          : expenseJson.split(',').where((id) => id.isNotEmpty).toList();

      final incomeJson =
          (await _db.getSetting('recent_categories_income')) ?? '';
      _recentIncomeIds = incomeJson.isEmpty
          ? []
          : incomeJson.split(',').where((id) => id.isNotEmpty).toList();
    } catch (_) {
      _recentExpenseIds = [];
      _recentIncomeIds = [];
    }
  }

  Future<void> _loadReceiptCategoryMemory() async {
    final settings = await _db.getSettingsWithPrefix('receipt_category_');
    _receiptCategoryMemory = {
      for (final entry in settings.entries)
        entry.key.replaceFirst('receipt_category_', ''): entry.value,
    };
  }

  Future<void> setUserName(String name) async {
    await _db.setSetting('user_name', name);
    _userName = name;
    notifyListeners();
  }

  Future<void> _loadCurrency() async {
    final code = await _db.getSetting('currency');
    if (code != null) {
      _currency = CurrencyModel.fromCode(code);
    }
    Formatters.setCurrency(_currency);
  }

  Future<void> _loadAll() async {
    await Future.wait([
      _loadAccounts().catchError((_) => null),
      _loadCategories().catchError((_) => null),
      _loadTransactions().catchError((_) => null),
      _loadBudgets().catchError((_) => null),
      _loadAnalytics().catchError((_) => null),
      _loadLoans().catchError((_) => null),
      _loadInvestments().catchError((_) => null),
      _loadCreditCards().catchError((_) => null),
    ]);
  }

  Future<void> _loadTransactions() async {
    _transactions = await _db.getTransactions();
  }

  Future<void> _loadAccounts() async {
    _accounts = await _db.getAccounts();
  }

  Future<void> _loadCategories() async {
    _categories = await _db.getCategories();
  }

  Future<void> _loadBudgets() async {
    _budgets = await _db.getBudgets(_selectedMonth.month, _selectedMonth.year);
  }

  Future<void> _loadAnalytics() async {
    _last6Months = await _db.getLast6MonthsSummary();
    _categorySpending = await _db.getCategorySpending(
      _selectedMonth.month,
      _selectedMonth.year,
    );
  }

  Future<void> setSelectedMonth(DateTime month) async {
    _selectedMonth = month;
    await Future.wait([_loadBudgets(), _loadAnalytics()]);
    notifyListeners();
  }

  // ─── TRANSACTIONS ────────────────────────────────────────────────────────

  Future<void> addTransaction(TransactionModel tx) async {
    await _db.insertTransaction(tx);
    if (tx.type != 'transfer') {
      final categoryIds = tx.splits.isEmpty
          ? <String>[tx.categoryId]
          : tx.splits.map((split) => split.categoryId).toSet().toList();
      for (final categoryId in categoryIds) {
        await _trackCategoryUsage(categoryId, tx.type);
      }
    }
    await _loadAll();
    notifyListeners();
  }

  Future<void> editTransaction(
    TransactionModel oldTx,
    TransactionModel newTx,
  ) async {
    await _db.updateTransaction(oldTx, newTx);
    await _loadAll();
    notifyListeners();
  }

  Future<void> removeTransaction(TransactionModel tx) async {
    await _db.deleteTransaction(tx);
    await _loadAll();
    notifyListeners();
  }

  // ─── ACCOUNTS ────────────────────────────────────────────────────────────

  Future<void> addAccount(AccountModel account) async {
    await _db.insertAccount(account);
    await _loadAccounts();
    notifyListeners();
  }

  Future<void> editAccount(AccountModel account) async {
    await _db.updateAccount(account);
    await _loadAccounts();
    notifyListeners();
  }

  Future<void> removeAccount(String id) async {
    await _db.deleteAccount(id);
    await _loadAccounts();
    notifyListeners();
  }

  // ─── CATEGORIES ──────────────────────────────────────────────────────────

  Future<void> addCategory(CategoryModel category) async {
    await _db.insertCategory(category);
    await _loadCategories();
    notifyListeners();
  }

  Future<void> removeCategory(String id) async {
    await _db.deleteCategory(id);
    await _loadCategories();
    notifyListeners();
  }

  // ─── BUDGETS ─────────────────────────────────────────────────────────────

  Future<void> addBudget(BudgetModel budget) async {
    await _db.insertBudget(budget);
    await _loadBudgets();
    notifyListeners();
  }

  Future<void> editBudget(BudgetModel budget) async {
    await _db.updateBudget(budget);
    await _loadBudgets();
    notifyListeners();
  }

  Future<void> removeBudget(String id) async {
    await _db.deleteBudget(id);
    await _loadBudgets();
    notifyListeners();
  }

  List<CategoryModel> getCategoriesForType(String type) {
    return _categories
        .where((c) => c.type == type || c.type == 'both')
        .toList();
  }

  /// Get recently used categories for a type (up to 3)
  List<CategoryModel> getRecentCategories(String type) {
    final recentIds = type == 'expense' ? _recentExpenseIds : _recentIncomeIds;
    final recent = <CategoryModel>[];

    for (final id in recentIds.take(3)) {
      final cat = getCategoryById(id);
      if (cat != null && (cat.type == type || cat.type == 'both')) {
        recent.add(cat);
      }
    }

    // If not enough recent, pad with default categories
    if (recent.length < 3) {
      final defaultCats = getCategoriesForType(type)
          .where((cat) => !recent.any((r) => r.id == cat.id))
          .take(3 - recent.length);
      recent.addAll(defaultCats);
    }

    return recent;
  }

  /// Track a category as recently used
  Future<void> _trackCategoryUsage(String categoryId, String type) async {
    try {
      final recentIds = type == 'expense'
          ? _recentExpenseIds
          : _recentIncomeIds;

      // Remove if already in list
      recentIds.removeWhere((id) => id == categoryId);

      // Add to front
      recentIds.insert(0, categoryId);

      // Keep only last 5
      if (recentIds.length > 5) {
        recentIds.removeRange(5, recentIds.length);
      }

      // Save to database
      final key = 'recent_categories_$type';
      final joined = recentIds.join(',');
      await _db.setSetting(key, joined);
    } catch (_) {
      // Silently fail - not critical
    }
  }

  // ─── LOANS ───────────────────────────────────────────────────────────────

  Future<void> _loadLoans() async {
    _loans = await _db.getLoans();
  }

  Future<void> addLoan(LoanModel loan) async {
    await _db.insertLoan(loan);
    await _loadLoans();
    notifyListeners();
  }

  Future<void> editLoan(LoanModel loan) async {
    await _db.updateLoan(loan);
    await _loadLoans();
    notifyListeners();
  }

  Future<void> removeLoan(String id) async {
    await _db.deleteLoan(id);
    await _loadLoans();
    notifyListeners();
  }

  // ─── INVESTMENTS ─────────────────────────────────────────────────────────

  Future<void> _loadInvestments() async {
    _investments = await _db.getInvestments();
  }

  Future<void> addInvestment(InvestmentModel inv) async {
    await _db.insertInvestment(inv);
    await _loadInvestments();
    notifyListeners();
  }

  Future<void> editInvestment(InvestmentModel inv) async {
    await _db.updateInvestment(inv);
    await _loadInvestments();
    notifyListeners();
  }

  Future<void> removeInvestment(String id) async {
    await _db.deleteInvestment(id);
    await _loadInvestments();
    notifyListeners();
  }

  // ─── CREDIT CARDS ────────────────────────────────────────────────────────

  Future<void> _loadCreditCards() async {
    final maps = await _db.getCreditCards();
    _creditCards = maps.map((m) => CreditCardModel.fromMap(m)).toList();
  }

  Future<void> addCreditCard(CreditCardModel card) async {
    await _db.insertCreditCard(card.toMap());
    await _loadCreditCards();
    notifyListeners();
  }

  Future<void> editCreditCard(CreditCardModel card) async {
    await _db.updateCreditCard(card.toMap());
    await _loadCreditCards();
    notifyListeners();
  }

  Future<void> removeCreditCard(String id) async {
    await _db.deleteCreditCard(id);
    await _loadCreditCards();
    notifyListeners();
  }

  // ─── SETTINGS / CURRENCY ─────────────────────────────────────────────────

  Future<void> setCurrency(CurrencyModel cur) async {
    await _db.setSetting('currency', cur.code);
    _currency = cur;
    Formatters.setCurrency(cur);
    notifyListeners();
  }

  // ─── BOOK MANAGEMENT ─────────────────────────────────────────────────────

  /// Current book name
  String get currentBookName => _db.currentBookName ?? 'default';

  /// List all available books
  Future<List<String>> listBooks() => DatabaseService.listBooks();

  /// Switch to a different book and reload all data
  Future<void> switchBook(String bookName) async {
    _isLoading = true;
    notifyListeners();
    await _db.openBook(bookName);
    await _loadCurrency();
    await _loadUserName();
    await _loadRecentCategories();
    await _loadReceiptCategoryMemory();
    await _loadAll();
    await _db.processAutoEmis();
    await _loadAll();
    _isLoading = false;
    notifyListeners();
  }

  /// Create a new book and switch to it
  Future<void> createNewBook(String bookName) async {
    _isLoading = true;
    notifyListeners();
    await _db.createBook(bookName);
    await _loadCurrency();
    await _loadUserName();
    await _loadRecentCategories();
    await _loadReceiptCategoryMemory();
    await _loadAll();
    _isLoading = false;
    notifyListeners();
  }

  /// Delete a book (cannot delete the currently active one)
  Future<bool> deleteBook(String bookName) async {
    if (bookName == currentBookName) return false;
    await _db.deleteBook(bookName);
    return true;
  }

  Future<String> backupCurrentBook() => _db.backupCurrentBook();

  Future<String> exportTransactionsCsv() async {
    final stamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '')
        .replaceAll('.', '');
    final fileName = '${currentBookName}_transactions_$stamp.csv';

    const headers = [
      'title',
      'amount',
      'type',
      'category',
      'account',
      'related_account',
      'date',
      'note',
      'payment_method',
      'tags',
      'tracking_status',
      'receipt_path',
      'splits',
    ];

    final rows = <List<String>>[headers];
    for (final tx in _transactions) {
      final category = getCategoryById(tx.categoryId);
      final account = getAccountById(tx.accountId);
      final related = tx.relatedAccountId == null
          ? null
          : getAccountById(tx.relatedAccountId!);
      rows.add([
        tx.title,
        tx.amount.toStringAsFixed(2),
        tx.type,
        categoryDisplayName(category),
        account?.name ?? '',
        related?.name ?? '',
        tx.date.toIso8601String(),
        tx.note ?? '',
        tx.paymentMethod ?? '',
        tx.tags.join(';'),
        tx.trackingStatus,
        tx.receiptPath ?? '',
        jsonEncode(
          tx.splits.map((split) {
            final splitCategory = getCategoryById(split.categoryId);
            return {
              'category': categoryDisplayName(splitCategory),
              'amount': split.amount,
            };
          }).toList(),
        ),
      ]);
    }

    final csv = rows.map((row) => row.map(_csvEscape).join(',')).join('\n');
    return DatabaseService.saveUserVisibleFile(
      fileName: fileName,
      mimeType: 'text/csv',
      subdirectory: 'exports',
      bytes: utf8.encode(csv),
    );
  }

  Future<int> importTransactionsCsv(String sourcePath) async {
    final file = File(sourcePath);
    if (!await file.exists()) throw Exception('CSV file not found');

    final rows = _parseCsv(await file.readAsString());
    if (rows.isEmpty) return 0;

    final headers = rows.first.map((header) => header.trim()).toList();
    final indexes = <String, int>{};
    for (var i = 0; i < headers.length; i++) {
      indexes[headers[i].toLowerCase()] = i;
    }

    String value(List<String> row, String key) {
      final index = indexes[key];
      if (index == null || index >= row.length) return '';
      return row[index].trim();
    }

    var imported = 0;
    const uuid = Uuid();

    for (final row in rows.skip(1)) {
      if (row.every((cell) => cell.trim().isEmpty)) continue;

      final amount = double.tryParse(value(row, 'amount'));
      if (amount == null || amount <= 0) continue;

      final type = _normaliseTransactionType(value(row, 'type'));
      final account = await _accountForImport(value(row, 'account'), uuid);
      AccountModel? related;
      if (type == 'transfer') {
        related = await _accountForImport(value(row, 'related_account'), uuid);
        if (related.id == account.id) continue;
      }

      final category = type == 'transfer'
          ? getCategoryById('cat_transfer')
          : await _categoryForImport(value(row, 'category'), type, uuid);
      if (category == null) continue;

      final date = DateTime.tryParse(value(row, 'date')) ?? DateTime.now();
      final splits = type == 'transfer'
          ? <TransactionSplitModel>[]
          : await _splitsForImport(value(row, 'splits'), type, uuid);

      final tx = TransactionModel(
        id: uuid.v4(),
        title: value(row, 'title').isEmpty
            ? 'Imported transaction'
            : value(row, 'title'),
        amount: amount,
        type: type,
        categoryId: splits.isNotEmpty ? splits.first.categoryId : category.id,
        accountId: account.id,
        relatedAccountId: related?.id,
        date: date,
        note: value(row, 'note').isEmpty ? null : value(row, 'note'),
        paymentMethod: _normalisePaymentMethod(value(row, 'payment_method')),
        tags: value(row, 'tags')
            .split(';')
            .map((tag) => tag.trim())
            .where((tag) => tag.isNotEmpty)
            .toList(),
        receiptPath: value(row, 'receipt_path').isEmpty
            ? null
            : value(row, 'receipt_path'),
        trackingStatus: _normaliseTrackingStatus(value(row, 'tracking_status')),
        splits: splits,
        createdAt: DateTime.now(),
      );

      await _db.insertTransaction(tx);
      imported++;
    }

    await _loadAll();
    notifyListeners();
    return imported;
  }

  String _csvEscape(String value) {
    final needsQuotes =
        value.contains(',') || value.contains('"') || value.contains('\n');
    final escaped = value.replaceAll('"', '""');
    return needsQuotes ? '"$escaped"' : escaped;
  }

  List<List<String>> _parseCsv(String input) {
    final rows = <List<String>>[];
    var row = <String>[];
    final cell = StringBuffer();
    var inQuotes = false;

    for (var i = 0; i < input.length; i++) {
      final char = input[i];
      if (inQuotes) {
        if (char == '"') {
          final nextIsQuote = i + 1 < input.length && input[i + 1] == '"';
          if (nextIsQuote) {
            cell.write('"');
            i++;
          } else {
            inQuotes = false;
          }
        } else {
          cell.write(char);
        }
      } else if (char == '"') {
        inQuotes = true;
      } else if (char == ',') {
        row.add(cell.toString());
        cell.clear();
      } else if (char == '\n') {
        row.add(cell.toString());
        rows.add(row);
        row = <String>[];
        cell.clear();
      } else if (char != '\r') {
        cell.write(char);
      }
    }

    row.add(cell.toString());
    if (row.any((cell) => cell.isNotEmpty)) {
      rows.add(row);
    }
    return rows;
  }

  String _normaliseTransactionType(String value) {
    final lower = value.toLowerCase();
    if (lower == 'income' || lower == 'transfer') return lower;
    return 'expense';
  }

  String? _normalisePaymentMethod(String value) {
    final lower = value.toLowerCase();
    if (TransactionPaymentMethod.values.contains(lower)) return lower;
    if (lower == 'upi') return TransactionPaymentMethod.upi;
    if (lower.isEmpty) return null;
    return TransactionPaymentMethod.cash;
  }

  String _normaliseTrackingStatus(String value) {
    final lower = value.toLowerCase();
    if (TransactionTrackingStatus.values.contains(lower)) return lower;
    return TransactionTrackingStatus.normal;
  }

  Future<AccountModel> _accountForImport(String name, Uuid uuid) async {
    final target = name.trim();
    if (target.isNotEmpty) {
      for (final account in _accounts) {
        if (account.name.toLowerCase() == target.toLowerCase()) {
          return account;
        }
      }
    }

    if (_accounts.isNotEmpty && target.isEmpty) {
      return _accounts.first;
    }

    final account = AccountModel(
      id: uuid.v4(),
      name: target.isEmpty ? 'Imported Account' : target,
      balance: 0,
      color: 0xFF6AA5FF,
      icon: 'bank',
      createdAt: DateTime.now(),
    );
    await _db.insertAccount(account);
    _accounts.add(account);
    return account;
  }

  Future<CategoryModel?> _categoryForImport(
    String name,
    String type,
    Uuid uuid,
  ) async {
    final target = name.trim();
    for (final category in _categories) {
      final display = categoryDisplayName(category);
      if ((category.name.toLowerCase() == target.toLowerCase() ||
              display.toLowerCase() == target.toLowerCase()) &&
          (category.type == type || category.type == 'both')) {
        return category;
      }
    }

    final fallbackName = target.isEmpty
        ? (type == 'income' ? 'Imported Income' : 'Imported Expense')
        : target.split('/').last.trim();
    CategoryModel? parent;
    if (target.contains('/')) {
      final parentName = target.split('/').first.trim();
      try {
        parent = _categories.firstWhere(
          (category) => category.name.toLowerCase() == parentName.toLowerCase(),
        );
      } catch (_) {
        parent = null;
      }
    }

    final category = CategoryModel(
      id: uuid.v4(),
      name: fallbackName,
      icon: type == 'income' ? 'cash' : 'box',
      color: type == 'income' ? 0xFF3EE184 : 0xFFFFD95A,
      type: type,
      parentCategoryId: parent?.id,
    );
    await _db.insertCategory(category);
    _categories.add(category);
    return category;
  }

  Future<List<TransactionSplitModel>> _splitsForImport(
    String raw,
    String type,
    Uuid uuid,
  ) async {
    if (raw.trim().isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      final splits = <TransactionSplitModel>[];
      for (final item in decoded) {
        if (item is! Map) continue;
        final categoryName = item['category']?.toString() ?? '';
        final amount = item['amount'] is num
            ? (item['amount'] as num).toDouble()
            : double.tryParse(item['amount']?.toString() ?? '');
        if (amount == null || amount <= 0) continue;
        final category = await _categoryForImport(categoryName, type, uuid);
        if (category == null) continue;
        splits.add(
          TransactionSplitModel(
            id: uuid.v4(),
            transactionId: '',
            categoryId: category.id,
            amount: amount,
          ),
        );
      }
      return splits;
    } catch (_) {
      return const [];
    }
  }

  /// Get current database file path
  Future<String?> get currentDbPath => _db.currentDbPath;
}
