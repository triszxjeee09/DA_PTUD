import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Hiển thị ảnh từ `XFile` trên mọi nền tảng (đọc bytes, dùng được cả Flutter Web).
class XFileImage extends StatefulWidget {
  const XFileImage({
    super.key,
    required this.file,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  final XFile file;
  final double? width;
  final double? height;
  final BoxFit fit;

  @override
  State<XFileImage> createState() => _XFileImageState();
}

class _XFileImageState extends State<XFileImage> {
  late Future<Uint8List> _bytes;

  @override
  void initState() {
    super.initState();
    _bytes = widget.file.readAsBytes();
  }

  @override
  void didUpdateWidget(covariant XFileImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.file.path != widget.file.path) {
      _bytes = widget.file.readAsBytes();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: _bytes,
      builder: (context, snapshot) {
        final data = snapshot.data;
        if (data != null) {
          return Image.memory(
            data,
            width: widget.width,
            height: widget.height,
            fit: widget.fit,
          );
        }
        return SizedBox(
          width: widget.width,
          height: widget.height,
          child: Center(
            child: snapshot.hasError
                ? const Icon(Icons.broken_image_outlined)
                : const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
          ),
        );
      },
    );
  }
}
