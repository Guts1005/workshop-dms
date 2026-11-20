import 'package:flutter/material.dart';

import '../tokens/app_tokens.dart';

/// Belongings & Valuables Inventory Selector (Bucket 1: Token Composition)
/// Allows rapid multi-selection of vehicle inventory at check-in to prevent disputes.
class BelongingsPillsGroup extends StatelessWidget {
  final Set<String> selectedItems;
  final ValueChanged<Set<String>> onChanged;
  final bool isReadOnly;

  static const List<String> standardInventory = [
    'Fastag',
    'Spare Wheel',
    'Jack & Toolkit',
    'Dashcam & SD Card',
    'Original RC / Insurance',
    'Floor Mats & Boot Tray',
    'Keys (Primary + Spare)',
  ];

  const BelongingsPillsGroup({
    super.key,
    required this.selectedItems,
    required this.onChanged,
    this.isReadOnly = false,
  });

  void _toggle(String item) {
    if (isReadOnly) return;
    final updated = Set<String>.from(selectedItems);
    if (updated.contains(item)) {
      updated.remove(item);
    } else {
      updated.add(item);
    }
    onChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: AppTokens.surface,
        borderRadius: AppTokens.cardRadius,
        border: Border.all(color: AppTokens.borderLight),
        boxShadow: AppTokens.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.inventory_2_outlined,
                size: 16.0,
                color: AppTokens.textPrimary,
              ),
              const SizedBox(width: 8.0),
              Expanded(
                child: Text(
                  'VALUABLES & BELONGINGS',
                  style: AppTokens.fontMonospace(
                    fontSize: 11.0,
                    fontWeight: FontWeight.w800,
                    color: AppTokens.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8.0),
              Text(
                '${selectedItems.length} CONFIRMED',
                style: AppTokens.fontMonospace(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  color: AppTokens.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12.0),
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: standardInventory.map((item) {
              final isSelected = selectedItems.contains(item);
              return InkWell(
                onTap: isReadOnly ? null : () => _toggle(item),
                borderRadius: AppTokens.pillRadius,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12.0,
                    vertical: 8.0,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTokens.inverse
                        : AppTokens.surfaceSubtle,
                    borderRadius: AppTokens.pillRadius,
                    border: Border.all(
                      color: isSelected
                          ? AppTokens.inverse
                          : AppTokens.borderLight,
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isSelected
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked,
                        size: 14.0,
                        color: isSelected
                            ? Colors.white
                            : AppTokens.textSecondary,
                      ),
                      const SizedBox(width: 6.0),
                      Text(
                        item,
                        style: AppTokens.fontBody(
                          fontSize: 12.0,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : AppTokens.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
