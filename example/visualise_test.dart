library many_points.test;

import '../lib/many_points.dart';

void main() {
  exampleRenderSync();
  exampleRenderAreaSync();
}

void exampleRenderSync() {
  Visualisation chart = new Visualisation();

  chart.addData(0, 0, {'value': 12});
  chart.addData(20, 20, {'value': 72});
  chart.addData(0, 20, {'value': 53});
  chart.addData(20, 0, {'value': 30});

  ColorTransformFunction fn = (int x, int y, Map data, Range xRange,
                               Range yRange, Range dataRange) {
    return Color.fromRgb(data['value'] * 3, 0, 0);
  };

  chart.setColorTransform(fn);
  chart.renderSync(21, 21);
}

void exampleRenderAreaSync() {
  Visualisation chart = new Visualisation();

  chart.addData(0, 0, {'value': 12});
  chart.addData(20, 20, {'value': 72});
  chart.addData(0, 20, {'value': 53});
  chart.addData(20, 0, {'value': 30});
  chart.addData(10, 10, {'value': 41});

  ColorTransformFunction fn = (int x, int y, Map data, Range xRange,
                               Range yRange, Range dataRange) {
    return Color.fromRgb(data['value'] * 3, 0, 0);
  };

  chart.setColorTransform(fn);
  chart.renderSync(21, 21);
  chart.renderAreaSync(new Range(0, 10), new Range(0, 10));
}
