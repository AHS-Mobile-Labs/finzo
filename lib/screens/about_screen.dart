import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/app_theme.dart';

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
            expandedHeight: 220,
            backgroundColor: AppTheme.backgroundColor,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
              title: const Text(
                'About Finzo',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              background: const _HeroHeader(),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
            sliver: SliverList.list(
              children: [
                const _PrivacyCard()
                    .animate()
                    .fadeIn(duration: 280.ms)
                    .slideY(begin: .08, end: 0),
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
                  body: 'Your finance book stays local and available anytime.',
                ),
                const _PrincipleTile(
                  icon: Icons.lock_rounded,
                  title: 'Privacy focused',
                  body: 'No cloud account is required for everyday tracking.',
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
                const SizedBox(height: 10),
                _ContactButton(
                  icon: Icons.link_rounded,
                  label: 'Linktree',
                  subtitle: 'All project links',
                  url: 'https://linktr.ee/ahsmobilelabs',
                  onTap: _launchUrl,
                ),
                const SizedBox(height: 18),
                _LinktreeQrCard(
                  onTap: () => _launchUrl('https://linktr.ee/ahsmobilelabs'),
                ),
                const SizedBox(height: 28),
                const Center(
                  child: Text(
                    'Finzo v1.0.0  |  AHS Mobile Labs',
                    style: TextStyle(color: Colors.white38, fontSize: 12),
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

class _HeroHeader extends StatelessWidget {
  const _HeroHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF090D18), Color(0xFF241044), Color(0xFF0F172A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -38,
            top: 28,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryColor.withAlpha(46),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withAlpha(90),
                    blurRadius: 80,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 20,
            top: 84,
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: const LinearGradient(
                      colors: [AppTheme.primaryColor, Color(0xFF38BDF8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withAlpha(90),
                        blurRadius: 26,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.asset(
                    'assets/laucher_icon_img/In use/Finzo Logo.png',
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 14),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Finzo',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      'Private finance, beautifully offline',
                      style: TextStyle(color: Colors.white60, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
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

class _LinktreeQrCard extends StatelessWidget {
  final VoidCallback onTap;

  const _LinktreeQrCard({required this.onTap});

  Future<void> _shareQrCode(BuildContext context) async {
    try {
      final uri = Uri.parse('https://linktr.ee/ahsmobilelabs');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Share error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white.withAlpha(16)),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withAlpha(30),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              // QR Code - made larger and more prominent
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withAlpha(50),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                  child: Image.asset(
                    'assets/app image/Linktree QR code/ahsmobilelabs.png',
                    width: 180,
                    height: 180,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Title and Description
              const Column(
                children: [
                  Text(
                    'AHS Mobile Labs',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Scan to explore all our projects and social media',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: onTap,
                        borderRadius: BorderRadius.circular(12),
                        child: Ink(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.qr_code_2_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Open Link',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _shareQrCode(context),
                        borderRadius: BorderRadius.circular(12),
                        child: Ink(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withAlpha(30),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.share_rounded,
                                color: Colors.white70,
                                size: 18,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Share',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
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
              const SizedBox(height: 12),
              // Linktree URL Text
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(6),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withAlpha(12)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.link_rounded,
                      color: AppTheme.primaryColor,
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'linktr.ee/ahsmobilelabs',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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
