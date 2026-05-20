import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class PremiumPickerItem<T> {
  final T value;
  final String label;
  final IconData icon;
  final bool isSpecial;

  const PremiumPickerItem({
    required this.value,
    required this.label,
    required this.icon,
    this.isSpecial = false,
  });
}

class PremiumPicker<T> extends StatelessWidget {
  final String label;
  final IconData icon;
  final T value;
  final List<PremiumPickerItem<T>> items;
  final ValueChanged<T?> onChanged;

  const PremiumPicker({
    super.key,
    required this.label,
    required this.icon,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.white : Colors.black;
    
    // Try to find the selected item, or fallback to the first one if value is null but not allowed
    final selectedItem = items.firstWhere(
      (it) => it.value == value, 
      orElse: () => items.first
    );

    return InkWell(
      onTap: () => _showPicker(context),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: baseColor.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: baseColor.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: [
            Icon(
              value == null ? icon : selectedItem.icon, 
              color: AppColors.brushedGold, 
              size: 20
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label.toUpperCase(), 
                    style: const TextStyle(
                      color: AppColors.brushedGold, 
                      fontSize: 9, 
                      fontWeight: FontWeight.w900, 
                      letterSpacing: 1.2
                    )
                  ),
                  const SizedBox(height: 2),
                  Text(
                    selectedItem.label, 
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87, 
                      fontSize: 14, 
                      fontWeight: FontWeight.w600
                    )
                  ),
                ],
              ),
            ),
            Icon(
              Icons.unfold_more_rounded, 
              color: baseColor.withValues(alpha: 0.3), 
              size: 20
            ),
          ],
        ),
      ),
    );
  }

  void _showPicker(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: (isDark ? AppColors.charcoal : Colors.white).withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: AppColors.brushedGold.withValues(alpha: 0.2)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40, 
                  height: 4, 
                  decoration: BoxDecoration(
                    color: AppColors.brushedGold.withValues(alpha: 0.2), 
                    borderRadius: BorderRadius.circular(2)
                  )
                ),
                const SizedBox(height: 20),
                Text(
                  label.toUpperCase(), 
                  style: const TextStyle(
                    color: AppColors.brushedGold, 
                    fontWeight: FontWeight.w900, 
                    fontSize: 11, 
                    letterSpacing: 2
                  )
                ),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.6
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final isSelected = item.value == value;
                      
                      return InkWell(
                        onTap: () {
                          Navigator.pop(context);
                          onChanged(item.value);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          decoration: BoxDecoration(
                            color: isSelected 
                                ? AppColors.brushedGold.withValues(alpha: 0.05) 
                                : Colors.transparent,
                            border: Border(
                              left: BorderSide(
                                color: isSelected ? AppColors.brushedGold : Colors.transparent, 
                                width: 4
                              )
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                item.icon, 
                                color: isSelected 
                                    ? AppColors.brushedGold 
                                    : (isDark ? Colors.white30 : Colors.black26), 
                                size: 20
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  item.label, 
                                  style: TextStyle(
                                    color: isSelected 
                                        ? AppColors.brushedGold 
                                        : (isDark ? Colors.white : Colors.black87), 
                                    fontWeight: isSelected ? FontWeight.w900 : FontWeight.w500,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                              if (isSelected) 
                                const Icon(
                                  Icons.check_circle_rounded, 
                                  color: AppColors.brushedGold, 
                                  size: 18
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
