import 'package:flutter/material.dart';
import 'package:yugioh_scanner/core/theme/app_theme.dart';
import 'package:yugioh_scanner/view_models/card_filters_view_model.dart'; // Asegúrate que la ruta es correcta
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';

class FiltersDialog extends StatelessWidget {
  final CardFiltersViewModel viewModel;

  const FiltersDialog({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.lg),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 800,
          maxHeight: 580,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: ChangeNotifierProvider.value(
            value: viewModel,
            child: Consumer<CardFiltersViewModel>(
              builder: (context, vm, _) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- CABECERA ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Filtros',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          splashRadius: 20,
                          icon: const Icon(Icons.close, color: AppColors.textSecondary),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildCategorySection(
                              context,
                              icon: LucideIcons.square,
                              iconColor: Colors.orangeAccent,
                              title: 'Marco de carta',
                              items: const ['Monster', 'Spell', 'Trap'],
                              keyName: 'cardTypes',
                              selected: vm.filters.cardTypes,
                              gridCount: 3,
                              childAspectRatioOverride: 4.5,
                            ),
                            const SizedBox(height: AppSpacing.lg),

                            _buildCategorySection(
                              context,
                              icon: LucideIcons.circle,
                              iconColor: Colors.yellowAccent,
                              title: 'Atributo',
                              items: const [
                                'LIGHT', 'DARK', 'WATER', 'FIRE',
                                'EARTH', 'WIND', 'DIVINE'
                              ],
                              keyName: 'attributes',
                              selected: vm.filters.attributes,
                              gridCount: 4,
                            ),
                            const SizedBox(height: AppSpacing.lg),

                            _buildCategorySection(
                              context,
                              icon: LucideIcons.zap,
                              iconColor: Colors.purpleAccent,
                              title: 'Tipos de Mágicas y Trampas',
                              items: const [
                                'Normal', 'Field', 'Equip', 'Continuous',
                                'Quick-Play', 'Ritual', 'Counter',
                              ],
                              keyName: 'spellTrapIcons',
                              selected: vm.filters.spellTrapIcons,
                              gridCount: 4,
                            ),
                            const SizedBox(height: AppSpacing.lg),

                            _buildCategorySection(
                              context,
                              icon: LucideIcons.star,
                              iconColor: Colors.greenAccent,
                              title: 'Tipo de Monstruo',
                              items: const [
                                'Aqua', 'Beast', 'Beast-Warrior', 'Winged Beast',
                                'Fiend', 'Dinosaur', 'Dragon', 'Warrior',
                                'Spellcaster', 'Machine', 'Zombie', 'Fairy',
                                'Pyro', 'Insect', 'Rock', 'Reptile',
                                'Thunder', 'Wyrm', 'Psychic', 'Cyberse',
                                'Divine-Beast', 'Sea Serpent', 'Fish', 'Creator God',
                              ],
                              keyName: 'monsterTypes',
                              selected: vm.filters.monsterTypes,
                              gridCount: 4,
                            ),
                            const SizedBox(height: AppSpacing.lg),

                            _buildCategorySection(
                              context,
                              icon: LucideIcons.layoutGrid,
                              iconColor: Colors.cyanAccent,
                              title: 'Subtipos',
                              items: const [
                                'Normal', 'Effect', 'Fusion', 'Ritual',
                                'Synchro', 'Xyz', 'Pendulum', 'Link',
                                'Tuner', 'Flip', 'Gemini', 'Spirit',
                                'Toon', 'Union', 'Token',
                              ],
                              keyName: 'subtypes',
                              selected: vm.filters.subtypes,
                              gridCount: 4,
                            ),
                            const SizedBox(height: AppSpacing.lg),

                            // --- Campos de ATK/DEF ---
                            Row(
                              children: [
                                Expanded(
                                  child: _buildNumberField(
                                    context: context,
                                    label: 'ATK Mínimo',
                                    value: vm.filters.minAtk ?? '',
                                    onChanged: (v) => vm.updateFilter('minAtk', v),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: _buildNumberField(
                                    context: context,
                                    label: 'DEF Mínimo',
                                    value: vm.filters.minDef ?? '',
                                    onChanged: (v) => vm.updateFilter('minDef', v),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.md),
                          ],
                        ),
                      ),
                    ),

                    const Divider(height: AppSpacing.lg, color: AppColors.border),

                    // --- BOTONES FINALES ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        OutlinedButton.icon(
                          icon: const Icon(Icons.close, size: 18),
                          label: const Text('Limpiar Filtros'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textPrimary,
                            side: const BorderSide(color: AppColors.border),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppSpacing.lg),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                          ),
                          onPressed: vm.clearAll,
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: theme.elevatedButtonTheme.style?.copyWith(
                            shape: WidgetStateProperty.all(
                               RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppSpacing.lg),
                              ),
                            ),
                             padding: WidgetStateProperty.all(
                              const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                            ),
                          ),
                          child: const Text('Aplicar Filtros'),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  // --- COMPONENTES INTERNOS ---

  Widget _buildCategorySection(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required List<String> items,
    required String keyName,
    required List<String> selected,
    int gridCount = 4,
    double? childAspectRatioOverride,
  }) {
    final vm = Provider.of<CardFiltersViewModel>(context, listen: false);
    final theme = Theme.of(context);

    const double buttonBorderRadius = 8.0;
    const Color selectedBackgroundColor = Color(0xFF1E63E9);
    const Color unselectedBackgroundColor = AppColors.surface;
    const Color selectedTextColor = AppColors.textPrimary;
    const Color unselectedTextColor = AppColors.textSecondary;
    const Color unselectedBorderColor = AppColors.border;

    final double effectiveChildAspectRatio = childAspectRatioOverride ?? 3.5;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: iconColor, size: 18),
            const SizedBox(width: AppSpacing.sm),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: AppTextSizes.md,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        GridView.builder(
          itemCount: items.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: gridCount,
            mainAxisSpacing: AppSpacing.sm,
            crossAxisSpacing: AppSpacing.sm,
            childAspectRatio: effectiveChildAspectRatio,
          ),
          itemBuilder: (context, index) {
            final item = items[index];
            final isSelected = selected.contains(item);

            return GestureDetector(
              // --- ⬇️ ESTA ES LA LÍNEA CORREGIDA ⬇️ ---
              onTap: () => vm.toggleArrayFilter(keyName, item),
              // --- ⬆️ FIN DE LA CORRECCIÓN ⬆️ ---
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                decoration: BoxDecoration(
                  color: isSelected ? selectedBackgroundColor : unselectedBackgroundColor,
                  border: Border.all(
                    color: isSelected ? selectedBackgroundColor : unselectedBorderColor,
                    width: 1.0,
                  ),
                  borderRadius: BorderRadius.circular(buttonBorderRadius),
                ),
                alignment: Alignment.center,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                  child: Text(
                    item,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isSelected ? selectedTextColor : unselectedTextColor,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      fontSize: AppTextSizes.sm,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildNumberField({
    required String label,
    required String value,
    required Function(String) onChanged,
    required BuildContext context,
  }) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        TextField(
          keyboardType: TextInputType.number,
          controller: TextEditingController(text: value)..selection = TextSelection.collapsed(offset: value.length),
          onChanged: onChanged,
          decoration: InputDecoration(
            filled: theme.inputDecorationTheme.filled,
            fillColor: theme.inputDecorationTheme.fillColor,
            hintStyle: theme.inputDecorationTheme.hintStyle,
            enabledBorder: theme.inputDecorationTheme.enabledBorder ??
              const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
                borderSide: BorderSide(color: AppColors.border),
              ),
            focusedBorder: theme.inputDecorationTheme.focusedBorder ??
              const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
                borderSide: BorderSide(color: AppColors.primary, width: 2),
             ),
            border: theme.inputDecorationTheme.border,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
          ),
          style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textPrimary),
        ),
      ],
    );
  }
}