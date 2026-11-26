import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'ui/puzzle_screen.dart';
import 'ui/sunlit_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const ProviderScope(child: JigsawCardsApp()));
}

class JigsawCardsApp extends StatelessWidget {
  const JigsawCardsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Jigsaw Cards',
      debugShowCheckedModeBanner: false,
      theme: Sunlit.theme(),
      home: const Scaffold(body: PuzzleScreen()),
    );
  }
}
