import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/transaction_model.dart';
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

  AccountModel? getAccountById(String id) {
    try {
      return _accounts.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
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
      await _trackCategoryUsage(tx.categoryId, tx.type);
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

  /// Get current database file path
  Future<String?> get currentDbPath => _db.currentDbPath;
}
