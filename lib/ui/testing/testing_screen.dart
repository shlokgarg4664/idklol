import 'package:flutter/material.dart';
import 'package:sports_app/widgets/figure_icon.dart';
import 'package:sports_app/features/pose_detector/screens/home_screen.dart';

class TestingScreen extends StatelessWidget {
  const TestingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = <_TestItem>[
      _TestItem('Pushups', () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }),
      _TestItem('Shuttle Run', () => _comingSoon(context, 'Shuttle Run')),
      _TestItem('Endurance Run', () => _comingSoon(context, 'Endurance Run')),
      _TestItem('Vertical Jump', () => _comingSoon(context, 'Vertical Jump')),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Testing')),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.0,
        ),
        itemCount: items.length,
        itemBuilder: (_, i) => _TestCard(item: items[i]),
      ),
    );
  }

  static void _comingSoon(BuildContext context, String title) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: const Text('This test will be available soon.'),
      ),
    );
  }
}

class _TestItem {
  _TestItem(this.title, this.onTap);
  final String title;
  final VoidCallback onTap;
}

class _TestCard extends StatelessWidget {
  const _TestCard({required this.item});
  final _TestItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: theme.colorScheme.surface.withValues(alpha: 0.5),
          border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const FigureIcon(size: 56),
            const SizedBox(height: 12),
            Text(item.title, style: theme.textTheme.titleMedium),
          ],
        ),
      ),
    );
  }
}
