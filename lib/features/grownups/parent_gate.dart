import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A small sum only a reader can answer, shown before the grown-ups area (which
/// holds settings, links out of the app and the only ad). Play Families policy
/// expects such a gate in front of anything aimed at parents.
Future<bool> showParentGate(BuildContext context, {math.Random? random}) async {
  final rng = random ?? math.Random();
  final a = 3 + rng.nextInt(6), b = 2 + rng.nextInt(6);
  final answer = a + b;
  final options = <int>{answer};
  while (options.length < 4) {
    options.add(math.max(2, answer + rng.nextInt(9) - 4));
  }
  final shuffled = options.toList()..shuffle(rng);
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      key: const Key('parent-gate'),
      title: const Text('For grown-ups'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('What is $a + $b?', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            children: [
              for (final n in shuffled)
                FilledButton.tonal(
                  key: Key('gate-$n'),
                  onPressed: () => Navigator.pop(ctx, n == answer),
                  child: Text('$n', style: const TextStyle(fontSize: 20)),
                ),
            ],
          ),
        ],
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Back to playing'))],
    ),
  );
  return ok ?? false;
}
