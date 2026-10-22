import 'package:flutter/material.dart';

/// Animate only route content. The shared live aurora stays behind Navigator;
/// a solid transition scrim or a route snapshot would flash over that backdrop.
class AuroraPageTransitionsBuilder extends PageTransitionsBuilder {
  const AuroraPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    return FadeTransition(
      opacity: animation.drive(CurveTween(curve: Curves.easeInOut)),
      child: FadeTransition(
        opacity: secondaryAnimation.drive(
          Tween<double>(
            begin: 1,
            end: 0,
          ).chain(CurveTween(curve: Curves.easeInOut)),
        ),
        child: child,
      ),
    );
  }
}
