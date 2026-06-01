// Category model — represents a product category with multilingual support.
//
// Maps to the `categories` table in Supabase. Categories can be nested
// (parent/child) via the `parentId` field. Includes Hive adapter for
// offline caching.

/// Represents a product category with bilingual names and descriptions.
///
/// Categories support hierarchical nesting via [parentId].
/// Null [parentId] indicates a top-level category.
class Category {
  /// Unique identifier from Supabase.
  final String id;

  /// Category name in French.
  final String nameFr;

  /// Category name in Arabic.
  final String nameAr;

  /// Category description in French.
  final String? descriptionFr;

  /// Category description in Arabic.
  final String? descriptionAr;

  /// URL to the category icon in Supabase Storage.
  final String? iconUrl;

  /// URL-friendly slug for the category.
  final String slug;

  /// ID of the parent category (null for top-level categories).
  final String? parentId;

  /// Timestamp when the category was created.
  final DateTime? createdAt;

  /// Creates a new [Category] instance.
  const Category({
    required this.id,
    required this.nameFr,
    required this.nameAr,
    this.descriptionFr,
    this.descriptionAr,
    this.iconUrl,
    this.slug = '',
    this.parentId,
    this.createdAt,
  });

  /// Creates a [Category] from a Supabase JSON response.
  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String,
      nameFr: json['name_fr'] as String? ?? '',
      nameAr: json['name_ar'] as String? ?? '',
      descriptionFr: json['description_fr'] as String?,
      descriptionAr: json['description_ar'] as String?,
      iconUrl: json['icon_url'] as String?,
      slug: json['slug'] as String? ?? '',
      parentId: json['parent_id'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  /// Converts this category to a JSON map for Supabase operations.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name_fr': nameFr,
      'name_ar': nameAr,
      'description_fr': descriptionFr,
      'description_ar': descriptionAr,
      'icon_url': iconUrl,
      'slug': slug,
      'parent_id': parentId,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  /// Returns a copy of this category with modified fields.
  Category copyWith({
    String? id,
    String? nameFr,
    String? nameAr,
    String? descriptionFr,
    String? descriptionAr,
    String? iconUrl,
    String? slug,
    String? parentId,
    DateTime? createdAt,
  }) {
    return Category(
      id: id ?? this.id,
      nameFr: nameFr ?? this.nameFr,
      nameAr: nameAr ?? this.nameAr,
      descriptionFr: descriptionFr ?? this.descriptionFr,
      descriptionAr: descriptionAr ?? this.descriptionAr,
      iconUrl: iconUrl ?? this.iconUrl,
      slug: slug ?? this.slug,
      parentId: parentId ?? this.parentId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Returns the localized name based on the provided locale code.
  ///
  /// Falls back to French if the Arabic name is empty.
  String getLocalizedName(String localeCode) {
    if (localeCode == 'ar' && nameAr.isNotEmpty) return nameAr;
    return nameFr;
  }

  /// Returns the localized description based on the provided locale code.
  ///
  /// Falls back to French if the Arabic description is null/empty.
  String? getLocalizedDescription(String localeCode) {
    if (localeCode == 'ar')
      return descriptionAr?.isNotEmpty == true ? descriptionAr : descriptionFr;
    return descriptionFr;
  }

  /// Returns `true` if this is a top-level category (no parent).
  bool get isTopLevel => parentId == null;

  @override
  String toString() => 'Category(id: $id, nameFr: $nameFr, nameAr: $nameAr)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Category && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
