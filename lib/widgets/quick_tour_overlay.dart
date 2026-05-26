import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

class QuickTourOverlay extends StatefulWidget {
  final VoidCallback onComplete;

  const QuickTourOverlay({super.key, required this.onComplete});

  @override
  State<QuickTourOverlay> createState() => _QuickTourOverlayState();
}

class _QuickTourOverlayState extends State<QuickTourOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  int _currentStep = 0;

  static const _steps = [
    _TourStep(
      title: 'Welcome to Finzo',
      description:
          'Your personal finance manager. Tap the + button to add transactions quickly.',
      icon: Icons.add_circle_outline_rounded,
    ),
    _TourStep(
      title: 'Track Transactions',
      description:
          'View all your transactions, filter by type, and search by title.',
      icon: Icons.swap_horiz_rounded,
    ),
    _TourStep(
      title: 'Manage Budgets',
      description:
          'Set spending limits per category and get alerts when you\'re overspending.',
      icon: Icons.pie_chart_rounded,
    ),
    _TourStep(
      title: 'View Reports',
      description:
          'Get insights into your spending patterns with visual reports.',
      icon: Icons.bar_chart_rounded,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < _steps.length - 1) {
      setState(() => _currentStep++);
    } else {
      _complete();
    }
  }

  void _complete() {
    _animController.reverse().then((_) => widget.onComplete());
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animController,
      child: Stack(
        children: [
          // Backdrop
          GestureDetector(
            onTap: _complete,
            child: Container(
              color: Colors.black87,
              child: const Center(
                child: Text(
                  'Tap anywhere to skip',
                  style: TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ),
            ),
          ),
          // Tooltip card
          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.5),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Step indicator
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withAlpha(20),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          'Step ${_currentStep + 1} of ${_steps.length}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Icon
                      Icon(
                        _steps[_currentStep].icon,
                        size: 56,
                        color: AppTheme.primaryColor,
                      ),
                      const SizedBox(height: 24),
                      // Title
                      Text(
                        _steps[_currentStep].title,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      // Description
                      Text(
                        _steps[_currentStep].description,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      // Progress dots
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          _steps.length,
                          (idx) => Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Container(
                              width: idx == _currentStep ? 24 : 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: idx <= _currentStep
                                    ? AppTheme.primaryColor
                                    : Colors.white24,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Next button
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _nextStep,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            _currentStep == _steps.length - 1
                                ? 'Get Started'
                                : 'Next',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TourStep {
  final String title;
  final String description;
  final IconData icon;

  const _TourStep({
    required this.title,
    required this.description,
    required this.icon,
  });
}
