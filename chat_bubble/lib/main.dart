import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/src/semantics/semantics.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.text = "Hola, caracola";
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
            child: SizedBox(
          width: 220,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  color: Colors.blue[100]!,
                  padding: const EdgeInsets.all(15),
                  child: ListenableBuilder(
                    listenable: _controller,
                    builder: (_, __) => TimestampdChatMessage(
                      text: _controller.text,
                      sentAt: '2 minutes ago',
                      style: const TextStyle(
                        color: Colors.red,
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 15),
                child: TextField(
                  controller: _controller,
                ),
              )
            ],
          ),
        )),
      ),
    );
  }
}

class TimestampdChatMessage extends LeafRenderObjectWidget {
  const TimestampdChatMessage({
    super.key,
    required this.text,
    required this.sentAt,
    required this.style,
  });

  final String text;
  final String sentAt;
  final TextStyle style;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return TimestampChatMessageRenderObject(
      text: text,
      sentAt: sentAt,
      textStyle: style,
      textDirection: Directionality.of(context),
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    covariant TimestampChatMessageRenderObject renderObject,
  ) {
    renderObject.text = text;
    renderObject.sentAt = sentAt;
    renderObject.textStyle = style;
    renderObject.textDirection = Directionality.of(context);
  }
}

class TimestampChatMessageRenderObject extends RenderBox {
  TimestampChatMessageRenderObject({
    required String sentAt,
    required String text,
    required TextStyle textStyle,
    required TextDirection textDirection,
  })  : _sentAt = sentAt,
        _text = text,
        _textStyle = textStyle,
        _textDirection = textDirection {
    _textPainter = TextPainter(
      text: _textTextSpan,
      textDirection: _textDirection,
    );
    _sentAtTextPainter = TextPainter(
      text: _sentAtTextSpan,
      textDirection: _textDirection,
    );
  }

  String _text;
  String get text => _text;
  set text(String value) {
    if (value == _text) return;
    _text = value;
    _textPainter.text = _textTextSpan;
    markNeedsLayout();
    markNeedsSemanticsUpdate();
  }

  String _sentAt;
  String get sentAt => _sentAt;
  set sentAt(String value) {
    if (value == _sentAt) return;
    _sentAt = value;
    _sentAtTextPainter.text = _sentAtTextSpan;
    markNeedsLayout();
    markNeedsSemanticsUpdate();
  }

  TextStyle _textStyle;
  TextStyle get textStyle => _textStyle;
  set textStyle(TextStyle value) {
    if (value == _textStyle) return;
    _textStyle = value;
    _textPainter.text = _textTextSpan;
    _sentAtTextPainter.text = _sentAtTextSpan;
    markNeedsLayout();
    markNeedsSemanticsUpdate();
  }

  TextDirection _textDirection;
  TextDirection get textDirection => _textDirection;
  set textDirection(TextDirection value) {
    if (value == _textDirection) return;
    _textDirection = value;
    _textPainter.textDirection = _textDirection;
    _sentAtTextPainter.textDirection = _textDirection;
  }

  late TextPainter _textPainter;
  late TextPainter _sentAtTextPainter;

  TextSpan get _textTextSpan => TextSpan(
        text: _text,
        style: _textStyle,
      );

  TextSpan get _sentAtTextSpan => TextSpan(
        text: _sentAt,
        style: _textStyle.copyWith(
          color: Colors.grey,
        ),
      );

  late bool _sentAtFitsOnLastLine;
  late double _lineHeight;
  late double _lastMessageLineWidth;
  double _longestLineWidth = 0;
  late double _sentAtLineWidth;
  late int _numMessageLines;

  @override
  void performLayout() {
    _textPainter.layout(maxWidth: constraints.maxWidth);
    _sentAtTextPainter.layout(maxWidth: constraints.maxWidth);

    final textLines = _textPainter.computeLineMetrics();
    _sentAtLineWidth = _sentAtTextPainter.computeLineMetrics().first.width;

    _longestLineWidth = 0;
    for (final line in textLines) {
      // What do this?
      _longestLineWidth = max(_longestLineWidth, line.width);
    }
    // What do this?
    _lastMessageLineWidth = textLines.last.width;
    _lineHeight = textLines.last.height;
    _numMessageLines = textLines.length;

    final sizeOfMessage = Size(_longestLineWidth, _textPainter.height);

    final lastLineWithDate = _lastMessageLineWidth + (_sentAtLineWidth * 1.1);

    if (textLines.length == 1) {
      _sentAtFitsOnLastLine = lastLineWithDate < constraints.maxWidth;
    } else {
      _sentAtFitsOnLastLine =
          lastLineWithDate < min(_longestLineWidth, constraints.maxWidth);
    }

    late Size computedSize;
    if (!_sentAtFitsOnLastLine) {
      computedSize = Size(sizeOfMessage.width,
          sizeOfMessage.height + _sentAtTextPainter.height);
    } else {
      if (textLines.length == 1) {
        computedSize = Size(lastLineWithDate, sizeOfMessage.height);
      } else {
        computedSize = Size(_longestLineWidth, sizeOfMessage.height);
      }
    }

    size = constraints.constrain(computedSize);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    _textPainter.paint(context.canvas, offset);

    late Offset sentAtOffset;
    if (_sentAtFitsOnLastLine) {
      sentAtOffset = Offset(
        offset.dx + (size.width - _sentAtLineWidth),
        offset.dy + (_lineHeight * (_numMessageLines - 1)),
      );
    } else {
      sentAtOffset = Offset(
        offset.dx + (size.width - _sentAtLineWidth),
        offset.dy + (_lineHeight * _numMessageLines),
      );
    }
    _sentAtTextPainter.paint(context.canvas, sentAtOffset);
  }

  @override
  void describeSemanticsConfiguration(SemanticsConfiguration config) {
    super.describeSemanticsConfiguration(config);
    config.isSemanticBoundary = true;
    config.label = '$_text, sent at $sentAt';
    config.textDirection = _textDirection;
  }
}
