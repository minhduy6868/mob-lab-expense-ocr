import 'dart:js_interop';

@JS('vkuPromptInstall')
external JSPromise<JSString> _vkuPromptInstall();

@JS('vkuDownloadApk')
external void _vkuDownloadApk();

Future<String> promptPwaInstall() async {
  try {
    final result = await _vkuPromptInstall().toDart;
    return result.toDart;
  } catch (_) {
    return 'unavailable';
  }
}

void downloadAndroidApk() {
  _vkuDownloadApk();
}
