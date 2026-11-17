import 'package:flutter/material.dart';

/// Slides in once on entry and leaves the map immediately interactive.
class RunningWelcome extends StatelessWidget {
  const RunningWelcome({
    super.key,
    required this.visible,
    required this.german,
  });
  final bool visible;
  final bool german;

  @override
  Widget build(BuildContext context) {
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 560);
    return ExcludeSemantics(
      excluding: !visible,
      child: IgnorePointer(
        child: AnimatedSlide(
          key: const Key('running-welcome-slide'),
          offset: visible ? Offset.zero : const Offset(1.15, 0),
          duration: duration,
          curve: Curves.easeInOutCubic,
          child: AnimatedOpacity(
            opacity: visible ? 1 : 0,
            duration: duration,
            child: ShaderMask(
              blendMode: BlendMode.dstIn,
              shaderCallback: (rect) => const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.white, Colors.white, Colors.transparent],
                stops: [0, .74, 1],
              ).createShader(rect),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      'assets/running_welcome.png',
                      fit: BoxFit.cover,
                      alignment: const Alignment(.3, 0),
                      excludeFromSemantics: true,
                    ),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFFF2F5E9),
                            Color(0xDDF2F5E9),
                            Color(0x00F2F5E9),
                          ],
                          stops: [0, .38, .8],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              german
                                  ? 'DEIN MOMENT DRAUSSEN'
                                  : 'YOUR TIME OUTSIDE',
                              style: const TextStyle(
                                color: Color(0xFF446D50),
                                fontSize: 10,
                                letterSpacing: 1.6,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              german
                                  ? 'Lauf\neinfach los.'
                                  : 'Just\nstart running.',
                              style: const TextStyle(
                                color: Color(0xFF172C22),
                                fontSize: 36,
                                height: 1.04,
                                letterSpacing: -1.2,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              german
                                  ? 'Erkunde deine\nUmgebung.'
                                  : 'Explore your\nsurroundings.',
                              style: const TextStyle(
                                color: Color(0xFF3A5545),
                                fontSize: 16,
                                height: 1.35,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
