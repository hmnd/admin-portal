import 'package:flutter/material.dart';
import 'package:invoiceninja_flutter/ui/app/forms/decorated_form_field.dart';

class GrowableFormField extends StatefulWidget {
  const GrowableFormField({
    Key key,
    this.initialValue,
    this.onChanged,
    this.keyboardType,
  });

  final String initialValue;
  final ValueChanged<String> onChanged;
  final TextInputType keyboardType;

  @override
  _GrowableFormFieldState createState() => _GrowableFormFieldState();
}

class _GrowableFormFieldState extends State<GrowableFormField> {
  final _focusNode = FocusNode();
  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFoucsChanged);
  }

  void _onFoucsChanged() {
    setState(() {
      _hasFocus = _focusNode.hasFocus;
    });
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFoucsChanged);
    _focusNode.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedFormField(
      key: widget.key,
      focusNode: _focusNode,
      initialValue: widget.initialValue,
      onChanged: widget.onChanged,
      keyboardType: widget.keyboardType,
      minLines: 1,
      maxLines: _hasFocus ? 20 : 1,
    );
  }
}
