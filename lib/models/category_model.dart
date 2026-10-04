class CategoryModel {
  final String id;
  final String name;
  final String icon;
  final int color;
  final String type; // 'income', 'expense', 'both'
  final bool isDefault;
  final String? parentCategoryId;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.type,
    this.isDefault = false,
    this.parentCategoryId,
  });

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['id'] as String,
      name: map['name'] as String,
      icon: map['icon'] as String,
      color: map['color'] as int,
      type: map['type'] as String,
      isDefault: (map['is_default'] as int) == 1,
      parentCategoryId: map['parent_id'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'color': color,
      'type': type,
      'is_default': isDefault ? 1 : 0,
      'parent_id': parentCategoryId,
    };
  }

  CategoryModel copyWith({
    String? name,
    String? icon,
    int? color,
    String? type,
    bool? isDefault,
    String? parentCategoryId,
  }) {
    return CategoryModel(
      id: id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      type: type ?? this.type,
      isDefault: isDefault ?? this.isDefault,
      parentCategoryId: parentCategoryId ?? this.parentCategoryId,
    );
  }
}
