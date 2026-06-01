import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/finance_provider.dart';
import '../services/database_service.dart';
import '../utils/app_theme.dart';
import '../widgets/app_logo.dart';
import '../widgets/quick_add_transaction_sheet.dart';
import '../widgets/quick_tour_overlay.dart';
import 'about_screen.dart';
import 'dashboard_screen.dart';
import 'transactions_screen.dart';
import 'budgets_screen.dart';
import 'reports_screen.dart';
import 'accounts_screen.dart';
import 'loans_screen.dart';
import 'investments_screen.dart';
import 'credit_cards_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  bool _showTour = false;

  final _screens = const [
    DashboardScreen(),
    TransactionsScreen(),
    BudgetsScreen(),
    ReportsScreen(),
    AccountsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkIfShowTour();
    });
  }

  Future<void> _checkIfShowTour() async {
    final hasSeenTour = await DatabaseService.instance.getSetting('tour_seen');
    if (hasSeenTour != 'true' && mounted) {
      setState(() => _showTour = true);
    }
  }

  Future<void> _completeTour() async {
    await DatabaseService.instance.setSetting('tour_seen', 'true');
    setState(() => _showTour = false);
  }

  @override
  Widget build(BuildContext context) {
    final loading = context.watch<FinanceProvider>().isLoading;

    if (loading) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const AppLogo(size: 72, radius: 22)
                  .animate(onPlay: (controller) => controller.repeat())
                  .scale(
                    begin: const Offset(.92, .92),
                    end: const Offset(1.06, 1.06),
                    duration: 900.ms,
                    curve: Curves.easeInOut,
                  )
                  .then()
                  .scale(
                    begin: const Offset(1.06, 1.06),
                    end: const Offset(.92, .92),
                    duration: 900.ms,
                    curve: Curves.easeInOut,
                  ),
              const SizedBox(height: 24),
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              const Text(
                'Finzo',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final compactNav = MediaQuery.sizeOf(context).width < 390;

    return Stack(
      children: [
        Scaffold(
          body: IndexedStack(index: _currentIndex, children: _screens),
          drawer: _buildDrawer(context),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                requestFocus: true,
                backgroundColor: Colors.transparent,
                builder: (_) => const QuickAddTransactionSheet(),
              );
            },
            backgroundColor: AppTheme.primaryColor,
            child: const Icon(Icons.add_rounded, size: 28),
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (i) => setState(() => _currentIndex = i),
            height: 72,
            backgroundColor: AppTheme.surfaceColor,
            indicatorColor: AppTheme.primaryColor.withAlpha(42),
            labelBehavior: compactNav
                ? NavigationDestinationLabelBehavior.onlyShowSelected
                : NavigationDestinationLabelBehavior.alwaysShow,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard_rounded),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.swap_horiz_outlined),
                selectedIcon: Icon(Icons.swap_horiz_rounded),
                label: 'Transactions',
              ),
              NavigationDestination(
                icon: Icon(Icons.donut_large_outlined),
                selectedIcon: Icon(Icons.donut_large_rounded),
                label: 'Budgets',
              ),
              NavigationDestination(
                icon: Icon(Icons.insights_outlined),
                selectedIcon: Icon(Icons.insights_rounded),
                label: 'Analytics',
              ),
              NavigationDestination(
                icon: Icon(Icons.account_balance_wallet_outlined),
                selectedIcon: Icon(Icons.account_balance_wallet_rounded),
                label: 'Accounts',
              ),
            ],
          ),
        ),
        if (_showTour) QuickTourOverlay(onComplete: _completeTour),
      ],
    );
  }

  Widget _buildDrawer(BuildContext context) {
    final provider = context.watch<FinanceProvider>();
    final width = MediaQuery.sizeOf(context).width;
    return Drawer(
      width: width >= 420 ? 360 : width * .86,
      backgroundColor: AppTheme.surfaceColor,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1F2937), Color(0xFF273469)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                children: [
                  const AppLogo(size: 54, radius: 16),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          provider.userName.isNotEmpty
                              ? provider.userName
                              : 'Finzo',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Currency: ${provider.currency.symbol} (${provider.currency.code})',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 4),
                children: [
                  _DrawerItem(
                    icon: Icons.credit_card_rounded,
                    title: 'Credit Cards',
                    subtitle: '${provider.creditCards.length} cards',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CreditCardsScreen(),
                        ),
                      );
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.account_balance_rounded,
                    title: 'Loans',
                    subtitle: '${provider.loans.length} active loans',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LoansScreen()),
                      );
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.trending_up_rounded,
                    title: 'Investments',
                    subtitle: '${provider.investments.length} investments',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const InvestmentsScreen(),
                        ),
                      );
                    },
                  ),
                  const Divider(
                    color: Colors.white12,
                    indent: 16,
                    endIndent: 16,
                  ),
                  _DrawerItem(
                    icon: Icons.settings_rounded,
                    title: 'Settings',
                    subtitle: 'Currency, preferences',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SettingsScreen(),
                        ),
                      );
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.info_rounded,
                    title: 'About',
                    subtitle: 'About Finzo',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AboutScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Finzo v1.0.0',
                style: TextStyle(color: Colors.white24, fontSize: 11),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      minLeadingWidth: 44,
      horizontalTitleGap: 12,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withAlpha(30),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppTheme.primaryColor, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: Colors.white38, fontSize: 11),
      ),
      onTap: onTap,
    );
  }
}
