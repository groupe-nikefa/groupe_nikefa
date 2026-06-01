import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/category.dart' as models;
import '../../../l10n/app_localizations.dart';
import '../providers/admin_providers.dart';

class AdminCategoriesScreen extends ConsumerStatefulWidget {
  const AdminCategoriesScreen({super.key});

  @override
  ConsumerState<AdminCategoriesScreen> createState() =>
      _AdminCategoriesScreenState();
}

class _AdminCategoriesScreenState extends ConsumerState<AdminCategoriesScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final categoriesAsync = ref.watch(adminCategoriesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Row(
            children: [
              Expanded(
                child: Text(l10n.manage_categories,
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800])),
              ),
              ElevatedButton.icon(
                onPressed: () => _showCategoryDialog(),
                icon: const Icon(Icons.add),
                label: Text(l10n.add_category),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.deepBlue,
                    foregroundColor: Colors.white),
              ),
            ],
          ),
        ),
        Expanded(
          child: categoriesAsync.when(
            data: (categories) {
              final cats = categories.whereType<models.Category>().toList();
              if (cats.isEmpty) {
                return Center(
                    child: Text(l10n.no_categories_found,
                        style: TextStyle(color: Colors.grey[600])));
              }
              final topLevel = cats.where((c) => c.parentId == null).toList();
              return RefreshIndicator(
                onRefresh: () async => ref.invalidate(adminCategoriesProvider),
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: topLevel.length,
                  itemBuilder: (context, index) => _CategoryTile(
                    category: topLevel[index],
                    allCategories: cats,
                    onEdit: () => _showCategoryDialog(topLevel[index]),
                    onDelete: (id) => _confirmAndDelete(context, ref, id),
                  ),
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('$e')),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmAndDelete(
      BuildContext context, WidgetRef ref, String categoryId) async {
    final l10n = AppLocalizations.of(context)!;
    final categoriesAsync = await ref.read(adminCategoriesProvider.future);
    final allCategories = categoriesAsync.whereType<models.Category>().toList();

    final otherCategories = allCategories
        .where((c) => c.id != categoryId && c.parentId == null)
        .toList();

    String? reassignToId;
    bool? confirmed;
    if (otherCategories.isNotEmpty) {
      final result = await showDialog<_DeleteConfirmResult>(
        context: context,
        builder: (ctx) {
          String? selectedId;
          return StatefulBuilder(
            builder: (ctx, setState) => AlertDialog(
              title: Text(l10n.delete),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(l10n.delete_category_confirmation),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String?>(
                    initialValue: null,
                    decoration:
                        InputDecoration(labelText: l10n.reassign_products_to),
                    items: [
                      DropdownMenuItem(
                        value: null,
                        child: Text(l10n.no_reassignment),
                      ),
                      ...otherCategories.map((c) => DropdownMenuItem(
                            value: c.id,
                            child: Text(c.nameFr),
                          )),
                    ],
                    onChanged: (v) => setState(() => selectedId = v),
                  ),
                ],
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(l10n.cancel)),
                ElevatedButton(
                  onPressed: () => Navigator.pop(
                      ctx,
                      _DeleteConfirmResult(
                          confirmed: true, reassignToId: selectedId)),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white),
                  child: Text(l10n.delete),
                ),
              ],
            ),
          );
        },
      );

      if (result == null || !result.confirmed) return;
      reassignToId = result.reassignToId;
    } else {
      confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.delete),
          content: Text(l10n.delete_category_confirmation),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(l10n.cancel)),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red, foregroundColor: Colors.white),
              child: Text(l10n.delete),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    final success =
        await ref.read(categoryFormProvider.notifier).deleteCategory(
              categoryId,
              reassignToId: reassignToId,
            );
    if (success) {
      if (context.mounted) {
        ref.invalidate(adminCategoriesProvider);
      }
    } else if (context.mounted) {
      final error = ref.read(categoryFormProvider).error?.toString() ??
          l10n.something_went_wrong;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.contains('cannot_delete_category_with_products')
              ? l10n.cannot_delete_category_with_products
              : l10n.something_went_wrong),
          backgroundColor: AppColors.red,
        ),
      );
    }
  }

  Future<void> _showCategoryDialog([models.Category? category]) async {
    final l10n = AppLocalizations.of(context)!;
    final nameFrCtrl = TextEditingController(text: category?.nameFr ?? '');
    final nameArCtrl = TextEditingController(text: category?.nameAr ?? '');
    final slugCtrl = TextEditingController(
        text: category?.slug ??
            (category?.nameFr.toLowerCase().replaceAll(' ', '-') ?? ''));
    String? parentId = category?.parentId;
    final isEditing = category != null;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final catsAsync = ref.watch(adminCategoriesProvider);
        return AlertDialog(
          title: Text(isEditing ? l10n.edit_category : l10n.add_category),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: nameFrCtrl,
                    decoration:
                        InputDecoration(labelText: '${l10n.category} (FR)')),
                const SizedBox(height: 12),
                TextField(
                    controller: nameArCtrl,
                    decoration:
                        InputDecoration(labelText: '${l10n.category} (AR)')),
                const SizedBox(height: 12),
                TextField(
                    controller: slugCtrl,
                    decoration: InputDecoration(labelText: 'Slug')),
                const SizedBox(height: 12),
                catsAsync.when(
                  data: (catList) {
                    final catItems =
                        catList.whereType<models.Category>().toList();
                    final parents = catItems
                        .where((models.Category c) =>
                            c.parentId == null && c.id != (category?.id ?? ''))
                        .toList();
                    return DropdownButtonFormField<String?>(
                      initialValue: parentId,
                      decoration:
                          InputDecoration(labelText: l10n.parent_category),
                      items: [
                        DropdownMenuItem(value: null, child: Text(l10n.none)),
                        ...parents.map((models.Category c) => DropdownMenuItem(
                            value: c.id, child: Text(c.nameFr))),
                      ],
                      onChanged: (v) => parentId = v,
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(l10n.cancel)),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.deepBlue,
                  foregroundColor: Colors.white),
              child: Text(isEditing ? l10n.save : l10n.add_category),
            ),
          ],
        );
      },
    );

    if (result == true) {
      final notifier = ref.read(categoryFormProvider.notifier);
      if (isEditing) {
        await notifier.updateCategory(category.id, {
          'name_fr': nameFrCtrl.text.trim(),
          'name_ar': nameArCtrl.text.trim(),
          'slug': slugCtrl.text.trim(),
          'parent_id': parentId,
        });
      } else {
        await notifier.createCategory(models.Category(
          id: '',
          nameFr: nameFrCtrl.text.trim(),
          nameAr: nameArCtrl.text.trim(),
          slug: slugCtrl.text.trim(),
          parentId: parentId,
        ));
      }
      ref.invalidate(adminCategoriesProvider);
    }
  }
}

class _DeleteConfirmResult {
  final bool confirmed;
  final String? reassignToId;
  const _DeleteConfirmResult({required this.confirmed, this.reassignToId});
}

class _CategoryTile extends ConsumerWidget {
  final models.Category category;
  final List<models.Category> allCategories;
  final VoidCallback? onEdit;
  final void Function(String categoryId)? onDelete;

  const _CategoryTile(
      {required this.category,
      required this.allCategories,
      this.onEdit,
      this.onDelete});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final children =
        allCategories.where((c) => c.parentId == category.id).toList();

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey[200]!)),
      child: Column(
        children: [
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: AppColors.deepBlue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8)),
              child: Icon(Icons.category, color: AppColors.deepBlue, size: 20),
            ),
            title: Text(category.nameFr,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text('${category.nameAr} • ${category.slug}',
                style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (children.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Chip(
                      label: Text('${children.length}',
                          style: const TextStyle(fontSize: 11)),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                IconButton(
                    icon: Icon(Icons.edit, color: Colors.grey[600], size: 20),
                    onPressed: onEdit),
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.red[400], size: 20),
                  onPressed:
                      onDelete != null ? () => onDelete!(category.id) : null,
                ),
              ],
            ),
          ),
          if (children.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 32, right: 16, bottom: 8),
              child: Column(
                children: children
                    .map((child) => ListTile(
                          dense: true,
                          leading: Icon(Icons.subdirectory_arrow_right,
                              color: Colors.grey[500], size: 20),
                          title: Text(child.nameFr,
                              style: const TextStyle(fontSize: 14)),
                          trailing: IconButton(
                            icon: Icon(Icons.delete,
                                color: Colors.red[300], size: 18),
                            onPressed: onDelete != null
                                ? () => onDelete!(child.id)
                                : null,
                          ),
                        ))
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }
}
