import 'package:flutter/material.dart';
import 'package:frontend/constants/colors.dart';

class CustomTextFormField extends StatefulWidget {
  const CustomTextFormField({
    required this.controller,
    super.key,
    this.labelText,
    this.keyboardType,
    this.obscureText = false,
    this.validator,
    this.isRequired = false,
  });

  final String? labelText;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final bool obscureText;
  final FormFieldValidator<String>? validator;
  final bool isRequired;

  @override
  State<CustomTextFormField> createState() => _CustomTextFormFieldState();
}

class _CustomTextFormFieldState extends State<CustomTextFormField> {
  late final FocusNode _focusNode;
  bool _isFocused = false;

  // Colors (defaults: white background, primary for others)
  static const Color fillColor = AppColors.white;
  static const Color focusedFillColor = AppColors.white;
  static const Color borderColor = AppColors.primary;
  static const Color focusedBorderColor = AppColors.primary;
  static const Color textColor = AppColors.primaryText;
  static const Color focusedTextColor = AppColors.primaryText;
  static const Color cursorColor = AppColors.primary;
  static const Color selectionColor = AppColors.highlight;
  static const Color errorColor = AppColors.error;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveTextColor = _isFocused
        ? focusedTextColor
        : textColor;
    const effectiveCursorColor = cursorColor;
    final effectiveFillColor = _isFocused
        ? focusedFillColor
        : fillColor;
    final effectiveBorderColor = _isFocused
        ? focusedBorderColor
        : borderColor;

    final enabled = OutlineInputBorder(
      borderRadius: BorderRadius.circular(4),
      borderSide: BorderSide(color: effectiveBorderColor),
    );
    final focused = OutlineInputBorder(
      borderRadius: BorderRadius.circular(4),
      borderSide: BorderSide(color: effectiveBorderColor, width: 2),
    );
    // Borders used when the field is in error state
    final error = OutlineInputBorder(
      borderRadius: BorderRadius.circular(4),
      borderSide: const BorderSide(color: errorColor),
    );
    final focusedError = OutlineInputBorder(
      borderRadius: BorderRadius.circular(4),
      borderSide: const BorderSide(
        color: errorColor,
        width: 2,
      ),
    );

    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: Theme.of(
          context,
        ).colorScheme.copyWith(error: errorColor),
      ),
      child: TextSelectionTheme(
        data: const TextSelectionThemeData(
          selectionColor: selectionColor,
          selectionHandleColor: cursorColor,
          cursorColor: cursorColor,
        ),
        child: TextFormField(
          focusNode: _focusNode,
          style: TextStyle(color: effectiveTextColor),
          cursorColor: effectiveCursorColor,
          controller: widget.controller,
          obscureText: widget.obscureText,
          keyboardType: widget.keyboardType,
          decoration: InputDecoration(
            label: widget.labelText != null
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(widget.labelText!),
                      if (widget.isRequired)
                        const Text(
                          ' *',
                          style: TextStyle(color: Colors.red),
                        ),
                    ],
                  )
                : null,
            filled: true,
            fillColor: effectiveFillColor,
            enabledBorder: enabled,
            focusedBorder: focused,
            // Use specific borders for the error state
            errorBorder: error,
            focusedErrorBorder: focusedError,
            errorStyle: const TextStyle(color: errorColor),
            labelStyle: const TextStyle(color: textColor),
            floatingLabelStyle: const TextStyle(
              color: focusedTextColor,
            ),
          ),
          validator: widget.validator,
        ),
      ),
    );
  }
}
