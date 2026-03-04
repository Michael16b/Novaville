import 'package:flutter/material.dart';
import 'package:frontend/features/reports/data/models/neighborhood.dart';

/// Compact autocomplete widget for selecting a neighborhood with search.
///
/// Used in filter panels across multiple feature pages.
class NeighborhoodAutocomplete extends StatefulWidget {
  /// Creates a [NeighborhoodAutocomplete].
  const NeighborhoodAutocomplete({
    required this.neighborhoods,
    required this.selectedId,
    required this.onSelected,
    required this.hintText,
    super.key,
  });

  /// Available neighborhoods.
  final List<Neighborhood> neighborhoods;

  /// Currently selected neighborhood ID (null = all).
  final int? selectedId;

  /// Callback when a neighborhood is selected or cleared.
  final ValueChanged<int?> onSelected;

  /// Hint text shown when no neighborhood is selected.
  final String hintText;

  @override
  State<NeighborhoodAutocomplete> createState() =>
      _NeighborhoodAutocompleteState();
}

class _NeighborhoodAutocompleteState extends State<NeighborhoodAutocomplete> {
  late TextEditingController _internalController;

  @override
  void initState() {
    super.initState();
    _internalController = TextEditingController(
      text: _labelForId(widget.selectedId),
    );
  }

  @override
  void didUpdateWidget(covariant NeighborhoodAutocomplete oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedId != widget.selectedId) {
      _internalController.text = _labelForId(widget.selectedId);
    }
  }

  @override
  void dispose() {
    _internalController.dispose();
    super.dispose();
  }

  String _labelForId(int? id) {
    if (id == null) return '';
    return widget.neighborhoods
            .where((n) => n.id == id)
            .map((n) => n.name)
            .firstOrNull ??
        '';
  }

  @override
  Widget build(BuildContext context) {
    return Autocomplete<Neighborhood>(
      displayStringForOption: (n) => n.name,
      optionsBuilder: (textEditingValue) {
        final query = textEditingValue.text.toLowerCase().trim();
        if (query.isEmpty) {
          return widget.neighborhoods;
        }
        return widget.neighborhoods.where(
          (n) => n.name.toLowerCase().contains(query),
        );
      },
      onSelected: (neighborhood) {
        _internalController.text = neighborhood.name;
        widget.onSelected(neighborhood.id);
        // Close the dropdown by removing focus.
        Future.microtask(() {
          FocusScope.of(context).unfocus();
        });
      },
      fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
        // Only sync when the field is not focused to avoid overwriting user input.
        if (!focusNode.hasFocus && controller.text != _internalController.text) {
          controller.text = _internalController.text;
        }

        return SizedBox(
          height: 32,
          child: TextFormField(
            controller: controller,
            focusNode: focusNode,
            style: Theme.of(context).textTheme.bodySmall,
            decoration: InputDecoration(
              hintText: widget.hintText,
              hintStyle: Theme.of(context).textTheme.bodySmall,
              border: const OutlineInputBorder(),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              isDense: true,
              suffixIcon: widget.selectedId != null
                  ? IconButton(
                      icon: const Icon(Icons.close, size: 16),
                      onPressed: () {
                        controller.clear();
                        _internalController.clear();
                        widget.onSelected(null);
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      splashRadius: 14,
                      tooltip: widget.hintText,
                    )
                  : const Icon(Icons.arrow_drop_down, size: 18),
            ),
            onTap: () {
              controller.selection = TextSelection(
                baseOffset: 0,
                extentOffset: controller.text.length,
              );
            },
            onFieldSubmitted: (_) => onSubmitted(),
          ),
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxHeight: 220,
                maxWidth: 250,
              ),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final neighborhood = options.elementAt(index);
                  final isSelected = neighborhood.id == widget.selectedId;
                  return ListTile(
                    dense: true,
                    title: Text(neighborhood.name),
                    selected: isSelected,
                    onTap: () => onSelected(neighborhood),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
