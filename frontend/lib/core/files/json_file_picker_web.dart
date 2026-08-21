import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

final class PickedJsonFile {
  const PickedJsonFile({required this.name, required this.content});

  final String name;
  final String content;
}

final class WebJsonFilePicker {
  const WebJsonFilePicker();

  Future<PickedJsonFile?> pick() async {
    final web.HTMLInputElement input = web.HTMLInputElement()
      ..type = 'file'
      ..accept = '.json,application/json'
      ..multiple = false;

    input.click();

    await input.onChange.first;

    final web.FileList? files = input.files;

    if (files == null || files.length == 0) {
      return null;
    }

    final web.File? file = files.item(0);

    if (file == null) {
      return null;
    }

    final web.FileReader reader = web.FileReader();

    reader.readAsText(file);

    await reader.onLoadEnd.first;

    final JSAny? result = reader.result;

    if (result == null || !result.isA<JSString>()) {
      throw const FormatException(
        'The selected file could not be read as text.',
      );
    }

    return PickedJsonFile(
      name: file.name,
      content: (result as JSString).toDart,
    );
  }
}
