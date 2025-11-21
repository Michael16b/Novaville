// dart
import 'package:flutter/material.dart';
import 'package:frontend/constants/colors.dart';

class CustomTextFormField extends StatefulWidget {
  CustomTextFormField({
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
  final Color fillColor = AppColors.white;
  final Color focusedFillColor = AppColors.white;
  final Color borderColor = AppColors.primary;
  final Color focusedBorderColor = AppColors.primary;
  final Color textColor = AppColors.primaryText;
  final Color focusedTextColor = AppColors.primaryText;
  final Color cursorColor = AppColors.primary;
  final Color selectionColor = AppColors.highlight;
  final Color errorColor = AppColors.error;

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
        ? widget.focusedTextColor
        : widget.textColor;
    final effectiveCursorColor = widget.cursorColor;
    final effectiveFillColor = _isFocused
        ? widget.focusedFillColor
        : widget.fillColor;
    final effectiveBorderColor = _isFocused
        ? widget.focusedBorderColor
        : widget.borderColor;

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
      borderSide: BorderSide(color: widget.errorColor),
    );
    final focusedError = OutlineInputBorder(
      borderRadius: BorderRadius.circular(4),
      borderSide: BorderSide(color: widget.errorColor, width: 2),
    );

    return Theme(
      data: Theme.of(context).copyWith(
        primaryColor: widget.cursorColor,
        colorScheme: Theme.of(context).colorScheme.copyWith(
          primary: widget.cursorColor,
          error: widget.cursorColor,
        ),
        textSelectionTheme: TextSelectionThemeData(
          selectionColor: widget.selectionColor,
          selectionHandleColor: widget.cursorColor,
          cursorColor: widget.cursorColor,
        ),
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
          errorStyle: TextStyle(color: widget.errorColor),
          labelStyle: TextStyle(color: widget.textColor),
          floatingLabelStyle: TextStyle(color: widget.focusedTextColor),
        ),
        validator: widget.validator,
      ),
    );
  }
}
