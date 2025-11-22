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
  });

  final String? labelText;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final bool obscureText;
  final FormFieldValidator<String>? validator;

  // Couleurs (valeurs par défaut : fond blanc, autres primary)
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
  State<CustomTextFormField> createState() => _CustomTextFormFieldState();
}

class _CustomTextFormFieldState extends State<CustomTextFormField> {
  late final FocusNode _focusNode;
  bool _isFocused = false;

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
        ? CustomTextFormField.focusedTextColor
        : CustomTextFormField.textColor;
    const effectiveCursorColor = CustomTextFormField.cursorColor;
    final effectiveFillColor = _isFocused
        ? CustomTextFormField.focusedFillColor
        : CustomTextFormField.fillColor;
    final effectiveBorderColor = _isFocused
        ? CustomTextFormField.focusedBorderColor
        : CustomTextFormField.borderColor;

    final enabled = OutlineInputBorder(
      borderRadius: BorderRadius.circular(4),
      borderSide: BorderSide(color: effectiveBorderColor),
    );
    final focused = OutlineInputBorder(
      borderRadius: BorderRadius.circular(4),
      borderSide: BorderSide(color: effectiveBorderColor, width: 2),
    );
    // Bordures à utiliser lorsque le champ est en état d'erreur
    final error = OutlineInputBorder(
      borderRadius: BorderRadius.circular(4),
      borderSide: const BorderSide(color: CustomTextFormField.errorColor),
    );
    final focusedError = OutlineInputBorder(
      borderRadius: BorderRadius.circular(4),
      borderSide: const BorderSide(
        color: CustomTextFormField.errorColor,
        width: 2,
      ),
    );

    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: Theme.of(context)
            .colorScheme
            .copyWith(error: CustomTextFormField.errorColor),
      ),
      child: TextSelectionTheme(
        data: const TextSelectionThemeData(
          selectionColor: CustomTextFormField.selectionColor,
          selectionHandleColor: CustomTextFormField.cursorColor,
          cursorColor: CustomTextFormField.cursorColor,
        ),
        child: TextFormField(
          focusNode: _focusNode,
          style: TextStyle(color: effectiveTextColor),
          cursorColor: effectiveCursorColor,
          controller: widget.controller,
          obscureText: widget.obscureText,
          keyboardType: widget.keyboardType,
          decoration: InputDecoration(
            labelText: widget.labelText,
            filled: true,
            fillColor: effectiveFillColor,
            enabledBorder: enabled,
            focusedBorder: focused,
            // Utiliser des bordures spécifiques pour l'état d'erreur
            errorBorder: error,
            focusedErrorBorder: focusedError,
            // Garder l'apparence du texte d'erreur similaire (ou ajuster si besoin)
            errorStyle: const TextStyle(color: CustomTextFormField.errorColor),
            labelStyle: const TextStyle(color: CustomTextFormField.textColor),
            floatingLabelStyle: const TextStyle(
              color: CustomTextFormField.focusedTextColor,
            ),
          ),
          validator: widget.validator,
        ),
      ),
    );
  }
}
