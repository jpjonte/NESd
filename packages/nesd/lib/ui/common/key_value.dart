import 'package:flutter/widgets.dart';

class KeyValue extends StatelessWidget {
  const KeyValue(this.label, this.value, {this.color, super.key});

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontVariations: [FontVariation.weight(700)]),
          ),
          Text(value, style: TextStyle(color: color)),
        ],
      ),
    );
  }
}
