import 'package:flutter/material.dart';

class BlockButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;

  const BlockButton({
    super.key,
    required this.text,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        child: Text(text),
      ),
    );
  }
}