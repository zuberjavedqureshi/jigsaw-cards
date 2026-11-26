import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../game/praise/praise_rules.dart';

/// Praise policy for connections and completion (M3.3). One place to tune
/// the messages, the large-group size and the pacing after playtesting;
/// tests override it.
final praiseRulesProvider = Provider<PraiseRules>((ref) => const PraiseRules());
