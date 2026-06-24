import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class FormStatefulInput extends StatefulWidget {
  final String initialValue;
  final ValueChanged<String> onChanged;
  final int maxLines;
  final String? placeholder;

  const FormStatefulInput({
    super.key,
    required this.initialValue,
    required this.onChanged,
    this.maxLines = 1,
    this.placeholder,
  });

  @override
  State<FormStatefulInput> createState() => _FormStatefulInputState();
}

class _FormStatefulInputState extends State<FormStatefulInput> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void didUpdateWidget(FormStatefulInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != oldWidget.initialValue && widget.initialValue != _controller.text) {
      _controller.text = widget.initialValue;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ShadInput(
      controller: _controller,
      maxLines: widget.maxLines,
      placeholder: widget.placeholder != null ? Text(widget.placeholder!) : null,
      onChanged: widget.onChanged,
    );
  }
}
