import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../models/category_model.dart';
import '../providers/finance_provider.dart';
import '../utils/app_theme.dart';
import '../utils/emoji_to_icon.dart';

class CategoryPickerSheet extends StatefulWidget {
  final String type;
  final List<CategoryModel> categories;

  const CategoryPickerSheet({
    super.key,
    required this.type,
    required this.categories,
  });

  @override
  State<CategoryPickerSheet> createState() => _CategoryPickerSheetState();
}

class _CategoryPickerSheetState extends State<CategoryPickerSheet> {
  String _query = '';
  late List<CategoryModel> _categories;

  @override
  void initState() {
    super.initState();
    _categories = [...widget.categories];
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FinanceProvider>();
    final query = _query.toLowerCase();
    final filtered = _categories.where((cat) {
      final name = provider.categoryDisplayName(cat).toLowerCase();
      return query.isEmpty || name.contains(query);
    }).toList();

    return FractionallySizedBox(
      heightFactor: .82,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Select Category',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: _showCreateCategoryDialog,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('New'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              onChanged: (value) => setState(() => _query = value),
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Search categories',
                prefixIcon: Icon(Icons.search_rounded, color: Colors.white38),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: GridView.count(
                crossAxisCount: 3,
                childAspectRatio: 1.02,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                children: filtered.map((cat) {
                  return GestureDetector(
                    onTap: () => Navigator.pop(context, cat),
                    child: PickerItem(
                      icon: cat.icon,
                      label: provider.categoryDisplayName(cat),
                      color: Color(cat.color),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showCreateCategoryDialog() async {
    final provider = context.read<FinanceProvider>();
    final nameCtrl = TextEditingController();
    var icon = widget.type == 'income' ? 'cash' : 'box';
    var color = widget.type == 'income' ? 0xFF4DDB6A : 0xFF654CFF;
    CategoryModel? parent;
    final parentOptions = provider.categories
        .where(
          (cat) =>
              cat.parentCategoryId == null &&
              (cat.type == widget.type || cat.type == 'both'),
        )
        .toList();

    final created = await showDialog<CategoryModel>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppTheme.cardColor,
              title: const Text('New Category'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      autofocus: true,
                      textCapitalization: TextCapitalization.words,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: 'Name'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<CategoryModel?>(
                      initialValue: parent,
                      dropdownColor: AppTheme.cardColor,
                      decoration: const InputDecoration(
                        labelText: 'Parent category',
                      ),
                      items: [
                        const DropdownMenuItem<CategoryModel?>(
                          value: null,
                          child: Text('None'),
                        ),
                        ...parentOptions.map(
                          (cat) => DropdownMenuItem<CategoryModel?>(
                            value: cat,
                            child: Text(provider.categoryDisplayName(cat)),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        setDialogState(() => parent = value);
                      },
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: AppConstants.categoryIcons.take(12).map((
                          iconName,
                        ) {
                          final isSelected = iconName == icon;
                          return InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: () {
                              setDialogState(() => icon = iconName);
                            },
                            child: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppTheme.primaryColor.withAlpha(64)
                                    : AppTheme.elevatedSurfaceColor,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSelected
                                      ? AppTheme.primaryColor
                                      : Colors.white10,
                                ),
                              ),
                              child: Icon(
                                EmojiToIcon.getIcon(iconName),
                                size: 18,
                                color: Colors.white70,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Wrap(
                        spacing: 8,
                        children: AppConstants.colorOptions.map((option) {
                          final isSelected = option == color;
                          return InkWell(
                            borderRadius: BorderRadius.circular(18),
                            onTap: () {
                              setDialogState(() => color = option);
                            },
                            child: Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: Color(option),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    final name = nameCtrl.text.trim();
                    if (name.isEmpty) return;
                    final category = CategoryModel(
                      id: const Uuid().v4(),
                      name: name,
                      icon: icon,
                      color: color,
                      type: widget.type,
                      parentCategoryId: parent?.id,
                    );
                    await provider.addCategory(category);
                    if (dialogContext.mounted) {
                      Navigator.pop(dialogContext, category);
                    }
                  },
                  child: const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );

    nameCtrl.dispose();
    if (created == null) return;
    setState(() => _categories.add(created));
    if (mounted) Navigator.pop(context, created);
  }
}

class ItemPickerSheet<T> extends StatelessWidget {
  final String title;
  final List<T> items;
  final Widget Function(T) builder;

  const ItemPickerSheet({
    super.key,
    required this.title,
    required this.items,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 12),
        Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Flexible(
          child: GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.1,
            children: items
                .map(
                  (item) => GestureDetector(
                    onTap: () => Navigator.pop(context, item),
                    child: builder(item),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}

class PickerItem extends StatelessWidget {
  final String icon;
  final String label;
  final Color color;

  const PickerItem({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color.withAlpha(31),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withAlpha(64)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(EmojiToIcon.getIcon(icon), color: color, size: 26),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 11),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
