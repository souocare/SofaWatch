import 'package:flutter/physics.dart';
import 'package:flutter/widgets.dart';

class AppPageScrollPhysics extends PageScrollPhysics {
  const AppPageScrollPhysics({super.parent, this.pageChangeThreshold = 0.18});

  final double pageChangeThreshold;

  @override
  AppPageScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return AppPageScrollPhysics(
      parent: buildParent(ancestor),
      pageChangeThreshold: pageChangeThreshold,
    );
  }

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    if (position is! PageMetrics || position.page == null) {
      return super.createBallisticSimulation(position, velocity);
    }

    if ((velocity <= 0.0 && position.pixels <= position.minScrollExtent) ||
        (velocity >= 0.0 && position.pixels >= position.maxScrollExtent)) {
      return super.createBallisticSimulation(position, velocity);
    }

    final Tolerance tolerance = toleranceFor(position);

    final double page = position.page!;
    final double nearestPage = page.roundToDouble();
    final double pageOffset = page - nearestPage;

    double targetPage = nearestPage;

    if (velocity.abs() > tolerance.velocity) {
      targetPage = velocity > 0 ? page.ceilToDouble() : page.floorToDouble();
    } else if (pageOffset.abs() >= pageChangeThreshold) {
      targetPage = pageOffset > 0 ? nearestPage + 1 : nearestPage - 1;
    }

    final double targetPixels = (targetPage * position.viewportDimension).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );

    if ((targetPixels - position.pixels).abs() < tolerance.distance) {
      return null;
    }

    return ScrollSpringSimulation(
      spring,
      position.pixels,
      targetPixels,
      velocity,
      tolerance: tolerance,
    );
  }
}
