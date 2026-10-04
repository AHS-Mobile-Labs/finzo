import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/app_theme.dart';
import '../widgets/app_logo.dart';
import '../widgets/pressable_card.dart';

const _linktreeUrl = 'https://linktr.ee/ahsmobilelabs';
const _githubUrl = 'https://github.com/AHS-Mobile-Labs/finzo';
const _emailAddress = 'ahsmobilelabs@gmail.com';
const _linktreeQrAsset = 'assets/app image/Linktree QR code/ahsmobilelabs.png';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  Future<void> _launchUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      debugPrint('Could not launch URL: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'About Finzo',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Hero Branding Block
                const _AboutHero()
                    .animate()
                    .fadeIn(duration: 300.ms)
                    .slideY(begin: 0.05, end: 0),
                const SizedBox(height: 24),

                // Core Principles / Value Proposition
                const _SectionHeader(
                  title: 'Core Values',
                  subtitle: 'Why Finzo is built differently',
                ),
                const SizedBox(height: 12),
                const _ValueCard(
                  icon: Icons.shield_rounded,
                  iconColor: AppTheme.incomeColor,
                  title: '100% Offline & Private',
                  description:
                      'No sign-ups, no remote servers, and zero data tracking. Your financial books stay strictly on your device.',
                ),
                const SizedBox(height: 10),
                const _ValueCard(
                  icon: Icons.inventory_2_rounded,
                  iconColor: AppTheme.primaryColor,
                  title: 'Complete Data Ownership',
                  description:
                      'Export your entire database or CSV ledgers with one tap. Your data is yours forever in open, portable formats.',
                ),
                const SizedBox(height: 10),
                const _ValueCard(
                  icon: Icons.auto_awesome_rounded,
                  iconColor: AppTheme.goldColor,
                  title: 'On-Device Financial Intelligence',
                  description:
                      '50/30/20 rule analytics, emergency runway calculators, and 4-pillar health scoring calculated securely offline.',
                ),
                const SizedBox(height: 26),

                // Studio & Developer
                const _SectionHeader(
                  title: 'Creator & Studio',
                  subtitle: 'Crafted with care for financial independence',
                ),
                const SizedBox(height: 12),
                const _StudioCard(),
                const SizedBox(height: 12),

                // Fast Action Links
                Row(
                  children: [
                    Expanded(
                      child: _QuickActionButton(
                        icon: Icons.mail_outline_rounded,
                        label: 'Support',
                        color: const Color(0xFF38BDF8),
                        onTap: () => _launchUrl('mailto:$_emailAddress'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _QuickActionButton(
                        icon: Icons.code_rounded,
                        label: 'GitHub',
                        color: AppTheme.primaryColor,
                        onTap: () => _launchUrl(_githubUrl),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _QuickActionButton(
                        icon: Icons.link_rounded,
                        label: 'Links',
                        color: AppTheme.incomeColor,
                        onTap: () => _launchUrl(_linktreeUrl),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Share / QR Card
                const _ShareFinzoCard(),
                const SizedBox(height: 32),

                // Footer
                Column(
                  children: [
                    Container(
                      width: 32,
                      height: 3,
                      decoration: BoxDecoration(
                        gradient: AppTheme.brandGradient,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'BUDGET FOR SUCCESS',
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2.0,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Finzo v1.0.1 • AHS Mobile Labs',
                      style: TextStyle(color: Colors.white24, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AboutHero extends StatelessWidget {
  const _AboutHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white10),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppTheme.primaryColor.withAlpha(20), AppTheme.cardColor],
        ),
      ),
      child: Column(
        children: [
          const AppLogo(size: 80, radius: 24),
          const SizedBox(height: 16),
          const Text(
            'Finzo',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withAlpha(40),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppTheme.primaryColor.withAlpha(80),
                  ),
                ),
                child: const Text(
                  'v1.0.1',
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.incomeColor.withAlpha(30),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.incomeColor.withAlpha(60)),
                ),
                child: const Text(
                  'Offline-First',
                  style: TextStyle(
                    color: AppTheme.incomeColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'A private, distraction-free personal finance book engineered to help you track spending, build emergency runways, and master your money.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.45),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: const TextStyle(color: Colors.white38, fontSize: 11),
        ),
      ],
    );
  }
}

class _ValueCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;

  const _ValueCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withAlpha(12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconColor.withAlpha(25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StudioCard extends StatelessWidget {
  const _StudioCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withAlpha(14)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withAlpha(30),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.terminal_rounded,
              color: AppTheme.primaryColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AHS Mobile Labs',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Independent studio crafting local-first mobile software.',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return PressableCard(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withAlpha(40)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShareFinzoCard extends StatefulWidget {
  const _ShareFinzoCard();

  @override
  State<_ShareFinzoCard> createState() => _ShareFinzoCardState();
}

class _ShareFinzoCardState extends State<_ShareFinzoCard> {
  static const _shareChannel = MethodChannel('com.ahsmobilelabs.finzo/share');
  bool _showQr = false;

  Future<void> _shareQrCode(BuildContext context) async {
    try {
      if (!Platform.isAndroid && !Platform.isIOS) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sharing QR images is available on mobile.'),
          ),
        );
        return;
      }

      final tempDir = await getTemporaryDirectory();
      final shareDir = Directory(p.join(tempDir.path, 'finzo-share'));
      if (!await shareDir.exists()) {
        await shareDir.create(recursive: true);
      }

      final data = await rootBundle.load(_linktreeQrAsset);
      final imageFile = File(p.join(shareDir.path, 'ahsmobilelabs-qr.png'));
      await imageFile.writeAsBytes(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
        flush: true,
      );

      await _shareChannel.invokeMethod<void>('shareLinktreeQr', {
        'text': 'AHS Mobile Labs\n$_linktreeUrl',
        'imagePath': imageFile.path,
      });
    } catch (e) {
      debugPrint('Share error: $e');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open share sheet.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.qr_code_rounded,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Share Finzo',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Share with friends or view link QR',
                      style: TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => setState(() => _showQr = !_showQr),
                icon: Icon(
                  _showQr
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: Colors.white54,
                ),
                tooltip: _showQr ? 'Hide QR' : 'Show QR',
              ),
            ],
          ),
          if (_showQr) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(4),
                color: Colors.white,
                child: Image.asset(
                  _linktreeQrAsset,
                  width: 150,
                  height: 150,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _shareQrCode(context),
                icon: const Icon(Icons.share_rounded, size: 16),
                label: const Text('Share Link & QR'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
