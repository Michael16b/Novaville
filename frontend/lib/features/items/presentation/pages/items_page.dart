import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend/constants/texts.dart';

import 'package:frontend/features/items/application/bloc/item_bloc.dart';

class ItemsPage extends StatefulWidget {
  const ItemsPage({super.key});

  @override
  State<ItemsPage> createState() => _ItemsPageState();
}

class _ItemsPageState extends State<ItemsPage> {
  @override
  void initState() {
    super.initState();
    context.read<ItemBloc>().add(const ItemRequested());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Items')),
      body: BlocBuilder<ItemBloc, ItemState>(
        builder: (context, state) {
          switch (state.status) {
            case ItemStatus.loading:
              return const Center(child: CircularProgressIndicator());
            case ItemStatus.failure:
              return Center(child: Text(state.error ?? AppTexts.errorOccurred));
            case ItemStatus.success:
              if (state.items.isEmpty) {
                return const Center();
              }
              return ListView.separated(
                itemCount: state.items.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final item = state.items[index];
                  return ListTile(
                    title: Text(item.title),
                    subtitle: Text('ID: ${item.id}'),
                  );
                },
              );
            case ItemStatus.initial:
              return const SizedBox.shrink();
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.read<ItemBloc>().add(const ItemRefreshed()),
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
