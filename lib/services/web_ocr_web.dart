import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';

@JS('vkuRecognizeText')
external JSPromise<JSString> _vkuRecognizeText(JSString dataUrl);

Future<String> recognizeImageBytes(Uint8List bytes) async {
  final dataUrl = 'data:image/jpeg;base64,${base64Encode(bytes)}';
  final result = await _vkuRecognizeText(dataUrl.toJS).toDart;
  return result.toDart;
}
