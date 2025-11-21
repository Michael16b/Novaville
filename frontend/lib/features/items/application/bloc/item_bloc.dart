import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:frontend/features/items/data/item_repository.dart';
import 'package:frontend/features/items/domain/item.dart';

part 'item_event.dart';
part 'item_state.dart';

class ItemBloc extends Bloc<ItemEvent, ItemState> {
  ItemBloc({required IItemRepository repository})
    : _repository = repository,
      super(const ItemState.initial()) {
    on<ItemRequested>(_onRequested);
    on<ItemRefreshed>(_onRefreshed);
  }

  final IItemRepository _repository;

  Future<void> _onRequested(
    ItemRequested event,
    Emitter<ItemState> emit,
  ) async {
    emit(state.copyWith(status: ItemStatus.loading));
    try {
      final items = await _repository.fetchItems();
      emit(state.copyWith(status: ItemStatus.success, items: items));
    } catch (e) {
      emit(state.copyWith(status: ItemStatus.failure, error: e.toString()));
    }
  }

  Future<void> _onRefreshed(
    ItemRefreshed event,
    Emitter<ItemState> emit,
  ) async {
    add(const ItemRequested());
  }
}
