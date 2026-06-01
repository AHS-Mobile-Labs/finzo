import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/database_service.dart';
import '../utils/app_theme.dart';
import '../widgets/app_logo.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;
  const OnboardingScreen({super.key, required this.onComplete});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

enum _Step { welcome, quickSetup }

class _OnboardingScreenState extends State<OnboardingScreen> {
  _Step _step = _Step.welcome;
  bool _isCreating = true; // true = create, false = import
  bool _isProcessing = false;
  final _nameCtrl = TextEditingController();
  String? _error;
  final String _defaultBookName = 'My Finance';
  final String _defaultUserName = 'User';

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _importBook() async {
    setState(() => _isProcessing = true);
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.any);
      if (result == null || result.files.single.path == null) {
        setState(() => _isProcessing = false);
        return;
      }
      final sourcePath = result.files.single.path!;
      if (!sourcePath.endsWith('.books.db')) {
        setState(() {
          _error = 'Please select a valid .books.db file';
          _isProcessing = false;
        });
        return;
      }
      final bookName = await DatabaseService.importBook(sourcePath);
      await DatabaseService.instance.openBook(bookName);
      setState(() {
        _error = null;
        _isProcessing = false;
        _step = _Step.quickSetup;
      });
    } catch (e) {
      setState(() => _error = 'Import failed: ${e.toString()}');
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _createBook() async {
    setState(() => _isProcessing = true);
    try {
      await DatabaseService.instance.createBook(_defaultBookName);
      setState(() {
        _error = null;
        _isProcessing = false;
        _step = _Step.quickSetup;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isProcessing = false;
      });
    }
  }

  Future<void> _finish() async {
    final name = _nameCtrl.text.trim();
    final finalName = name.isEmpty ? _defaultUserName : name;

    try {
      await DatabaseService.instance.setSetting('user_name', finalName);
      widget.onComplete();
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _buildStep(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep() {
    return switch (_step) {
      _Step.welcome => _buildWelcome(),
      _Step.quickSetup => _buildQuickSetup(),
    };
  }

  Widget _buildWelcome() {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          // Progress Indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withAlpha(20),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Step 1 of 2',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
          const SizedBox(height: 48),
          const AppLogo(size: 76, radius: 22),
          const SizedBox(height: 24),
          const Text(
            'Welcome to Finzo',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Your personal finance manager',
            style: TextStyle(color: Colors.white54, fontSize: 14),
          ),
          const SizedBox(height: 56),
          _ActionCard(
            icon: Icons.add_circle_outline_rounded,
            title: 'Create New Book',
            subtitle: 'Start fresh with a new finance book',
            onTap: _isProcessing
                ? null
                : () {
                    _error = null;
                    _isCreating = true;
                    _createBook();
                  },
          ),
          const SizedBox(height: 16),
          _ActionCard(
            icon: Icons.file_download_outlined,
            title: 'Import Existing',
            subtitle: 'Restore from a .books.db file',
            onTap: _isProcessing
                ? null
                : () {
                    _isCreating = false;
                    _importBook();
                  },
          ),
          if (_error != null) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.expenseColor.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _error!,
                style: const TextStyle(
                  color: AppTheme.expenseColor,
                  fontSize: 13,
                ),
              ),
            ),
          ],
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildQuickSetup() {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          // Progress Indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withAlpha(20),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Step 2 of 2',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
          const SizedBox(height: 48),
          if (_isProcessing)
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 24),
                Text(
                  _isCreating ? 'Creating book…' : 'Importing…',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            )
          else
            Column(
              children: [
                const Icon(
                  Icons.person_rounded,
                  size: 64,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(height: 32),
                const Text(
                  'What\'s your name?',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'We\'ll use this to personalize your experience (optional)',
                  style: TextStyle(color: Colors.white54, fontSize: 13),
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: _nameCtrl,
                  autofocus: true,
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    hintText: 'Enter your name',
                    hintStyle: const TextStyle(color: Colors.white24),
                    filled: true,
                    fillColor: AppTheme.cardColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 18,
                    ),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    style: const TextStyle(
                      color: AppTheme.expenseColor,
                      fontSize: 12,
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _finish,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Get Started',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          _nameCtrl.clear();
                          _finish();
                        },
                        child: const Text(
                          'Skip',
                          style: TextStyle(color: Colors.white38),
                        ),
                      ),
                    ),
                    Expanded(
                      child: TextButton(
                        onPressed: () => setState(() {
                          _error = null;
                          _step = _Step.welcome;
                          _nameCtrl.clear();
                        }),
                        child: const Text(
                          'Back',
                          style: TextStyle(color: Colors.white38),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = onTap != null;
    return Material(
      color: AppTheme.cardColor.withAlpha(isEnabled ? 255 : 100),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: isEnabled ? onTap : null,
        borderRadius: BorderRadius.circular(16),
        child: Opacity(
          opacity: isEnabled ? 1.0 : 0.6,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withAlpha(30),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: AppTheme.primaryColor, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: Colors.white24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
