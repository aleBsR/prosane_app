import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.errorText,
    this.helperText,
    this.isPassword = false,
    this.isValid = false,
    this.keyboardType,
    this.onChanged,
    this.readOnly = false,
  });

  final String label;
  final String? hint;
  final TextEditingController? controller;
  final String? errorText;
  final String? helperText;
  final bool isPassword;
  final bool isValid;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final bool readOnly;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _obscure = widget.isPassword;

  @override
  Widget build(BuildContext context) {
    final hasError = widget.errorText != null;
    final borderColor = hasError
        ? AppColors.error
        : (widget.isValid ? AppColors.primario : Colors.transparent);

    Widget? suffix;
    if (widget.isPassword) {
      suffix = IconButton(
        icon: Icon(
          _obscure ? Icons.visibility_off : Icons.visibility,
          color: AppColors.link,
        ),
        onPressed: () => setState(() => _obscure = !_obscure),
      );
    } else if (hasError) {
      suffix =  Icon(Icons.cancel, color: AppColors.error);
    } else if (widget.isValid) {
      suffix =  Icon(Icons.check_circle, color: AppColors.primario);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: AppTypography.subtitulo),
        const SizedBox(height: 6),
        TextField(
          controller: widget.controller,
          obscureText: _obscure,
          keyboardType: widget.keyboardType,
          onChanged: widget.onChanged,
          readOnly: widget.readOnly,
          style: AppTypography.campo,
          decoration: InputDecoration(
            hintText: widget.hint,
            filled: true,
            fillColor: AppColors.campo,
            suffixIcon: suffix,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 14),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadii.campo),
              borderSide: BorderSide(color: borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadii.campo),
              borderSide:
                   BorderSide(color: AppColors.primario, width: 1.5),
            ),
          ),
        ),
        if (hasError || widget.helperText != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Text(
              widget.errorText ?? widget.helperText ?? '',
              style: AppTypography.texto.copyWith(
                color: hasError ? AppColors.error : AppColors.texto,
              ),
            ),
          ),
      ],
    );
  }
}
