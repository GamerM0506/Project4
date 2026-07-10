import 'package:flutter/material.dart';

class HomeHeroBanner extends StatelessWidget {
  const HomeHeroBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      constraints: const BoxConstraints(minHeight: 180),
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        color: colorScheme.surfaceContainerHighest,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Stack(
          children: [
            // Background Image
            Positioned.fill(
              child: Opacity(
                opacity: 0.8,
                child: Image.network(
                  'https://lh3.googleusercontent.com/aida/AP1WRLsahntZF3atg6yuEDyAd4OOn0tgcJ9AAO6GnQccI9qRYXyU1enVo_edqXm9QZCl04SU6ol5RKIvV9gPO7wrLs33IyiJF4ZC2Fi2HtR_GmIkyNHIoFzCPU9Yh_t_kdFIuc_H0sIhgL3VFHBdO2Y54iQ0BXf-hpQ8X7L2ffb_ZQv-3YuJZwMO9Ah27WGLA1mxw8DKWAF70tm8-n4BssXSlIApniq-4Oj4m-n6paGKFtNM8skIVuuiZu4Ygj8',
                  fit: BoxFit.cover,
                  colorBlendMode: BlendMode.multiply,
                ),
              ),
            ),
            // Gradient Overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.surface.withValues(alpha: 0.9),
                      Colors.transparent,
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Help a Neighbor\nToday',
                    style: textTheme.headlineSmall?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your small donation makes\na big difference.',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.volunteer_activism, size: 18),
                    label: const Text('Donate Now'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
