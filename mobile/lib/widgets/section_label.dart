import 'package:flutter/material.dart';

import '../core/theme/app_text_styles.dart';

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
      child: Text(text.toUpperCase(), style: AppTextStyles.label),
    );
  }
}
