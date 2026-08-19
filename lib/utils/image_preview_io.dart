import 'dart:io';
import 'package:flutter/material.dart';

Widget buildLocalImage(String path) => Image.file(
      File(path),
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => const Center(
        child: Text('Unable to preview image',
            style: TextStyle(color: Colors.white70)),
      ),
    );
