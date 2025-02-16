import 'package:flutter/material.dart';
import 'package:nesd/ui/common/nesd_button.dart';

class SettingsTile extends StatelessWidget {
  const SettingsTile({
    required this.child,
    this.title,
    this.enabled = true,
    this.adaptive = false,
    this.onTap,
    super.key,
  });

  final Widget? title;
  final Widget child;

  final bool enabled;

  final bool adaptive;

  final GestureTapCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final wrappedTitle = DefaultTextStyle(
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      child: title ?? const SizedBox(),
    );

    return InkWell(
      onTap: enabled ? onTap : null,
      child: LayoutBuilder(
        builder: (_, constraints) {
          final narrow = constraints.maxWidth < 500;
          final column = adaptive && narrow;
          final height = column ? 140.0 : 70.0;

          final wrappedChild = SizedBox(
            height: 70,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth:
                    column ? constraints.maxWidth : constraints.maxWidth / 2,
              ),
              child: ExcludeFocus(child: child),
            ),
          );

          final children = [if (title != null) wrappedTitle, wrappedChild];

          return SizedBox(
            height: height,
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
