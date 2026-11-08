import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

/// 画面の撮影(binding.takeScreenshot)を build/shots/<名前>.png に保存する。
Future<void> main() => integrationDriver(
      onScreenshot: (name, bytes, [args]) async {
        final f = File('build/shots/$name.png')..createSync(recursive: true);
        f.writeAsBytesSync(bytes);
        return true;
      },
    );
