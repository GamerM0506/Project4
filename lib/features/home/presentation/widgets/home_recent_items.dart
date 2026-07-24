import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class HomeRecentItems extends StatelessWidget {
  const HomeRecentItems({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      {
        'name': 'Áo khoác mùa đông',
        'type': 'Quần áo',
        'donor': 'Hội Chữ thập đỏ',
        'image':
            'https://lh3.googleusercontent.com/aida-public/AB6AXuAA3MKdv3wXXZpRjT_25whtOOUt7i2qV_Kf8GV9HVTs9MQOYNs_xXexoIM_ntmGfS598smcr0DOEK-6wej6qDNwBwp5auPWSjHd34krmV4VDBERZk6NIpkW-T0M-N7-PUSCrCZfDVhfZQ2Al2W6erdBhtwXfyJJQv02R24rZpbQjKABumUKJ8L33abvulOmNxUhdjALm8P8Z7FcOd-pgp27rJ1b62JLmevp2lUa-GkCJ1LtD3jjtyWNRg',
      },
      {
        'name': 'Nôi em bé',
        'type': 'Đồ nội thất',
        'donor': 'Người dân địa phương',
        'image':
            'https://lh3.googleusercontent.com/aida-public/AB6AXuAUnnM-aoudYiyJ1OCyTCW_p6AZ88UOBgqRxUyrJT24ZyrdY-_vn0ABSMqEqFtCh-9Nht2MSGoUO3pU6PohJehBJt2FiKVmvaPEbGszefy2NMy4HeuiGz9BvEj9Re3F1wfamhoePfchAFfaQwCUQ8-0z-cdwAdvhX5BS6H45rFXqQolHyJ8OZAXjKbNS7uonmq64AO74WxutfyahGK8u0vqQyP1cMGZMKadAY2fBYFkhanMqmHRwpjyUQ',
      },
      {
        'name': 'Thùng nhu yếu phẩm',
        'type': 'Thực phẩm',
        'donor': 'Tủ lạnh cộng đồng',
        'image':
            'https://lh3.googleusercontent.com/aida-public/AB6AXuArpiAD4MM9pUq2PTYcBmxncOFEL82t7iq0KYE-8fDaV-oeTfslvkYUHO2Sz0zpksZf6cMutX3-UPjbckHCVaVogHlJ07L_McdRIzZjtZPS0S5ZFCSK0h-GkLj1szqm3cnlJNy69vdOhKNo5lrcc_l1d3Tu1_S63BFV1sPBUUbcoN8ipos1xdaP95vSjugZkJDuC6_i7YCAz-x8np8YqCS_2Ht2lec9zJ7G-Ebl2GgKm0dYqvclIuHoYw',
      },
    ];

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = items[index];
        final colorScheme = Theme.of(context).colorScheme;

        return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colorScheme.surfaceContainerHighest),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      item['image']!,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              item['name']!,
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.secondaryContainer,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                'Miễn phí',
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      color: colorScheme.onSecondaryContainer,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.sell_outlined,
                              size: 14,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              item['type']!,
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.verified_outlined,
                              size: 14,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              item['donor']!,
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
            .animate(delay: (index * 100).ms)
            .fade(duration: 400.ms)
            .slideX(begin: -0.1, curve: Curves.easeOut);
      },
    );
  }
}
