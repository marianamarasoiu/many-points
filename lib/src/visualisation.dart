part of many_points;

class Visualisation {
  String _outputFolder, _outputFilename;
  List<DataTransformFunction> _dataTransforms = [];
  ColorTransformFunction _colorTransform;
  List<int> _xs = [];
  List<int> _ys = [];
  List<Map> _dataList = [];
  List<int> _colors = [];
  Range _xRange;
  Range _yRange;
  Range _valueRange;
  bool _transformsApplied;
  Logger _logger;

  Visualisation([String outputFolder = "output/image/", String outputFilename,
      bool enableLogging = true]) {
    _xRange = new Range(double.INFINITY, double.NEGATIVE_INFINITY);
    _yRange = new Range(double.INFINITY, double.NEGATIVE_INFINITY);
    _valueRange = new Range(double.INFINITY, double.NEGATIVE_INFINITY);
    _outputFolder = outputFolder;
    _outputFilename = outputFilename;

    // Initialize logging
    _logger = new Logger('Visualisation');
    hierarchicalLoggingEnabled = true;
    _logger.level = enableLogging ? Level.ALL : Level.OFF;
    _logger.onRecord.listen((LogRecord rec) {
      print('${rec.level.name}: ${rec.time}: ${rec.message}');
    });
  }

  /// Add a data point defined by the [x] and [y] coordinates and its [data].
  /// The [data] map must contain a 'value' entry.
  void addData(num x, num y, Map data) {
    assert(x != null);
    assert(y != null);
    assert(data != null);
    assert(data['value'] != null);
    _xs.add(x);
    _ys.add(y);
    _dataList.add(data);

    // Adjust the ranges for the data.
    _xRange.min = math.min(_xRange.min, x);
    _xRange.max = math.max(_xRange.max, x);

    _yRange.min = math.min(_yRange.min, y);
    _yRange.max = math.max(_yRange.max, y);

    _valueRange.min = math.min(_valueRange.min, data['value']);
    _valueRange.max = math.max(_valueRange.max, data['value']);
  }

  /// Appends the data points defined by the coordinate lists [ix] and [iy] and
  /// the value list [ivalue].
  void addAllDataPoints(
      Iterable<num> ix, Iterable<num> iy, Iterable<Map> idataList) {
    Iterator x = ix.iterator;
    Iterator y = iy.iterator;
    Iterator data = idataList.iterator;
    while (x.moveNext() && y.moveNext() && data.moveNext()) {
      addData(x.current, y.current, data.current);
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
    Stopwatch sw = new Stopwatch()..start();
    _applyTransforms();
    _logger.info('Transforms applied. Duration/ms: ${sw.elapsedMilliseconds}');
    sw.reset();

    int w = (_xRange.max - _xRange.min).ceil() + 1;
    int h = (_yRange.max - _yRange.min).ceil() + 1;
    Image image = new Image(w, h);

    for (int i = 0; i < _xs.length; i++) {
      image.setPixel(_xs[i], _ys[i], _colors[i]);
    }
    _logger.info('Pixel values set. Duration/ms: ${sw.elapsedMilliseconds}');
    sw.reset();

    if (width != -1) {
      image = copyResize(image, width, height, NEAREST);
      _logger.info('Image resized. Duration/ms: ${sw.elapsedMilliseconds}');
      sw.reset();
    }

    String filePath = _computeFilePath("${new DateTime.now()}.png");
    _writeImageSync(filePath, image);
    _logger
        .info('Image written to file. Duration/ms: ${sw.elapsedMilliseconds}');
  }

  void render_SCALING_HACK(num width, num height) {
    Stopwatch sw = new Stopwatch()..start();
    _applyTransforms();
    _logger.info('Transforms applied. Duration/ms: ${sw.elapsedMilliseconds}');
    sw.reset();

    int w = (_xRange.max - _xRange.min).ceil() + 1;
    int h = (_yRange.max - _yRange.min).ceil() + 1;
    Image image = new Image(width, height);

    for (int i = 0; i < _xs.length; i++) {
      image.setPixel((((_xs[i] - _xRange.min) / w) * width).floor(),
          (((_ys[i] - _yRange.min) / h) * height).floor(), _colors[i]);
    }
    _logger.info('Pixel values set. Duration/ms: ${sw.elapsedMilliseconds}');
    sw.reset();

//    if (width != -1) {
//      image = copyResize(image, width, height, NEAREST);
//    }

    String filePath = _computeFilePath("${new DateTime.now()}.png");
    _writeImageSync(filePath, image);
    _logger
        .info('Image written to file. Duration/ms: ${sw.elapsedMilliseconds}');
  }

  /// Writes only the selected range of the visualisation to file. No scaling.
  void renderAreaSync(Range areaX, Range areaY) {
    assert(areaX != null);
    assert(areaY != null);
    Stopwatch sw = new Stopwatch()..start();
    _applyTransforms();
    _logger.info('Transforms applied. Duration/ms: ${sw.elapsedMilliseconds}');
    sw.reset();

    int w = (areaX.max - areaX.min).ceil() + 1;
    int h = (areaY.max - areaY.min).ceil() + 1;
    Image image = new Image(w, h);
    for (int i = 0; i < _xs.length; i++) {
      if (areaX.min <= _xs[i] &&
          _xs[i] <= areaY.max &&
          areaY.min <= _ys[i] &&
          _ys[i] <= areaY.max) {
        image.setPixel(_xs[i], _ys[i], _colors[i]);
      }
    }
    _logger.info('Pixel values set. Duration/ms: ${sw.elapsedMilliseconds}');
    sw.reset();

    String autoFileName = "${new DateTime.now()}"
        "_${areaX.min},${areaX.max}_${areaY.min},${areaY.max}.png";
    String filePath = _computeFilePath(autoFileName);
    _writeImageSync(filePath, image);
    _logger
        .info('Image written to file. Duration/ms: ${sw.elapsedMilliseconds}');
  }

  void _writeImageSync(String filePath, Image image) {
    var file = new io.File(filePath)..createSync(recursive: true);
    file.writeAsBytesSync(encodePng(image));
  }

  /// Compute a file path, using the supplied automatic name unless it is
  /// overridden
  String _computeFilePath(String autoFileName) {
    String filePath = _outputFolder;
    if (_outputFilename == null) {
      filePath = filePath + autoFileName;
    } else {
      filePath = filePath + _outputFilename;
    }
    return filePath;
  }

  /// Applies the transforms to the stored data points.
  /// It modifies the data point values, so no more data should be added after
  /// calling this method.
  /// TODO(mariana): Enforce this (e.g. add a flag on the class that fails the add calls).
  void _applyTransforms() {
    // Apply the transforms only once. This allows for multiple render calls but
    // a single transforms application phase.
    if (_transformsApplied == false) return;
    _transformsApplied = true;
    // Go through data transforms first and apply them to every point.
    for (DataTransformFunction transform in _dataTransforms) {
      List<num> newXs = [];
      List<num> newYs = [];
      List<Map> newDataList = [];
      Range newXRange = new Range(double.INFINITY, double.NEGATIVE_INFINITY);
      Range newYRange = new Range(double.INFINITY, double.NEGATIVE_INFINITY);
      Range newValueRange =
          new Range(double.INFINITY, double.NEGATIVE_INFINITY);

      for (int i = 0; i < _xs.length; i++) {
        List result =
            transform(_xs[i], _ys[i], _dataList[i], _xRange, _yRange, _valueRange);

        newXs.add(result[0]);
        newYs.add(result[1]);
        newDataList.add(result[2]);

        // Adjust the ranges for the data.
        newXRange.min = math.min(newXRange.min, result[0]);
        newXRange.max = math.max(newXRange.max, result[0]);

        newYRange.min = math.min(newYRange.min, result[1]);
        newYRange.max = math.max(newYRange.max, result[1]);

        newValueRange.min = math.min(newValueRange.min, result[2]);
        newValueRange.max = math.max(newValueRange.max, result[2]);
      }
      _xs = newXs;
      _ys = newYs;
      _dataList = newDataList;
      _xRange = newXRange;
      _yRange = newYRange;
      _valueRange = newValueRange;
    }

    // Apply the color transform.
    if (_colorTransform != null) {
      for (int i = 0; i < _xs.length; i++) {
        num color = _colorTransform(
            _xs[i], _ys[i], _dataList[i], _xRange, _yRange, _valueRange);
        _colors.add(color);
      }
    } else {
      for (int i = 0; i < _xs.length; i++) {
        _colors.add(Color.fromRgb(0, 0, 0));
      }
    }
  }
}
