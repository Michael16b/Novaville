import 'dart:async';

import 'package:frontend/features/items/domain/item.dart';

abstract class IItemRepository {
  Future<List<Item>> fetchItems();
}

class FakeItemRepository implements IItemRepository {
  @override
  Future<List<Item>> fetchItems() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return const [
      Item(id: '1', title: 'Item 1'),
      Item(id: '2', title: 'Item 2'),
      Item(id: '3', title: 'Item 3'),
    ];
  }
}
