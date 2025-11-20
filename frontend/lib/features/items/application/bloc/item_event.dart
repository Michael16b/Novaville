part of 'item_bloc.dart';

abstract class ItemEvent extends Equatable {
  const ItemEvent();
}

class ItemRequested extends ItemEvent {
  const ItemRequested();

  @override
  List<Object?> get props => const [];
}

class ItemRefreshed extends ItemEvent {
  const ItemRefreshed();

  @override
  List<Object?> get props => const [];
}
