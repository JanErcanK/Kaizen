int _shoppingIdSequence = 0;

// Some platforms expose a coarse clock; timestamps alone can collide.
String newShoppingId(String prefix) =>
    '${prefix}_${DateTime.now().microsecondsSinceEpoch}_${_shoppingIdSequence++}';

class ShoppingItem {
  const ShoppingItem({
    required this.id,
    required this.text,
    this.checked = false,
  });

  final String id;
  final String text;
  final bool checked;

  ShoppingItem copyWith({String? text, bool? checked}) => ShoppingItem(
    id: id,
    text: text ?? this.text,
    checked: checked ?? this.checked,
  );

  Map<String, dynamic> toJson() => {'id': id, 'text': text, 'checked': checked};

  factory ShoppingItem.fromJson(Map json) => ShoppingItem(
    id: json['id'] as String,
    text: json['text'] as String? ?? '',
    checked: json['checked'] == true,
  );
}

class ShoppingList {
  const ShoppingList({
    required this.id,
    required this.name,
    required this.items,
    required this.updatedAt,
  });

  factory ShoppingList.empty() => ShoppingList(
    id: newShoppingId('shopping'),
    name: '',
    items: const [],
    updatedAt: DateTime.now(),
  );

  final String id;
  final String name;
  final List<ShoppingItem> items;
  final DateTime updatedAt;
  bool get isEmpty => items.every((item) => item.text.trim().isEmpty);

  ShoppingList copyWith({String? name, List<ShoppingItem>? items}) =>
      ShoppingList(
        id: id,
        name: name ?? this.name,
        items: items ?? this.items,
        updatedAt: DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'updatedAt': updatedAt.toIso8601String(),
    'items': items.map((item) => item.toJson()).toList(),
  };

  factory ShoppingList.fromJson(Map json) => ShoppingList(
    id: json['id'] as String,
    name: json['name'] as String? ?? '',
    updatedAt: DateTime.tryParse('${json['updatedAt']}') ?? DateTime(2000),
    items: (json['items'] as List? ?? const [])
        .whereType<Map>()
        .map(ShoppingItem.fromJson)
        .toList(),
  );
}
