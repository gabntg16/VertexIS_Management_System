import 'package:flutter/widgets.dart';
import 'image_preview_stub.dart'
    if (dart.library.io) 'image_preview_io.dart';

Widget localImagePreview(String path) => buildLocalImage(path);
