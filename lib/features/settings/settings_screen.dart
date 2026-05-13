import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/extensions/l10n_extension.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = context.l10n;
    final themeProvider = context.watch<ThemeProvider>();
    final localeProvider = context.watch<LocaleProvider>();
    final auth = context.read<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.charcoal,
      appBar: AppBar(
        backgroundColor: AppColors.charcoal,
        elevation: 0,
        title: Text(l.settingsTitle, style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Profile card
          _ProfileCard(email: auth.currentUser?.email ?? 'Organizer'),
          const SizedBox(height: 32),

          // ── Language ────────────────────────────────────────────
          _SectionHeader(l.languageSection),
          const SizedBox(height: 16),
          _LanguageTile(localeProvider: localeProvider),
          const SizedBox(height: 32),

          // ── Appearance ─────────────────────────────────────────
          _SectionHeader(l.appearanceSection),
          const SizedBox(height: 16),
          _SettingTile(
            icon: themeProvider.themeMode == ThemeMode.dark
                ? Icons.dark_mode_rounded
                : Icons.light_mode_rounded,
            title: l.darkModeLabel,
            trailing: Switch(
              value: themeProvider.themeMode == ThemeMode.dark,
              onChanged: (_) => themeProvider.toggleThemeMode(),
              activeColor: AppColors.brushedGold,
              activeTrackColor: AppColors.brushedGold.withValues(alpha: 0.3),
            ),
          ),
          const SizedBox(height: 32),

          // ── Account ─────────────────────────────────────────────
          _SectionHeader(l.accountSection),
          const SizedBox(height: 16),
          _SettingTile(
            icon: Icons.logout_rounded,
            title: l.signOutLabel,
            iconColor: AppColors.declined,
            onTap: () => auth.signOut(),
          ),
          const SizedBox(height: 48),

          Center(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.verified_user_outlined, size: 20, color: Colors.white24),
                ),
                const SizedBox(height: 12),
                Text(l.versionLabel,
                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.white24, letterSpacing: 1)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Language Tile ──────────────────────────────────────────────────────────

class _LanguageTile extends StatelessWidget {
  final LocaleProvider localeProvider;
  const _LanguageTile({required this.localeProvider});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = context.l10n;
    final isDark = theme.brightness == Brightness.dark;
    final baseColor = isDark ? Colors.white : Colors.black;

    final options = [
      _LangOption(code: 'auto', label: l.langAuto, flag: '🌐', icon: Icons.language_rounded),
      _LangOption(code: 'en', label: l.langEnglish, flag: '🇺🇸', icon: Icons.translate_rounded),
      _LangOption(code: 'es', label: l.langSpanish, flag: '🇲🇽', icon: Icons.translate_rounded),
    ];

    final current = options.firstWhere(
      (o) => o.code == localeProvider.currentCode,
      orElse: () => options.first,
    );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.brushedGold.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Text(current.flag, style: const TextStyle(fontSize: 20)),
        ),
        title: Text(l.languageLabel, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700, color: Colors.white)),
        subtitle: Text(current.label, style: theme.textTheme.bodySmall?.copyWith(color: Colors.white38)),
        trailing: const Icon(Icons.expand_more_rounded, color: Colors.white24),
        onTap: () => _showLanguagePicker(context, l, options),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
    );
  }

  void _showLanguagePicker(BuildContext context, dynamic l, List<_LangOption> options) {
    final localeProvider = context.read<LocaleProvider>();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.charcoal,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.languageSection,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.5)),
              const SizedBox(height: 24),
              ...options.map((opt) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: localeProvider.currentCode == opt.code ? AppColors.brushedGold.withValues(alpha: 0.1) : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: localeProvider.currentCode == opt.code ? AppColors.brushedGold.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.05)),
                ),
                child: ListTile(
                  leading: Text(opt.flag, style: const TextStyle(fontSize: 24)),
                  title: Text(opt.label, style: TextStyle(color: Colors.white, fontWeight: localeProvider.currentCode == opt.code ? FontWeight.w800 : FontWeight.w500)),
                  trailing: localeProvider.currentCode == opt.code ? const Icon(Icons.check_circle_rounded, color: AppColors.brushedGold) : null,
                  onTap: () {
                    localeProvider.setLocale(opt.code);
                    Navigator.pop(context);
                  },
                ),
              )),
            ],
          ),
        );
      },
    );
  }
}

class _LangOption {
  final String code;
  final String label;
  final String flag;
  final IconData icon;
  const _LangOption({required this.code, required this.label, required this.flag, required this.icon});
}

// ── Shared Widgets ──────────────────────────────────────────────────────────

class _ProfileCard extends StatelessWidget {
  final String email;
  const _ProfileCard({required this.email});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = context.l10n;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.brushedGold,
            AppColors.brushedGold.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: AppColors.brushedGold.withValues(alpha: 0.2),
            blurRadius: 30,
            offset: const Offset(0, 15),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.charcoal.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.charcoal.withValues(alpha: 0.1)),
            ),
            child: CircleAvatar(
              radius: 32,
              backgroundColor: AppColors.charcoal,
              child: Text(
                email.isNotEmpty ? email[0].toUpperCase() : 'P',
                style: const TextStyle(color: AppColors.brushedGold, fontSize: 28, fontWeight: FontWeight.w900),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.organizerLabel,
                    style: theme.textTheme.titleLarge?.copyWith(color: AppColors.charcoal, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                const SizedBox(height: 2),
                Text(email, style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.charcoal.withValues(alpha: 0.6), fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.charcoal,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4, offset: const Offset(0, 2))
              ],
            ),
            child: const Row(
              children: [
                Icon(Icons.stars_rounded, size: 14, color: AppColors.brushedGold),
                SizedBox(width: 4),
                Text('PRO', style: TextStyle(color: AppColors.brushedGold, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(title.toUpperCase(),
        style: const TextStyle(color: AppColors.brushedGold, letterSpacing: 2, fontWeight: FontWeight.w900, fontSize: 11));
  }
}

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? trailing;
  final Color? iconColor;
  final VoidCallback? onTap;

  const _SettingTile({required this.icon, required this.title, this.trailing, this.iconColor, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (iconColor ?? AppColors.brushedGold).withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor ?? AppColors.brushedGold, size: 20),
        ),
        title: Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700, color: Colors.white)),
        trailing: trailing ?? const Icon(Icons.chevron_right_rounded, color: Colors.white24),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
    );
  }
}
