import 'package:flutter/material.dart';

/// Small, resolution-independent paper illustration for the food card.
class ShoppingNoteArt extends StatelessWidget {
  const ShoppingNoteArt({super.key});

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = (constraints.maxWidth - 6).clamp(24.0, 46.0);
      return Center(
        child: Transform.rotate(
          angle: -.10,
          child: Container(
            width: width,
            height: width * 1.5,
            padding: const EdgeInsets.fromLTRB(5, 9, 5, 7),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Theme.of(context).colorScheme.surfaceContainerHigh
                  : const Color(0xFFFFFDF3),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: const Color(0xFFA4C99B), width: 1.4),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 5,
                  offset: Offset(1, 3),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(
                4,
                (index) => Row(
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: const Color(0xFF719585),
                          width: .8,
                        ),
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Container(
                        height: 1.2,
                        color: const Color(0xFFB8C9BE),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}
