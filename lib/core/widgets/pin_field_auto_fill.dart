import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pin_input_text_field/pin_input_text_field.dart';

export 'package:pin_input_text_field/pin_input_text_field.dart';

class SmsAutoFill {
  late SmsAutoFill? _singleton;
  static const MethodChannel _channel = MethodChannel('sms_autofill');
  final StreamController<String> _code = StreamController.broadcast();

  SmsAutoFill._() {
    _channel.setMethodCallHandler((method) {
      if (method.method == 'smscode') {
        _code.add(method.arguments);
      }
      return Future.value();
    });
  }

  SmsAutoFill getInstance() {
    _singleton ??= SmsAutoFill._();
    return _singleton!;
  }

  Stream<String> get code => _code.stream;

  Future<String> get hint async {
    final String version = await _channel.invokeMethod('requestPhoneHint');
    return version;
  }

  Future<void> get listenForCode async {
    await _channel.invokeMethod('listenForCode');
  }

  Future<void> unregisterListener() async {
    await _channel.invokeMethod('unregisterListener');
  }

  Future<String> get getAppSignature async {
    final String appSignature = await _channel.invokeMethod('getAppSignature');
    return appSignature;
  }
}

class PinFieldAutoFill extends StatefulWidget {
  final int codeLength;
  final bool autofocus;
  final TextEditingController? controller;
  final String currentCode;
  final Function(String) onCodeSubmitted;
  final Function(String) onCodeChanged;
  final PinDecoration decoration;
  final FocusNode focusNode;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;

  const PinFieldAutoFill({
    Key? key,
    this.keyboardType = const TextInputType.numberWithOptions(),
    this.textInputAction = TextInputAction.done,
    required this.focusNode,
    this.controller,
    this.decoration = const UnderlineDecoration(
        colorBuilder: FixedColorBuilder(Colors.black),
        textStyle: TextStyle(color: Colors.black)),
    required this.onCodeSubmitted,
    required this.onCodeChanged,
    required this.currentCode,
    this.autofocus = false,
    this.codeLength = 6,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _PinFieldAutoFillState();
  }
}

class _PinFieldAutoFillState extends State<PinFieldAutoFill> with CodeAutoFill {
  late TextEditingController controller;
  late bool _shouldDisposeController;

  @override
  Widget build(BuildContext context) {
    return PinInputTextField(
      pinLength: widget.codeLength,
      decoration: widget.decoration,
      focusNode: widget.focusNode,
      enableInteractiveSelection: true,
      autocorrect: false,
      autofillHints: const <String>[AutofillHints.oneTimeCode],
      textCapitalization: TextCapitalization.none,
      toolbarOptions: const ToolbarOptions(paste: true),
      keyboardType: widget.keyboardType,
      autoFocus: widget.autofocus,
      controller: controller,
      textInputAction: widget.textInputAction,
      onSubmit: widget.onCodeSubmitted,
    );
  }

  @override
  void initState() {
    _shouldDisposeController = widget.controller == null;
    controller = widget.controller ?? TextEditingController(text: '');
    code = widget.currentCode;
    codeUpdated();
    controller.addListener(() {
      if (controller.text != code) {
        code = controller.text;
        if (code != null) {
          widget.onCodeChanged(code!);
        }
      }
    });
    listenForCode();
    super.initState();
  }

  @override
  void didUpdateWidget(PinFieldAutoFill oldWidget) {
    if (widget.controller != null && widget.controller != controller) {
      controller.dispose();
      controller = widget.controller!;
    }

    if (widget.currentCode != oldWidget.currentCode ||
        widget.currentCode != code) {
      code = widget.currentCode;
      codeUpdated();
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void codeUpdated() {
    if (controller.text != code && code != null) {
      controller.value = TextEditingValue(text: code!);
      widget.onCodeChanged(code!);
    }
  }

  @override
  void dispose() {
    cancel();
    if (_shouldDisposeController) {
      controller.dispose();
    }
    unregisterListener();
    super.dispose();
  }
}

class PhoneFormFieldHint extends StatelessWidget {
  final bool autofocus;
  final FocusNode focusNode;
  final TextEditingController controller;
  final List<TextInputFormatter> inputFormatters;
  final FormFieldValidator validator;
  final InputDecoration decoration;
  final TextField child;

  const PhoneFormFieldHint({
    required Key key,
    required this.child,
    required this.controller,
    required this.inputFormatters,
    required this.validator,
    required this.decoration,
    this.autofocus = false,
    required this.focusNode,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return _PhoneFieldHint(
        key: key,
        child: child,
        inputFormatters: inputFormatters,
        controller: controller,
        validator: validator,
        decoration: decoration,
        autofocus: autofocus,
        focusNode: focusNode,
        isFormWidget: true);
  }
}

class PhoneFieldHint extends StatelessWidget {
  final bool autofocus;
  final FocusNode focusNode;
  final TextEditingController controller;
  final List<TextInputFormatter> inputFormatters;
  final InputDecoration decoration;
  final TextField child;

  const PhoneFieldHint({
    required Key key,
    required this.child,
    required this.controller,
    required this.inputFormatters,
    required this.decoration,
    this.autofocus = false,
    required this.focusNode,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return _PhoneFieldHint(
      key: key,
      child: child,
      inputFormatters: inputFormatters,
      decoration: decoration,
      autofocus: autofocus,
      focusNode: focusNode,
      isFormWidget: false,
      validator: (value) {},
    );
  }
}

class _PhoneFieldHint extends StatefulWidget {
  final bool autofocus;
  final FocusNode? focusNode;
  final TextEditingController? controller;
  final List<TextInputFormatter>? inputFormatters;
  final FormFieldValidator validator;
  final bool isFormWidget;
  final InputDecoration? decoration;
  final TextField? child;

  const _PhoneFieldHint({
    Key? key,
    this.child,
    this.controller,
    this.inputFormatters,
    required this.validator,
    this.isFormWidget = false,
    this.decoration,
    this.autofocus = false,
    this.focusNode,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _PhoneFieldHintState();
  }
}

class _PhoneFieldHintState extends State<_PhoneFieldHint> {
  final SmsAutoFill _autoFill = SmsAutoFill._();
  late TextEditingController _controller;
  late List<TextInputFormatter> _inputFormatters;
  late FocusNode _focusNode;
  bool _hintShown = false;
  bool _isUsingInternalController = false;
  bool _isUsingInternalFocusNode = false;

  @override
  void initState() {
    _controller = widget.controller ??
        widget.child?.controller ??
        _createInternalController();
    _inputFormatters =
        widget.inputFormatters ?? widget.child?.inputFormatters ?? [];
    _focusNode = widget.focusNode ??
        widget.child?.focusNode ??
        _createInternalFocusNode();
    _focusNode.addListener(() async {
      if (_focusNode.hasFocus && !_hintShown) {
        _hintShown = true;
        // ignore: unnecessary_lambdas
        scheduleMicrotask(() {
          _askPhoneHint();
        });
      }
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final decoration = widget.decoration ??
        InputDecoration(
          suffixIcon: Platform.isAndroid
              ? IconButton(
                  icon: const Icon(Icons.phonelink_setup),
                  onPressed: () async {
                    _hintShown = true;
                    await _askPhoneHint();
                  },
                )
              : null,
        );

    return widget.child ??
        _createField(widget.isFormWidget, decoration, widget.validator);
  }

  @override
  void dispose() {
    if (_isUsingInternalController) {
      _controller.dispose();
    }

    if (_isUsingInternalFocusNode) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  Widget _createField(bool isFormWidget, InputDecoration decoration,
      FormFieldValidator validator) {
    return isFormWidget
        ? _createTextFormField(decoration, validator)
        : _createTextField(decoration);
  }

  Widget _createTextField(InputDecoration decoration) {
    return TextField(
      autofocus: widget.autofocus,
      focusNode: _focusNode,
      autofillHints: const [AutofillHints.telephoneNumber],
      inputFormatters: _inputFormatters,
      decoration: decoration,
      controller: _controller,
      keyboardType: TextInputType.phone,
    );
  }

  Widget _createTextFormField(
      InputDecoration decoration, FormFieldValidator validator) {
    return TextFormField(
      validator: validator,
      autofocus: widget.autofocus,
      focusNode: _focusNode,
      autofillHints: const [AutofillHints.telephoneNumber],
      inputFormatters: _inputFormatters,
      decoration: decoration,
      controller: _controller,
      keyboardType: TextInputType.phone,
    );
  }

  Future<void> _askPhoneHint() async {
    String hint = await _autoFill.hint;
    _controller.value = TextEditingValue(text: hint);
  }

  TextEditingController _createInternalController() {
    _isUsingInternalController = true;
    return TextEditingController(text: '');
  }

  FocusNode _createInternalFocusNode() {
    _isUsingInternalFocusNode = true;
    return FocusNode();
  }
}

class TextFieldPinAutoFill extends StatefulWidget {
  final int codeLength;
  final bool autofocus;
  final FocusNode? focusNode;
  final String? currentCode;
  final Function(String) onCodeSubmitted;
  final Function(String) onCodeChanged;
  final InputDecoration decoration;
  final bool obscureText;
  final TextStyle? style;
  final TextEditingController textController;
  const TextFieldPinAutoFill({
    Key? key,
    this.focusNode,
    this.obscureText = false,
    required this.onCodeSubmitted,
    this.style,
    required this.onCodeChanged,
    this.decoration = const InputDecoration(),
    this.currentCode,
    this.autofocus = false,
    this.codeLength = 6,
    required this.textController,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _TextFieldPinAutoFillState();
  }
}

mixin CodeAutoFill {
  final SmsAutoFill _autoFill = SmsAutoFill._();
  String? code;
  StreamSubscription? _subscription;

  void listenForCode() {
    _subscription = _autoFill.code.listen((code) {
      this.code = code;
      codeUpdated();
    });
    _autoFill.listenForCode;
  }

  Future<void>? cancel() {
    return _subscription?.cancel();
  }

  Future<void> unregisterListener() {
    return _autoFill.unregisterListener();
  }

  void codeUpdated();
}

class _TextFieldPinAutoFillState extends State<TextFieldPinAutoFill>
    with CodeAutoFill {
  @override
  Widget build(BuildContext context) {
    return TextField(
      autofocus: widget.autofocus,
      focusNode: widget.focusNode,
      maxLength: widget.codeLength,
      decoration: widget.decoration,
      style: widget.style,
      autofillHints: const <String>[AutofillHints.oneTimeCode],
      onSubmitted: widget.onCodeSubmitted,
      onChanged: widget.onCodeChanged,
      keyboardType: const TextInputType.numberWithOptions(),
      controller: widget.textController,
      obscureText: widget.obscureText,
    );
  }

  @override
  void initState() {
    code = widget.currentCode;
    codeUpdated();
    listenForCode();
    super.initState();
  }

  @override
  void codeUpdated() {
    if (widget.textController.text != code) {
      widget.textController.value = TextEditingValue(text: code ?? '');
      widget.onCodeChanged(code ?? '');
    }
  }

  @override
  void didUpdateWidget(TextFieldPinAutoFill oldWidget) {
    if (widget.currentCode != oldWidget.currentCode ||
        widget.currentCode != _getCode()) {
      code = widget.currentCode;
      codeUpdated();
    }
    super.didUpdateWidget(oldWidget);
  }

  String _getCode() {
    return widget.textController.value.text;
  }

  @override
  void dispose() {
    cancel();
    widget.textController.dispose();
    unregisterListener();
    super.dispose();
  }
}
