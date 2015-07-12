library many_points.example;

import 'dart:math';

import 'package:many_points/many_points.dart';


void main() {
  exampleRenderSync();
}

void exampleRenderSync() {
  Visualisation chart = new Visualisation();

  Random r = new Random();
  for (int i = 0; i < 1000; i++) {
    chart.addData(i, r.nextInt(1000), r.nextInt(256), {'code': 'Here is some code.'});
  }

  ColorTransformFunction fn = (int x, int y, num value, Range xRange,
                               Range yRange, Range dataRange) {
    return Color.fromRgb(value, 0, 0);
  };

  chart.setColorTransform(fn);
  chart.renderSync();
}

