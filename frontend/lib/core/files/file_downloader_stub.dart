final class WebFileDownloader {
  const WebFileDownloader();

  void downloadJson({required String json, required String filename}) {
    throw UnsupportedError('File downloads are only available on the Web.');
  }
}
