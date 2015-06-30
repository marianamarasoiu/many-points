part of many_points;

class Visualisation {
  String _outputFolder, _outputFilename;

  List<DataTransformFunction> _dataTransforms = [];
  ColorTransformFunction _colorTransform;
  List<int> xs = [];
  List<int> ys = [];
  List<num> values = [];
  List<int> colors = [];
  Range xRange;
  Range yRange;
  Range valueRange;
  bool transformsApplied;

  Visualisation([String outputFolder = "output/image/", String outputFilename]) {
    xRange = new Range(double.INFINITY, double.NEGATIVE_INFINITY);
    yRange = new Range(double.INFINITY, double.NEGATIVE_INFINITY);
    valueRange = new Range(double.INFINITY, double.NEGATIVE_INFINITY);
    _outputFolder = outputFolder;
    _outputFilename = outputFilename;
  }

  /// Add a data point defined by the [x] and [y] coordinates and its [value].
  void addData(num x, num y, num value) {
    assert(x != null);
    assert(y != null);
    assert(value != null);
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
    Iterator x = ix.iterator;
    Iterator y = iy.iterator;
    Iterator value = ivalue.iterator;
    while (x.moveNext() && y.moveNext() && value.moveNext()) {
      addData(x.current, y.current, value.current);
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
  void renderSync([num width = -1, num height = -1]) {
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
    String filename = _outputFolder;
    if (_outputFilename == null) {
      filename = filename + new DateTime.now().toString() + '.png';
    } else {
      filename = filename + _outputFilename;
    }
    new io.File(filename).create(recursive: true).then((io.File file) {
      file.writeAsBytesSync(encodePng(image));
    });
  }

  void render_SCALING_HACK(num width, num height) {
    _applyTransforms();

    int w = (xRange.max - xRange.min).ceil() + 1;
    int h = (yRange.max - yRange.min).ceil() + 1;
    Image image = new Image(width, height);

    for (int i = 0; i < xs.length; i++) {
      image.setPixel((((xs[i] - xRange.min) / w) * width).floor(),
          (((ys[i] - yRange.min) / h) * height).floor(), colors[i]);
    }

//    if (width != -1) {
//      image = copyResize(image, width, height, NEAREST);
//    }
    String filename = _outputFolder;
    if (_outputFilename == null) {
      filename = filename + new DateTime.now().toString() + '.png';
    } else {
      filename = filename + _outputFilename;
    }
    new io.File(filename).create(recursive: true).then((io.File file) {
      file.writeAsBytesSync(encodePng(image));
    });
  }

  /// Writes only the selected range of the visualisation to file. No scaling.
  void renderAreaSync(Range areaX, Range areaY) {
    assert(areaX != null);
    assert(areaY != null);
    _applyTransforms();

    int w = (areaX.max - areaX.min).ceil() + 1;
    int h = (areaY.max - areaY.min).ceil() + 1;
    Image image = new Image(w, h);

    for (int i = 0; i < xs.length; i++) {
      if (areaX.min <= xs[i] && xs[i] <= areaY.max &&
          areaY.min <= ys[i] && ys[i] <= areaY.max) {
        image.setPixel(xs[i], ys[i], colors[i]);
      }
    }

    String filename = _outputFolder;
    if (_outputFilename == null) {
      filename = filename +
          new DateTime.now().toString() +
          '_${areaX.min},${areaX.max}_${areaY.min},${areaY.max}' +
          '.png';
    } else {
      filename = filename + _outputFilename;
    }
    new io.File(filename).create(recursive: true).then((io.File file) {
      file.writeAsBytesSync(encodePng(image));
    });
  }

  /// Applies the transforms to the stored data points.
  /// It modifies the data point values, so no more data should be added after
  /// calling this method.
  /// TODO(mariana): Enforce this (e.g. add a flag on the class that fails the add calls).
  void _applyTransforms() {
    // Apply the transforms only once. This allows for multiple render calls but
    // a single transforms application phase.
    if (transformsApplied == false) return;
    transformsApplied = true;
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
