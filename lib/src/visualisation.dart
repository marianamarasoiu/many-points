part of many_points;

class Visualisation {
  String _imagePrefix = 'output/image/';

  List<DataTransformFunction> _dataTransforms = [];
  ColorTransformFunction _colorTransform;
  List<int> xs = [];
  List<int> ys = [];
  List<num> values = [];
  List<int> colors = [];
  Range xRange;
  Range yRange;
  Range valueRange;

  Visualisation() {
    xRange = new Range(double.INFINITY, double.NEGATIVE_INFINITY);
    yRange = new Range(double.INFINITY, double.NEGATIVE_INFINITY);
    valueRange = new Range(double.INFINITY, double.NEGATIVE_INFINITY);
  }

  /// Add a data point defined by the [x] and [y] coordinates and its [value].
  void addData(num x, num y, num value) {
    xs.add(x);
    ys.add(y);
    values.add(value);

    // Adjust the ranges for the data.
    xRange.min = math.min(xRange.min, x);
    xRange.max = math.max(xRange.max, x);

    yRange.min = math.min(yRange.min, y);
    yRange.max = math.max(yRange.max, y);

    valueRange.min = math.min(valueRange.min, value);
    valueRange.max = math.max(valueRange.max, value);
  }

  /// Appends the data points defined by the coordinate lists [ix] and [iy] and
  /// the value list [ivalue].
  void addAllDataPoints(
      Iterable<num> ix, Iterable<num> iy, Iterable<num> ivalue) {
    xs.addAll(ix);
    ys.addAll(iy);
    values.addAll(ivalue);

    // Adjust the ranges for the data.
    for (num x in ix) {
      xRange.min = math.min(xRange.min, x);
      xRange.max = math.max(xRange.max, x);
    }
    for (num y in iy) {
      yRange.min = math.min(yRange.min, y);
      yRange.max = math.max(yRange.max, y);
    }
    for (num value in ivalue) {
      valueRange.min = math.min(valueRange.min, value);
      valueRange.max = math.max(valueRange.max, value);
    }
  }

  /// Appends the transform to the end of the end of the data transform list.
  void addDataTransform(DataTransformFunction function) {
    _dataTransforms.add(function);
  }

  /// Sets the color transform.
  void setColorTransform(ColorTransformFunction function) {
    _colorTransform = function;
  }

  /// Clears the data and color transform functions.
  void clearTransforms() {
    _dataTransforms.clear();
    _colorTransform = null;
  }

  /// Writes the visualisation to file and scales it if necessary.
  /// If [width] is -1, then there is no scaling.
  /// If [width] is > 0 and [height] is -1, then the scaling will be determined
  /// by the aspect ratio of the visualisation and [width].
  void render(num width, [num height = -1]) {
    _applyTransforms();

    int w = (xRange.max - xRange.min).ceil() + 1;
    int h = (yRange.max - yRange.min).ceil() + 1;
    Image image = new Image(w, h);

    for (int i = 0; i < xs.length; i++) {
      image.setPixel(xs[i], ys[i], colors[i]);
    }

    if (width != -1) {
      image = copyResize(image, width, height, NEAREST);
    }
    new io.File(_imagePrefix + new DateTime.now().toString() + '.png')
        .create(recursive: true)
        .then((io.File file) {
      file.writeAsBytesSync(encodePng(image));
    });
  }

  void render_SCALING_HACK(num width, num height) {
    _applyTransforms();

    int w = (xRange.max - xRange.min).ceil() + 1;
    int h = (yRange.max - yRange.min).ceil() + 1;
    Image image = new Image(width, height);

    for (int i = 0; i < xs.length; i++) {
      image.setPixel(
          (((xs[i] - xRange.min) / w) * width).floor(),
          (((ys[i] - yRange.min) / h) * height).floor(), colors[i]);
    }

//    if (width != -1) {
//      image = copyResize(image, width, height, NEAREST);
//    }
    new io.File(_imagePrefix + new DateTime.now().toString() + '.png')
    .create(recursive: true)
    .then((io.File file) {
      file.writeAsBytesSync(encodePng(image));
    });
  }

  /// Applies the transforms to the stored data points.
  /// It modifies the data point values, so no more data should be added after
  /// calling this method.
  void _applyTransforms() {
    // Go through data transforms first and apply them to every point.
    for (DataTransformFunction transform in _dataTransforms) {
      List<num> newXs = [];
      List<num> newYs = [];
      List<num> newValues = [];
      Range newXRange = new Range(double.INFINITY, double.NEGATIVE_INFINITY);
      Range newYRange = new Range(double.INFINITY, double.NEGATIVE_INFINITY);
      Range newValueRange =
          new Range(double.INFINITY, double.NEGATIVE_INFINITY);

      for (int i = 0; i < xs.length; i++) {
        List result =
            transform(xs[i], ys[i], values[i], xRange, yRange, valueRange);

        newXs.add(result[0]);
        newYs.add(result[1]);
        newValues.add(result[2]);

        // Adjust the ranges for the data.
        newXRange.min = math.min(newXRange.min, result[0]);
        newXRange.max = math.max(newXRange.max, result[0]);

        newYRange.min = math.min(newYRange.min, result[1]);
        newYRange.max = math.max(newYRange.max, result[1]);

        newValueRange.min = math.min(newValueRange.min, result[2]);
        newValueRange.max = math.max(newValueRange.max, result[2]);
      }
      xs = newXs;
      ys = newYs;
      values = newValues;
      xRange = newXRange;
      yRange = newYRange;
      valueRange = newValueRange;
    }

    // Apply the color transform.
    if (_colorTransform != null) {
      for (int i = 0; i < xs.length; i++) {
        num color = _colorTransform(
            xs[i], ys[i], values[i], xRange, yRange, valueRange);
        colors.add(color);
      }
    } else {
      for (int i = 0; i < xs.length; i++) {
        colors.add(Color.fromRgb(0, 0, 0));
      }
    }
  }
}
