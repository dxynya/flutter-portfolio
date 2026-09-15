import 'package:flutter/material.dart';

class ActivityCard extends StatelessWidget {
  final String number;
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onTap;

  const ActivityCard({
    super.key,
    required this.number,
    required this.title,
    required this.description,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),

        child: Container(
          padding: const EdgeInsets.all(20),

          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF151515)
                : Colors.white,

            borderRadius: BorderRadius.circular(22),

            border: Border.all(
              color: isDark
                  ? Colors.white12
                  : Colors.black12,
            ),
          ),

          child: Row(
            children: [
              Container(
                width: 55,
                height: 55,

                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white
                      : Colors.black,
                  borderRadius: BorderRadius.circular(16),
                ),

                child: Center(
                  child: Icon(
                    icon,
                    color: isDark
                        ? Colors.black
                        : Colors.white,
                    size: 27,
                  ),
                ),
              ),

              const SizedBox(width: 18),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [
                    Text(
                      'ACTIVITY $number',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                        color: isDark
                            ? Colors.white54
                            : Colors.black54,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? Colors.white60
                            : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),

              const Icon(
                Icons.arrow_forward_ios,
                size: 17,
              ),
            ],
          ),
        ),
      ),
    );
  }
}