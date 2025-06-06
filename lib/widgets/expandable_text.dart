import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class ExpandableText extends StatefulWidget {
  final String text;
  final int trimLines;
  final TextStyle? style;
  final String trimExpandedText;
  final String trimCollapsedText;
  final Color linkColor;

  const ExpandableText(
    this.text, {
    super.key,
    this.trimLines = 2,
    this.style,
    this.trimExpandedText = ' Read less',
    this.trimCollapsedText = '... Read more',
    this.linkColor = Colors.blue,
  });

  @override
  ExpandableTextState createState() => ExpandableTextState();
}

class ExpandableTextState extends State<ExpandableText> {
  bool _readMore = true;

  void _onTapLink() {
    setState(() => _readMore = !_readMore);
  }

  @override
  Widget build(BuildContext context) {
    final DefaultTextStyle defaultTextStyle = DefaultTextStyle.of(context);
    TextStyle effectiveTextStyle = widget.style ?? defaultTextStyle.style;
    if (widget.style?.inherit ?? false) {
       effectiveTextStyle = defaultTextStyle.style.merge(widget.style);
    }


    TextSpan link = TextSpan(
      text: _readMore ? widget.trimCollapsedText : widget.trimExpandedText,
      style: effectiveTextStyle.copyWith(color: widget.linkColor, fontWeight: FontWeight.bold),
      recognizer: TapGestureRecognizer()..onTap = _onTapLink,
    );

    Widget result = LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        assert(constraints.hasBoundedWidth);
        final double maxWidth = constraints.maxWidth;

        // Create a TextSpan with data
        final text = TextSpan(
          text: widget.text,
          style: effectiveTextStyle,
        );

        // Layout and measure text
        TextPainter textPainter = TextPainter(
          text: link,
          textAlign: TextAlign.start,
          textDirection: TextDirection.ltr, // Or TextDirection.rtl
          maxLines: widget.trimLines,
          ellipsis: '...',
        );
        textPainter.layout(minWidth: constraints.minWidth, maxWidth: maxWidth);
        final linkSize = textPainter.size;

        textPainter.text = text;
        textPainter.layout(minWidth: constraints.minWidth, maxWidth: maxWidth);
        final textSize = textPainter.size;

        // Get the endIndex of data
        int? endIndex;
        if (textPainter.didExceedMaxLines) {
          final pos = textPainter.getPositionForOffset(Offset(
            textSize.width - linkSize.width,
            textSize.height,
          ));
          endIndex = textPainter.getOffsetBefore(pos.offset);
        }


        TextSpan textSpan;
        if (textPainter.didExceedMaxLines) {
          textSpan = TextSpan(
            text: _readMore && endIndex != null
                ? widget.text.substring(0, endIndex)
                : widget.text,
            style: effectiveTextStyle,
            children: <TextSpan>[link],
          );
        } else {
          textSpan = text;
        }

        return RichText(
          softWrap: true,
          overflow: TextOverflow.clip,
          text: textSpan,
        );
      },
    );
    return result;
  }
}