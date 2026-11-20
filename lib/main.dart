import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'app/app.dart';

/// 想定外の例外でアプリを落とさない(ログに残すだけ)。
void _report(Object error, StackTrace? stack) {
  debugPrint('Unhandled error: $error\n$stack');
}

Future<void> main() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    FlutterError.onError = (d) => _report(d.exception, d.stack);
    PlatformDispatcher.instance.onError = (e, s) {
      _report(e, s);
      return true;
    };
    runApp(await buildApp());
  }, _report);
}
