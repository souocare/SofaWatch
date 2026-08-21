final class PickedJsonFile {
  const PickedJsonFile({required this.name, required this.content});

  final String name;
  final String content;
}

final class WebJsonFilePicker {
  const WebJsonFilePicker();

  Future<PickedJsonFile?> pick() {
    throw UnsupportedError('JSON file selection is only available on the Web.');
  }
}
