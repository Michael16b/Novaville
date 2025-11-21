part of 'item_bloc.dart';

enum ItemStatus { initial, loading, success, failure }

class ItemState extends Equatable {
  const ItemState({required this.status, required this.items, this.error});

  const ItemState.initial()
    : status = ItemStatus.initial,
      items = const [],
      error = null;
  final ItemStatus status;
  final List<Item> items;
  final String? error;

  ItemState copyWith({ItemStatus? status, List<Item>? items, String? error}) {
    return ItemState(
      status: status ?? this.status,
      items: items ?? this.items,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [status, items, error];
}
