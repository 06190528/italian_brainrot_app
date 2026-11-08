import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/audio_service.dart';
import '../../core/strings.dart';

class SettingsDialog extends ConsumerStatefulWidget {
  const SettingsDialog({super.key});

  @override
  ConsumerState<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends ConsumerState<SettingsDialog> {
  late final TextEditingController _name =
      TextEditingController(text: ref.read(userDataProvider).name);

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userDataProvider);
    return AlertDialog(
      title: Text(S.settings),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(
          key: const Key('nameField'),
          controller: _name,
          maxLength: 12,
          decoration: InputDecoration(labelText: S.playerName),
        ),
        SwitchListTile(
          key: const Key('soundSwitch'),
          title: Text(S.sound),
          value: user.soundOn,
          onChanged: (v) {
            ref.read(userDataProvider.notifier).setSound(v);
            AudioService.instance.enabled = v;
            if (!v) AudioService.instance.stopBgm();
          },
        ),
      ]),
      actions: [
        TextButton(
          key: const Key('settingsSave'),
          onPressed: () {
            final n = _name.text.trim();
            if (n.isNotEmpty) ref.read(userDataProvider.notifier).setName(n);
            Navigator.pop(context);
          },
          child: Text(S.save),
        ),
      ],
    );
  }
}
