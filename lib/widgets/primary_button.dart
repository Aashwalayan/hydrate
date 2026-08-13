import 'package:flutter/material.dart';

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        child: isLoading
            ? const SizedBox(
                key: ValueKey('loader'),
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2.6),
              )
            : Text(label, key: const ValueKey('label')),
      ),
    );
  }
}
