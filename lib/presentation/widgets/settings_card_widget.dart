import 'package:auno/core/localization/app_strings.dart';
import 'glass_surface.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class SettingsIconBadge extends StatelessWidget {
  const SettingsIconBadge({
    super.key,
    required this.icon,
    this.color,
    this.backgroundColor,
  });
  final IconData icon;
  final Color? color, backgroundColor;
  @override
  Widget build(BuildContext context) => Container(
    width: 44,
    height: 44,
    decoration: BoxDecoration(
      color: backgroundColor ?? AppColors.primary.withValues(alpha: .1),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: Colors.white.withValues(alpha: .14)),
    ),
    child: Icon(icon, size: 22, color: color ?? AppColors.primary),
  );
}

class SettingsCardGroup extends StatelessWidget {
  const SettingsCardGroup({
    super.key,
    required this.title,
    required this.children,
  });
  final String title;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 10),
          child: AppText(
            context.tr(title).toUpperCase(),
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.3,
            ),
          ),
        ),
        GlassSurface(
          child: Material(
            color: Colors.transparent,
            child: Column(children: children),
          ),
        ),
      ],
    ),
  );
}

class SettingsCardTile extends StatelessWidget {
  const SettingsCardTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.iconColor,
    this.iconBgColor,
    this.trailing,
  });
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Color? iconColor, iconBgColor;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final below = trailing != null && constraints.maxWidth < 340;
      return InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  SettingsIconBadge(
                    icon: icon,
                    color: iconColor,
                    backgroundColor: iconBgColor,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            height: 1.35,
                          ),
                        ),
                        if (subtitle?.isNotEmpty == true) ...[
                          const SizedBox(height: 4),
                          AppText(
                            subtitle!,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (!below) ...[
                    const SizedBox(width: 8),
                    if (trailing != null)
                      trailing!
                    else if (onTap != null)
                      const Icon(
                        Icons.chevron_right,
                        color: Colors.white54,
                        size: 22,
                      ),
                  ],
                ],
              ),
              if (below)
                Padding(
                  padding: const EdgeInsets.only(left: 58, top: 8),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: trailing!,
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );
}

class SettingsSwitchTile extends StatelessWidget {
  const SettingsSwitchTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });
  final IconData icon;
  final String title, subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final compact = constraints.maxWidth < 340;
      final description = AppText(
        subtitle,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 13,
          height: 1.5,
        ),
      );
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SwitchListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 10,
            ),
            secondary: SettingsIconBadge(icon: icon),
            title: AppText(
              title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            subtitle: compact
                ? null
                : Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: description,
                  ),
            value: value,
            onChanged: onChanged,
          ),
          if (compact)
            Padding(
              padding: const EdgeInsets.fromLTRB(74, 0, 16, 16),
              child: description,
            ),
        ],
      );
    },
  );
}

class SettingsChoiceTile extends StatelessWidget {
  const SettingsChoiceTile({
    super.key,
    required this.title,
    this.subtitle,
    required this.selected,
    required this.onTap,
  });
  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      selected: selected,
      selectedTileColor: AppColors.primary.withValues(alpha: .08),
      leading: Icon(
        selected ? Icons.radio_button_checked : Icons.radio_button_off,
        color: selected ? AppColors.primary : Colors.white54,
      ),
      title: AppText(
        title,
        style: TextStyle(
          color: selected ? AppColors.primary : Colors.white,
          fontSize: 15,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
      subtitle: subtitle == null
          ? null
          : Padding(
              padding: const EdgeInsets.only(top: 4),
              child: AppText(
                subtitle!,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
            ),
      onTap: onTap,
    ),
  );
}

class SettingsInfoTile extends StatelessWidget {
  const SettingsInfoTile({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
  });
  final IconData icon;
  final String title, description;
  @override
  Widget build(BuildContext context) =>
      SettingsCardTile(icon: icon, title: title, subtitle: description);
}

class SettingsCardDivider extends StatelessWidget {
  const SettingsCardDivider({super.key});
  @override
  Widget build(BuildContext context) => const Divider(
    height: 1,
    thickness: .7,
    indent: 74,
    endIndent: 16,
    color: Colors.white12,
  );
}
