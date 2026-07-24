import 'package:flutter/material.dart';
import '../../../../core/widgets/app_network_image.dart';

class ProductCard extends StatelessWidget {
  final String title;
  final String imageUrl;
  final bool isNew;
  final String providerName;
  final String providerLogo;
  final String location;
  final VoidCallback onReceive;

  const ProductCard({
    super.key,
    required this.title,
    required this.imageUrl,
    required this.isNew,
    required this.providerName,
    required this.providerLogo,
    required this.location,
    required this.onReceive,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Image and Badge Stack
          Expanded(
            flex: 5,
            child: Stack(
              fit: StackFit.expand,
              children: [
                AppNetworkImage(
                  url: imageUrl,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  fit: BoxFit.cover,
                  placeholderIcon: Icons.inventory_2_outlined,
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isNew ? colorScheme.error.withValues(alpha: 0.9) : const Color(0xFFC0CA33).withValues(alpha: 0.9), // Red for NEW, Yellow-green for USED
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isNew ? 'NEW' : 'USED',
                      style: textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Content Details
          Expanded(
            flex: 6,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  
                  // Provider Info
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 8,
                        backgroundColor: colorScheme.surfaceContainerHighest,
                        child: ClipOval(
                          child: AppNetworkImage(
                            url: providerLogo,
                            width: 16,
                            height: 16,
                            placeholderIcon: Icons.groups_outlined,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          providerName,
                          style: textTheme.labelMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  
                  // Location Info
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 14, color: colorScheme.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          location,
                          style: textTheme.labelMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  
                  const Spacer(),
                  
                  // Receive Button
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: onReceive,
                      style: FilledButton.styleFrom(
                        backgroundColor: colorScheme.primary, // Teal color as per theme primary
                        foregroundColor: colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: Text(
                        'Nhận món này',
                        style: textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onPrimary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
