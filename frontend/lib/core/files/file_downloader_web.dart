import 'dart:js_interop';

import 'package:web/web.dart' as web;

final class WebFileDownloader {
  const WebFileDownloader();

  void downloadJson({required String json, required String filename}) {
    final web.Blob blob = web.Blob(
      <JSAny>[json.toJS].toJS,
      web.BlobPropertyBag(type: 'application/json;charset=utf-8'),
    );

    final String objectUrl = web.URL.createObjectURL(blob);

    final web.HTMLAnchorElement anchor = web.HTMLAnchorElement()
      ..href = objectUrl
      ..download = filename
      ..style.display = 'none';

    web.document.body?.append(anchor);

    anchor.click();
    anchor.remove();

    web.URL.revokeObjectURL(objectUrl);
  }
}
