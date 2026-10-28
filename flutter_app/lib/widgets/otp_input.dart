import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme.dart';

/// 4 kotak OTP (64x66, jarak 24) sesuai Figma.
class OtpInput extends StatefulWidget {
  final ValueChanged<String> onChanged;
  const OtpInput({super.key, required this.onChanged});

  @override
  State<OtpInput> createState() => _OtpInputState();
}

class _OtpInputState extends State<OtpInput> {
  final _ctrls = List.generate(4, (_) => TextEditingController());
  final _nodes = List.generate(4, (_) => FocusNode());

  @override
  void dispose() {
    for (final c in _ctrls) {
      c.dispose();
    }
    for (final n in _nodes) {
      n.dispose();
    }
    super.dispose();
  }

  void _notify() => widget.onChanged(_ctrls.map((c) => c.text).join());

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(4, (i) {
        return Padding(
          padding: EdgeInsets.only(right: i == 3 ? 0 : 24),
          child: Container(
            width: 64,
            height: 66,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.primary),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Focus(
              onKeyEvent: (node, event) {
                if (event is KeyDownEvent &&
                    event.logicalKey == LogicalKeyboardKey.backspace &&
                    _ctrls[i].text.isEmpty &&
                    i > 0) {
                  _ctrls[i - 1].clear();
                  _nodes[i - 1].requestFocus();
                  _notify();
                }
                return KeyEventResult.ignored;
              },
              child: TextField(
                controller: _ctrls[i],
                focusNode: _nodes[i],
                autofocus: i == 0,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(1)],
                style: inter(20, weight: FontWeight.w700),
                cursorColor: AppColors.primary,
                decoration: const InputDecoration(border: InputBorder.none, counterText: ''),
                onChanged: (v) {
                  if (v.isNotEmpty && i < 3) _nodes[i + 1].requestFocus();
                  if (v.isNotEmpty && i == 3) _nodes[i].unfocus();
                  _notify();
                },
              ),
            ),
          ),
        );
      }),
    );
  }
}
