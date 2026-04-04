import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

class KycDocument {
  File? file;
  Uint8List? bytes;
  PlatformFile? platformFile;
  String? networkUrl;

  KycDocument({this.file, this.bytes, this.platformFile, this.networkUrl});

  bool get isEmpty => file == null && bytes == null && platformFile == null;
  String? get fileName => platformFile?.name;
}
