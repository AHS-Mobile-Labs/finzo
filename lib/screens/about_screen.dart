import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/app_theme.dart';
import '../widgets/app_logo.dart';

const _linktreeUrl = 'https://linktr.ee/ahsmobilelabs';
const _linktreeQrAsset = 'assets/app image/Linktree QR code/ahsmobilelabs.png';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  Future<void> _launchUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        // Fallback for Android - try launching with platform default
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      // Silent catch for unavailable apps
      debugPrint('Could not launch URL: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            pinned: true,
            toolbarHeight: 64,
            expandedHeight: 220,
            backgroundColor: AppTheme.backgroundColor,
            surfaceTintColor: Colors.transparent,
            titleSpacing: 0,
            title: const Text(
              'About Us',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            flexibleSpace: const FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              background: _HeroHeader(),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              MediaQuery.sizeOf(context).width < 360 ? 16 : 20,
              18,
              MediaQuery.sizeOf(context).width < 360 ? 16 : 20,
              28,
            ),
            sliver: SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _PrivacyCard()
                          .animate()
                          .fadeIn(duration: 280.ms)
                          .slideY(begin: .08, end: 0),
                      const SizedBox(height: 14),
                      const _StudioCard(),
                      const SizedBox(height: 18),
                      const _SectionTitle('Built For'),
                      const SizedBox(height: 10),
                      const Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _FeatureChip(
                            icon: Icons.account_balance_wallet_rounded,
                            label: 'Accounts',
                          ),
                          _FeatureChip(
                            icon: Icons.swap_horiz_rounded,
                            label: 'Transfers',
                          ),
                          _FeatureChip(
                            icon: Icons.pie_chart_rounded,
                            label: 'Budgets',
                          ),
                          _FeatureChip(
                            icon: Icons.insights_rounded,
                            label: 'Analytics',
                          ),
                          _FeatureChip(
                            icon: Icons.credit_card_rounded,
                            label: 'Cards',
                          ),
                          _FeatureChip(
                            icon: Icons.trending_up_rounded,
                            label: 'Investing',
                          ),
                          _FeatureChip(
                            icon: Icons.account_balance_rounded,
                            label: 'Loans',
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const _SectionTitle('Principles'),
                      const SizedBox(height: 10),
                      const _PrincipleTile(
                        icon: Icons.offline_bolt_rounded,
                        title: 'Offline first',
                        body:
                            'Your finance book stays local and available anytime.',
                      ),
                      const _PrincipleTile(
                        icon: Icons.lock_rounded,
                        title: 'Privacy focused',
                        body:
                            'No cloud account is required for everyday tracking.',
                      ),
                      const _PrincipleTile(
                        icon: Icons.folder_special_rounded,
                        title: 'Visible exports',
                        body:
                            'CSV files and book backups are saved to the Finzo folder on your device.',
                      ),
                      const _PrincipleTile(
                        icon: Icons.auto_graph_rounded,
                        title: 'Decision ready',
                        body:
                            'Dashboards, budgets, loans, cards, and investments stay connected.',
                      ),
                      const SizedBox(height: 24),
                      const _SectionTitle('Connect'),
                      const SizedBox(height: 10),
                      _ContactButton(
                        icon: Icons.mail_outline_rounded,
                        label: 'Email',
                        subtitle: 'ahsmobilelabs@gmail.com',
                        url: 'mailto:ahsmobilelabs@gmail.com',
                        onTap: _launchUrl,
                      ),
                      const SizedBox(height: 10),
                      _ContactButton(
                        icon: Icons.code_rounded,
                        label: 'GitHub - AHS Mobile Labs',
                        subtitle: 'github.com/AHS-Mobile-Labs',
                        url: 'https://github.com/AHS-Mobile-Labs',
                        onTap: _launchUrl,
                      ),
                      const SizedBox(height: 10),
                      _ContactButton(
                        icon: Icons.code_rounded,
                        label: 'GitHub - Finzo',
                        subtitle: 'github.com/AHS-Mobile-Labs/finzo',
                        url: 'https://github.com/AHS-Mobile-Labs/finzo',
                        onTap: _launchUrl,
                      ),
                      const SizedBox(height: 10),
                      _ContactButton(
                        icon: Icons.camera_alt_rounded,
                        label: 'Instagram',
                        subtitle: '@ahsmobilelabs',
                        url: 'https://www.instagram.com/ahsmobilelabs',
                        onTap: _launchUrl,
                      ),
                      const SizedBox(height: 10),
                      _ContactButton(
                        icon: Icons.play_circle_outline_rounded,
                        label: 'YouTube',
                        subtitle: '@AHSMobileLabs',
                        url: 'https://www.youtube.com/@AHSMobileLabs',
                        onTap: _launchUrl,
                      ),
                      const SizedBox(height: 10),
                      _ContactButton(
                        icon: Icons.tag_rounded,
                        label: 'X (Twitter)',
                        subtitle: '@ahsmobilelabs',
                        url: 'https://x.com/ahsmobilelabs',
                        onTap: _launchUrl,
                      ),
                      const SizedBox(height: 18),
                      const _LinktreeQrCard(),
                      const SizedBox(height: 28),
                      const Center(
                        child: Text(
                          'Finzo v1.0.1  |  AHS Mobile Labs',
                          style: TextStyle(color: Colors.white38, fontSize: 12),
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

class _HeroHeader extends StatelessWidget {
  const _HeroHeader();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final horizontalPadding = width < 360 ? 16.0 : 20.0;

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppTheme.surfaceColor,
        border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            76,
            horizontalPadding,
            22,
          ),
          child: Align(
            alignment: Alignment.bottomLeft,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const AppLogo(size: 64, radius: 18),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Finzo',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Private finance by AHS Mobile Labs',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.white60, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PrivacyCard extends StatelessWidget {
  const _PrivacyCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.cardColor.withAlpha(220),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withAlpha(18)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(80),
            blurRadius: 24,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: const Text(
        'Finzo helps you track spending, accounts, budgets, loans, credit cards, and investments in one local finance book. It is designed for quick daily entry and clear monthly decisions.',
        style: TextStyle(color: Colors.white70, height: 1.55, fontSize: 13),
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
        border: Border.all(color: Colors.white.withAlpha(16)),
      ),
      child: const Row(
        children: [
          AppLogo(size: 46, radius: 13),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AHS Mobile Labs',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Independent mobile tools for local-first finance.',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                    height: 1.35,
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

class _LinktreeQrCard extends StatelessWidget {
  static const _shareChannel = MethodChannel('com.ahsmobilelabs.finzo/share');

  const _LinktreeQrCard();

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
    } on PlatformException catch (e) {
      debugPrint('Share platform error: ${e.message}');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Unable to open the share sheet.')),
      );
    } catch (e) {
      debugPrint('Share error: $e');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to share the QR code.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withAlpha(16)),
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(2),
              color: Colors.white,
              child: Image.asset(
                _linktreeQrAsset,
                width: 180,
                height: 180,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'AHS Mobile Labs',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Scan or share the QR code with the project link.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white60, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _shareQrCode(context),
              icon: const Icon(Icons.share_rounded, size: 18),
              label: const Text('Share Link and QR'),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(6),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withAlpha(12)),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.link_rounded,
                  color: AppTheme.primaryColor,
                  size: 14,
                ),
                SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'linktr.ee/ahsmobilelabs',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
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

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 15,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FeatureChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withAlpha(16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppTheme.primaryColor, size: 17),
          const SizedBox(width: 7),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _PrincipleTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _PrincipleTile({
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withAlpha(14)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withAlpha(34),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppTheme.primaryColor, size: 20),
          ),
          const SizedBox(width: 12),
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
                const SizedBox(height: 3),
                Text(
                  body,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                    height: 1.35,
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

class _ContactButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final String url;
  final Future<void> Function(String) onTap;

  const _ContactButton({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.url,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onTap(url),
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withAlpha(16)),
          ),
          child: Row(
            children: [
              Icon(icon, color: AppTheme.primaryColor, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_outward_rounded,
                color: Colors.white38,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
