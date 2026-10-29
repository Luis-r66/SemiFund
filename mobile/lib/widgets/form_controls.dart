import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/utils/formatters.dart';

/// Barra de búsqueda con forma de píldora (Figma: "Buscar integrante").
class SearchField extends StatelessWidget {
  const SearchField({
    super.key,
    required this.controller,
    required this.hintText,
    this.onChanged,
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: AppTextStyles.body,
        decoration: InputDecoration(
          hintText: hintText,
          filled: true,
          fillColor: AppColors.mist,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          prefixIcon: const Padding(
            padding: EdgeInsets.only(left: 14, right: 8),
            child: Icon(LucideIcons.search, size: 17, color: AppColors.ink3),
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 0,
            minHeight: 0,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(999),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(999),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(999),
            borderSide: const BorderSide(color: AppColors.line),
          ),
        ),
      ),
    );
  }
}

/// Pestañas segmentadas (Figma: Todos / Pendiente / Vencido).
class SegmentedTabs<T> extends StatelessWidget {
  const SegmentedTabs({
    super.key,
    required this.options,
    required this.selected,
    required this.labelOf,
    required this.onChanged,
  });

  final List<T> options;
  final T selected;
  final String Function(T value) labelOf;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.mist,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: <Widget>[
          for (final T option in options)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(option),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: option == selected
                        ? AppColors.paper
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: option == selected
                        ? const <BoxShadow>[
                            BoxShadow(
                              color: Color(0x14000000),
                              blurRadius: 2,
                              offset: Offset(0, 1),
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    labelOf(option),
                    style: AppTextStyles.smallSemibold.copyWith(
                      color: option == selected
                          ? AppColors.ink
                          : AppColors.ink2,
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

/// Selector desplegable con el estilo de los inputs de la maquetación.
class SelectField<T> extends StatelessWidget {
  const SelectField({
    super.key,
    required this.value,
    required this.items,
    required this.labelOf,
    required this.hintText,
    required this.onChanged,
    this.error,
  });

  final T? value;
  final List<T> items;
  final String Function(T value) labelOf;
  final String hintText;
  final ValueChanged<T?> onChanged;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final T? safeValue = items.contains(value) ? value : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.paper,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: error == null ? AppColors.line : AppColors.bad,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: safeValue,
              isExpanded: true,
              menuMaxHeight: 320,
              borderRadius: BorderRadius.circular(12),
              dropdownColor: AppColors.paper,
              style: AppTextStyles.body,
              icon: const Icon(
                LucideIcons.chevronDown,
                size: 17,
                color: AppColors.ink2,
              ),
              hint: Text(
                hintText,
                style: AppTextStyles.body.copyWith(color: AppColors.ink3),
              ),
              items: <DropdownMenuItem<T>>[
                for (final T item in items)
                  DropdownMenuItem<T>(value: item, child: Text(labelOf(item))),
              ],
              onChanged: onChanged,
            ),
          ),
        ),
        if (error != null) ...<Widget>[
          const SizedBox(height: 7),
          Text(
            error!,
            style: AppTextStyles.smallMedium.copyWith(color: AppColors.bad),
          ),
        ],
      ],
    );
  }
}

/// Convierte la entrada a miles con separador "." (formato es-CO).
class ThousandsInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final String digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }
    final String formatted = formatThousands(int.parse(digits));
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// Campo de monto en COP con prefijo "$", estilo de la maquetación.
class MoneyField extends StatelessWidget {
  const MoneyField({
    super.key,
    required this.controller,
    this.invalid = false,
    this.onChanged,
  });

  final TextEditingController controller;
  final bool invalid;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final Color borderColor = invalid ? AppColors.bad : AppColors.line;
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: <Widget>[
          Text(
            '\$',
            style: AppTextStyles.moneySmall.copyWith(color: AppColors.ink3),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              keyboardType: TextInputType.number,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly,
                ThousandsInputFormatter(),
              ],
              style: AppTextStyles.moneySmall.copyWith(
                color: invalid ? AppColors.bad : AppColors.ink,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
                hintText: '0',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
