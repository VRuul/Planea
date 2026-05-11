import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
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
      appBar: AppBar(title: Text(l.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Profile card
          _ProfileCard(email: auth.currentUser?.email ?? 'Organizer'),
          const SizedBox(height: 24),

          // ── Language ────────────────────────────────────────────
          _SectionHeader(l.languageSection),
          const SizedBox(height: 12),
          _LanguageTile(localeProvider: localeProvider),
          const SizedBox(height: 24),

          // ── Appearance ─────────────────────────────────────────
          _SectionHeader(l.appearanceSection),
          const SizedBox(height: 12),
          _SettingTile(
            icon: themeProvider.themeMode == ThemeMode.dark
                ? Icons.dark_mode_rounded
                : Icons.light_mode_rounded,
            title: l.darkModeLabel,
            trailing: Switch(
              value: themeProvider.themeMode == ThemeMode.dark,
              onChanged: (_) => themeProvider.toggleThemeMode(),
              activeThumbColor: AppColors.brushedGold,
            ),
          ),
          const SizedBox(height: 24),

          // ── Color Palette ───────────────────────────────────────
          _SectionHeader(l.globalPaletteSection),
          const SizedBox(height: 12),
          _ColorSettingTile(
            label: l.primaryColorSetting,
            color: themeProvider.primaryColor,
            onPick: (c) => themeProvider.setPrimaryColor(c),
          ),
          const SizedBox(height: 8),
          _ColorSettingTile(
            label: l.accentColorSetting,
            color: themeProvider.secondaryColor,
            onPick: (c) => themeProvider.setSecondaryColor(c),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => themeProvider.applyEventColors(
                AppColors.charcoal, AppColors.brushedGold),
            icon: const Icon(Icons.refresh_rounded),
            label: Text(l.restorePaletteButton),
          ),
          const SizedBox(height: 24),

          // ── Theme Preview ───────────────────────────────────────
          _SectionHeader(l.themePreviewSection),
          const SizedBox(height: 12),
          _ThemePreviewCard(themeProvider: themeProvider),
          const SizedBox(height: 24),

          // ── Account ─────────────────────────────────────────────
          _SectionHeader(l.accountSection),
          const SizedBox(height: 12),
          _SettingTile(
            icon: Icons.logout_rounded,
            title: l.signOutLabel,
            iconColor: AppColors.declined,
            onTap: () => auth.signOut(),
          ),
          const SizedBox(height: 32),

          Center(
            child: Text(l.versionLabel,
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
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

    final options = [
      _LangOption(code: 'auto', label: l.langAuto,
          flag: '🌐', icon: Icons.language_rounded),
      _LangOption(code: 'en', label: l.langEnglish,
          flag: '🇺🇸', icon: Icons.translate_rounded),
      _LangOption(code: 'es', label: l.langSpanish,
          flag: '🇲🇽', icon: Icons.translate_rounded),
    ];

    final current = options.firstWhere(
      (o) => o.code == localeProvider.currentCode,
      orElse: () => options.first,
    );

    return Container(
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          ListTile(
            leading: Text(current.flag,
                style: const TextStyle(fontSize: 24)),
            title: Text(l.languageLabel,
                style: theme.textTheme.titleSmall),
            subtitle: Text(current.label,
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
            trailing: const Icon(Icons.expand_more_rounded),
            onTap: () => _showLanguagePicker(context, l, options),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
          ),
        ],
      ),
    );
  }

  void _showLanguagePicker(BuildContext context, AppLocalizations l,
      List<_LangOption> options) {
    final localeProvider = context.read<LocaleProvider>();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.languageSection,
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              ...options.map((opt) => ListTile(
                leading: Text(opt.flag,
                    style: const TextStyle(fontSize: 24)),
                title: Text(opt.label),
                trailing: localeProvider.currentCode == opt.code
                    ? Icon(Icons.check_rounded, color: AppColors.brushedGold)
                    : null,
                onTap: () {
                  localeProvider.setLocale(opt.code);
                  Navigator.pop(context);
                },
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
  const _LangOption({required this.code, required this.label,
      required this.flag, required this.icon});
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.goldGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(
          color: AppColors.brushedGold.withValues(alpha: 0.3),
          blurRadius: 20, offset: const Offset(0, 8),
        )],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.charcoal.withValues(alpha: 0.3),
            child: Text(
              email.isNotEmpty ? email[0].toUpperCase() : 'P',
              style: const TextStyle(
                  color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.organizerLabel,
                    style: theme.textTheme.titleMedium?.copyWith(
                        color: AppColors.charcoal, fontWeight: FontWeight.w700)),
                Text(email,
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.charcoal.withValues(alpha: 0.7))),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.charcoal.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text('⭐ PRO',
                style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.charcoal, fontWeight: FontWeight.w800)),
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
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Colors.grey, letterSpacing: 1.5, fontWeight: FontWeight.w700));
  }
}

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? trailing;
  final Color? iconColor;
  final VoidCallback? onTap;

  const _SettingTile({
    required this.icon, required this.title,
    this.trailing, this.iconColor, this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
          color: theme.cardTheme.color, borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: Icon(icon, color: iconColor ?? AppColors.brushedGold),
        title: Text(title, style: theme.textTheme.titleSmall),
        trailing: trailing ?? const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}

class _ColorSettingTile extends StatelessWidget {
  final String label;
  final Color color;
  final ValueChanged<Color> onPick;

  const _ColorSettingTile(
      {required this.label, required this.color, required this.onPick});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = context.l10n;
    return Container(
      decoration: BoxDecoration(
          color: theme.cardTheme.color, borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            color: color, shape: BoxShape.circle,
            border: Border.all(
                color: Colors.white.withValues(alpha: 0.2), width: 2),
            boxShadow: [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 8)],
          ),
        ),
        title: Text(label, style: theme.textTheme.titleSmall),
        subtitle: Text(
          '#${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
          style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
        ),
        trailing: const Icon(Icons.color_lens_outlined),
        onTap: () => _pickColor(context, l),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Future<void> _pickColor(BuildContext context, AppLocalizations l) async {
    Color selected = color;
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(l.chooseColorFor(label)),
        content: SingleChildScrollView(
          child: ColorPicker(
            color: color,
            onColorChanged: (c) => selected = c,
            heading: Text(l.selectColorHeading,
                style: Theme.of(context).textTheme.titleSmall),
            subheading: Text(l.adjustToneSubheading,
                style: Theme.of(context).textTheme.bodySmall),
            pickersEnabled: const {
              ColorPickerType.both: true,
              ColorPickerType.primary: false,
              ColorPickerType.accent: false,
              ColorPickerType.bw: false,
              ColorPickerType.custom: true,
              ColorPickerType.wheel: true,
            },
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l.cancelButton)),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l.applyButton)),
        ],
      ),
    );
    if (result == true) onPick(selected);
  }
}

class _ThemePreviewCard extends StatelessWidget {
  final ThemeProvider themeProvider;
  const _ThemePreviewCard({required this.themeProvider});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = context.l10n;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: themeProvider.secondaryColor.withValues(alpha: 0.3)),
      ),
      child: Column(children: [
        Container(
          height: 40,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              themeProvider.primaryColor,
              themeProvider.secondaryColor,
            ]),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(
            child: Container(
              height: 36,
              decoration: BoxDecoration(
                color: themeProvider.secondaryColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(l.buttonPreviewLabel,
                    style: TextStyle(
                        color: themeProvider.primaryColor,
                        fontWeight: FontWeight.w700)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 36,
              decoration: BoxDecoration(
                border: Border.all(
                    color: themeProvider.secondaryColor, width: 1.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(l.outlinePreviewLabel,
                    style: TextStyle(
                        color: themeProvider.secondaryColor,
                        fontWeight: FontWeight.w700)),
              ),
            ),
          ),
        ]),
      ]),
    );
  }
}
