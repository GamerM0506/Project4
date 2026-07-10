import 'package:flutter/material.dart';

class HomeFeaturedGroups extends StatelessWidget {
  const HomeFeaturedGroups({super.key});

  @override
  Widget build(BuildContext context) {
    final groups = [
      {
        'name': 'Community Kitchen',
        'location': 'Phnom Penh',
        'members': '1.2k members',
        'image': 'https://lh3.googleusercontent.com/aida-public/AB6AXuBTFkTPhzZx2aiwX97HlX_lnR6TlrbWLy-uNf2vOVehAIbs59AzfCZmWVt43nPhb3dG9ck3NsbpvMLS7XWQmAscq8WNeBKpjMpy7g5hCBbPUVvkQgJWgQRzlf361GK_Nwj3WOuysj8JOL6JQ-ioMncHFI_eNDbLZQ_zqY3ZS-RvGH1JOFKRaO1FO_h4bd6fGzrfy-hbNOOIbnw0n6ywJq97s_ClvpWIgsTzlF19RQFALLhof7agWEXJAQ'
      },
      {
        'name': 'Books for Kids',
        'location': 'Siem Reap',
        'members': '850 members',
        'image': 'https://lh3.googleusercontent.com/aida-public/AB6AXuA88VvTFXHwt2LsDT8pc4e3xdlGxeHvK-uFRdNvGX8XjuALvnM9r_jv9uTLDJ3idbzxTLGpEVgeqeoaXtKXXAy5z1VEGUNwAuU1m-pJtKt7MYxuHANEuTyUNMOrCqkqiqu80SQCd4dIEo2umXhNK1ykBvC0GpzJzBWsc1kXvU5PVy7TOAmA4W2EyCdlRTcIW3SmS4vNSlYVsscyNjexFQE5tequbiQvIlQjVyibjpl2h3v_4Wio6OWZjA'
      },
      {
        'name': 'Clean River',
        'location': 'Battambang',
        'members': '3.4k members',
        'image': 'https://lh3.googleusercontent.com/aida-public/AB6AXuDHYYJRucFggQt06yu9zuG0xHDFEw-BAyUxfx2jeTEiTZVIlkGFzh4aPbHj5LeEJ2ZmTAbF4K9LTGTB22TaX0vEMbY4VmyHqs-77SCrqtP0uJ21KxjRXZ3bT2rSzHT2mMmCmN8Lw9jn5nqQls7m4IwoZmnYXP94YdFxQAeBbBO9jxKfHPc2Rl9CygK3JVniRvtky5gQMibIPuwQ1rvHJ5nNK39eE6ZwefUcJJ_jEIdyQTOd_CoRgMQg5A'
      },
    ];

    return SizedBox(
      height: 170,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: groups.length,
        separatorBuilder: (context, index) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final group = groups[index];
          final colorScheme = Theme.of(context).colorScheme;
          
          return Container(
            width: 160,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: colorScheme.surfaceContainerHighest),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                )
              ]
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: colorScheme.surfaceContainerLow, width: 2),
                  ),
                  child: ClipOval(
                    child: Image.network(group['image']!, fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  group['name']!,
                  style: Theme.of(context).textTheme.labelLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.location_on, size: 12, color: colorScheme.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text(
                      group['location']!,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.group, size: 12, color: colorScheme.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text(
                      group['members']!,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
