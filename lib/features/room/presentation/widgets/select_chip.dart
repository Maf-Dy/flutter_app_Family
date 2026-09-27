import 'package:flutter/material.dart';

import '../../../../core/motion/motion.dart';

/// A pill that fills with ink when selected.
class SelectChip extends StatelessWidget {
  const SelectChip({super.key, required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          customBorder: const StadiumBorder(),
          child: AnimatedContainer(
            duration: Motion.of(context, Motion.quick),
            constraints: const BoxConstraints(minHeight: 40),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            decoration: ShapeDecoration(
              color: selected ? scheme.onSurface : scheme.surfaceContainerLowest,
              shape: StadiumBorder(side: BorderSide(color: selected ? scheme.onSurface : scheme.outlineVariant)),
            ),
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(fontSize: 14, color: selected ? scheme.surface : scheme.onSurface),
            ),
          ),
        ),
      ),
    );
  }
}
