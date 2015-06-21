library many_points.test;

import 'package:many_points/many_points.dart';

void main() {
  Visualisation chart = new Visualisation();

  chart.addData(0, 0, 12);
  chart.addData(20, 20, 72);
  chart.addData(0, 20, 53);
  chart.addData(20, 0, 30);

  ColorTransformFunction fn = (int x, int y, num value, Range xRange,
      Range yRange, Range dataRange) {
    return Color.fromRgb(value * 3, 0, 0);
  };

  chart.setColorTransform(fn);
  chart.render(21, 21);
}
