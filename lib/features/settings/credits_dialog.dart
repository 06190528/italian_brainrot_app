import 'package:flutter/material.dart';

import '../../core/strings.dart';

/// 出典の表記。CC BY 4.0 の背景写真は、作者・題名・ライセンスの表記が必須。CC0 の素材は表記不要だが、載せる。
const creditLines = <(String, String)>[
  ('Background photo', '"Positano (Italy) 04" by Bernard Gagnon, licensed under CC BY 4.0 (creativecommons.org/licenses/by/4.0), via Wikimedia Commons. Cropped to fit the screen.'),
  ('Sound effects', 'Kenney (kenney.nl), CC0 1.0'),
  ('Music', '"Carnival Rides" by Écrivain; "Shine Blitz" by Chris Murphy (zesona) — OpenGameArt.org, CC0 1.0'),
  ('Coin icon', 'MELLE — OpenGameArt.org, CC0 1.0'),
];

class CreditsDialog extends StatelessWidget {
  const CreditsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(S.credits),
      content: SizedBox(
        width: 320,
        child: SingleChildScrollView(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            for (final (title, body) in creditLines) ...[
              Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
              Text(body, style: const TextStyle(fontSize: 13)),
              const SizedBox(height: 10),
            ],
          ]),
        ),
      ),
      actions: [TextButton(key: const Key('creditsClose'), onPressed: () => Navigator.pop(context), child: Text(S.ok))],
    );
  }
}
