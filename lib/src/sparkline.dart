import 'dart:math' as math;
import 'dart:ui' as ui show PointMode;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Strategy used when filling the area of a sparkline.
enum FillMode {
  /// Do not fill, draw only the sparkline.
  none,

  /// Fill the area above the sparkline: creating a closed path from the line
  /// to the upper edge of the widget.
  above,

  /// Fill the area below the sparkline: creating a closed path from the line
  /// to the lower edge of the widget.
  below,
}

/// Strategy used when drawing individual data points over the sparkline.
enum PointsMode {
  /// Do not draw individual points.
  none,

  /// Draw all the points in the data set.
  all,

  /// Draw only the last point in the data set.
  last,
}

/// A widget that draws a sparkline chart.
///
/// Represents the given [data] in a sparkline chart that spans the available
/// space.
///
/// By default only the sparkline is drawn, with its looks defined by
/// the [lineWidth] and [lineColor] properties.
///
/// The corners between two segments of the sparkline can be made sharper by
/// setting [sharpCorners] to true.
///
/// The area above or below the sparkline can be filled with the provided
/// [fillColor] by setting the desired [fillMode].
///
/// [pointsMode] controls how individual points are drawn over the sparkline
/// at the provided data point. Their appearance is determined by the
/// [pointSize] and [pointColor] properties.
///
/// By default, the sparkline is sized to fit its container. If the
/// sparkline is in an unbounded space, it will size itself according to the
/// given [fallbackWidth] and [fallbackHeight].
class Sparkline extends StatelessWidget {
  /// Creates a widget that represents provided [data] in a Sparkline chart.
  Sparkline({
    Key key,
    @required this.data,
    this.lineWidth = 2.0,
    this.lineColor = Colors.lightBlue,
    this.pointsMode = PointsMode.none,
    this.pointSize = 4.0,
    this.pointColor = const Color(0xFF0277BD), //Colors.lightBlue[800]
    this.sharpCorners = false,
    this.fillMode = FillMode.none,
    this.fillColor = const Color(0xFF81D4FA), //Colors.lightBlue[200]
    this.fallbackHeight = 100.0,
    this.fallbackWidth = 300.0,
  })
      : assert(data != null),
        assert(lineWidth != null),
        assert(lineColor != null),
        assert(pointsMode != null),
        assert(pointSize != null),
        assert(pointColor != null),
        assert(sharpCorners != null),
        assert(fillMode != null),
        assert(fillColor != null),
        assert(fallbackHeight != null),
        assert(fallbackWidth != null),
        super(key: key);

  /// List of values to be represented by the sparkline.
  ///
  /// Each data entry represents an individual point on the chart, with a path
  /// drawn connecting the consecutive points to form the sparkline.
  ///
  /// The values are normalized to fit within the bounds of the chart.
  final List<double> data;

  /// The width of the sparkline.
  ///
  /// Defaults to 2.0.
  final double lineWidth;

  /// The color of the sparkline.
  ///
  /// Defaults to Colors.lightBlue.
  final Color lineColor;

  /// Determines how individual data points should be drawn over the sparkline.
  ///
  /// Defaults to [PointsMode.none].
  final PointsMode pointsMode;

  /// The size to use when drawing individual data points over the sparkline.
  ///
  /// Defaults to 4.0.
  final double pointSize;

  /// The color used when drawing individual data points over the sparkline.
  ///
  /// Defaults to Colors.lightBlue[800].
  final Color pointColor;

  /// Determines if the sparkline path should have sharp corners where two
  /// segments intersect.
  ///
  /// Defaults to false.
  final bool sharpCorners;

  /// Determines the area that should be filled with [fillColor].
  ///
  /// Defaults to [FillMode.none].
  final FillMode fillMode;

  /// The fill color used in the chart, as determined by [fillMode].
  ///
  /// Defaults to Colors.lightBlue[200].
  final Color fillColor;

  /// The width to use when the sparkline is in a situation with an unbounded
  /// width.
  ///
  /// See also:
  ///
  ///  * [fallbackHeight], the same but vertically.
  final double fallbackWidth;

  /// The height to use when the sparkline is in a situation with an unbounded
  /// height.
  ///
  /// See also:
  ///
  ///  * [fallbackWidth], the same but horizontally.
  final double fallbackHeight;

  @override
  Widget build(BuildContext context) {
    return new LimitedBox(
      maxWidth: fallbackWidth,
      maxHeight: fallbackHeight,
      child: new CustomPaint(
        size: Size.infinite,
        painter: new _SparklinePainter(
          data,
          lineWidth: lineWidth,
          lineColor: lineColor,
          sharpCorners: sharpCorners,
          fillMode: fillMode,
          fillColor: fillColor,
          pointsMode: pointsMode,
          pointSize: pointSize,
          pointColor: pointColor,
        ),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter(
    this.dataPoints, {
    @required this.lineWidth,
    @required this.lineColor,
    @required this.sharpCorners,
    @required this.fillMode,
    @required this.fillColor,
    @required this.pointsMode,
    @required this.pointSize,
    @required this.pointColor,
  })
      : _max = dataPoints.reduce(math.max),
        _min = dataPoints.reduce(math.min);

  final List<double> dataPoints;

  final double lineWidth;
  final Color lineColor;

  final bool sharpCorners;

  final FillMode fillMode;
  final Color fillColor;

  final PointsMode pointsMode;
  final double pointSize;
  final Color pointColor;

  final double _max;
  final double _min;

  @override
  void paint(Canvas canvas, Size size) {
    final double width = size.width - lineWidth;
    final double height = size.height - lineWidth;
    final double widthNormalizer = width / (dataPoints.length - 1);
    final double heightNormalizer = height / (_max - _min);

    final Path path = new Path();
    final List<Offset> points = <Offset>[];

    Offset startPoint;

    for (int i = 0; i < dataPoints.length; i++) {
      double x = i * widthNormalizer + lineWidth / 2;
      double y =
          height - (dataPoints[i] - _min) * heightNormalizer + lineWidth / 2;

      if (pointsMode == PointsMode.all) {
        points.add(new Offset(x, y));
      }

      if (pointsMode == PointsMode.last && i == dataPoints.length - 1) {
        points.add(new Offset(x, y));
      }

      if (i == 0) {
        startPoint = new Offset(x, y);
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    Paint paint = new Paint()
      ..strokeWidth = lineWidth
      ..color = lineColor
      ..strokeCap = StrokeCap.round
      ..strokeJoin = sharpCorners ? StrokeJoin.miter : StrokeJoin.round
      ..style = PaintingStyle.stroke;

    if (fillMode != FillMode.none) {
      Path fillPath = new Path()..addPath(path, Offset.zero);
      if (fillMode == FillMode.below) {
        fillPath.relativeLineTo(lineWidth / 2, 0.0);
        fillPath.lineTo(size.width, size.height);
        fillPath.lineTo(0.0, size.height);
        fillPath.lineTo(startPoint.dx - lineWidth / 2, startPoint.dy);
      } else if (fillMode == FillMode.above) {
        fillPath.relativeLineTo(lineWidth / 2, 0.0);
        fillPath.lineTo(size.width, 0.0);
        fillPath.lineTo(0.0, 0.0);
        fillPath.lineTo(startPoint.dx - lineWidth / 2, startPoint.dy);
      }
      fillPath.close();
      Paint fillPaint = new Paint()
        ..strokeWidth = 0.0
        ..color = fillColor
        ..style = PaintingStyle.fill;
      canvas.drawPath(fillPath, fillPaint);
    }

    canvas.drawPath(path, paint);

    if (points.isNotEmpty) {
      Paint pointsPaint = new Paint()
        ..strokeCap = StrokeCap.round
        ..strokeWidth = pointSize
        ..color = pointColor;
      canvas.drawPoints(ui.PointMode.points, points, pointsPaint);
    }
  }

  @override
  bool shouldRepaint(_SparklinePainter old) {
    return dataPoints != old.dataPoints ||
        lineWidth != old.lineWidth ||
        lineColor != old.lineColor ||
        sharpCorners != old.sharpCorners ||
        fillMode != old.fillMode ||
        fillColor != old.fillColor ||
        pointsMode != old.pointsMode ||
        pointSize != old.pointSize ||
        pointColor != old.pointColor;
  }
}
