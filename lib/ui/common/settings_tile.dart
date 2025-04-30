import 'package:flutter/material.dart';
import 'package:nesd/ui/common/nesd_button.dart';

class SettingsTile extends StatelessWidget {
  const SettingsTile({
    required this.child,
    this.title,
    this.subtitle,
    this.enabled = true,
    this.adaptive = false,
    this.onTap,
    super.key,
  });

  final Widget? title;
  final Widget? subtitle;
  final Widget child;

  final bool enabled;

  final bool adaptive;

  final GestureTapCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final wrappedTitle = DefaultTextStyle(
      style: DefaultTextStyle.of(context).style.copyWith(
        color: enabled ? null : Colors.grey[800],
        fontSize: 15,
        fontVariations: const [FontVariation.weight(700)],
      ),
      child: title ?? const SizedBox(),
    );

    return InkWell(
      onTap: enabled ? onTap : null,
      child: LayoutBuilder(
        builder: (_, constraints) {
          final narrow = constraints.maxWidth < 600;
          final column = adaptive && narrow;

          final titles = [
            if (title != null) wrappedTitle,
            if (subtitle != null)
              DefaultTextStyle(
                style: DefaultTextStyle.of(context).style.copyWith(
                  color: enabled ? Colors.grey[400] : Colors.grey[800],
                  fontSize: 14,
                ),
                child: subtitle!,
              ),
          ];

          final wrappedTitles =
              column
                  ? Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: titles,
                  )
                  : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: titles,
                  );

          final wrappedChild = SizedBox(
            height: 70,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth:
                    column
                        ? constraints.maxWidth
                        : constraints.maxWidth * 2 / 3,
              ),
              child: ExcludeFocus(child: child),
            ),
          );

          final children = [if (title != null) wrappedTitles, wrappedChild];

          return SizedBox(
            height: column ? 100.0 : 70.0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child:
                  column
                      ? Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: children,
                      )
                      : Row(
                        mainAxisAlignment:
                            title != null
                                ? MainAxisAlignment.spaceBetween
                                : MainAxisAlignment.center,
                        children: children,
                      ),
            ),
          );
        },
      ),
    );
  }
}

class SwitchSettingsTile extends StatelessWidget {
  const SwitchSettingsTile({
    required this.title,
    required this.value,
    required this.onChanged,
    super.key,
  });

  final Widget title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SettingsTile(
      title: title,
      onTap: () => onChanged(!value),
      child: Switch(value: value, onChanged: onChanged),
    );
  }
}

class IconButtonSettingsTile extends StatelessWidget {
  const IconButtonSettingsTile({
    required this.title,
    required this.icon,
    required this.onPressed,
    super.key,
  });

  final Widget title;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SettingsTile(
      title: title,
      onTap: onPressed,
      child: Padding(
        padding: const EdgeInsets.only(right: 16),
        child: Icon(icon, size: 32),
      ),
    );
  }
}

class ButtonSettingsTile extends StatelessWidget {
  const ButtonSettingsTile({
    required this.title,
    required this.onPressed,
    super.key,
  });

  final Widget title;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SettingsTile(
      onTap: onPressed,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: NesdButton(onPressed: onPressed, child: title),
      ),
    );
  }
}
