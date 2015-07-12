part of many_points;

logging.Logger _logger = new logging.Logger('Visualisation');
bool isLoggingInitialized = false;

_initLogging(bool enableLogging) {
  logging.hierarchicalLoggingEnabled = true;
  _logger.level = enableLogging ? logging.Level.ALL : logging.Level.OFF;
  if (!isLoggingInitialized) {
    _logger.onRecord.listen((logging.LogRecord rec) {
      print('${rec.level.name}: ${rec.time}: ${rec.message}');
    });
  }
  isLoggingInitialized = true;
}

class Visualisation {
  /// The output folder path for the resulting PNG image.
  String imageOutputFolder = "output/image/";

  /// The output PNG image name.
  String imageOutputFileName;

  /// The output folder path for the resulting data dump in JSON format.
  String dataOutputFolder = "output/freckl/";

  /// The output JSON data file name.
  String dataOutputFileName;

  List<DataTransformFunction> _dataTransforms = [];
  ColorTransformFunction _colorTransform;
  List<int> _xList = [];
  List<int> _yList = [];
  List<num> _valueList = [];
  List<Map> _dataList = [];
  List<int> _colorList = [];
  Range _xRange;
  Range _yRange;
  Range _valueRange;
  bool _transformsApplied = false;

  Visualisation([bool enableLogging = true]) {
    _xRange = new Range(double.INFINITY, double.NEGATIVE_INFINITY);
    _yRange = new Range(double.INFINITY, double.NEGATIVE_INFINITY);
    _valueRange = new Range(double.INFINITY, double.NEGATIVE_INFINITY);
    _initLogging(enableLogging);
  }

  /// Add a data point defined by the [x] and [y] coordinates and its [value].
  /// [data] is a Map used to store other information about the point.
  void addData(int x, int y, num value, Map data) {
    assert(x != null);
    assert(y != null);
    assert(value != null);
    assert(data != null);

    _xList.add(x);
    _yList.add(y);
    _valueList.add(value);
    _dataList.add(data);

    // Adjust the ranges for the data.
    _xRange.min = math.min(_xRange.min, x);
    _xRange.max = math.max(_xRange.max, x);

    _yRange.min = math.min(_yRange.min, y);
    _yRange.max = math.max(_yRange.max, y);

    _valueRange.min = math.min(_valueRange.min, value);
    _valueRange.max = math.max(_valueRange.max, value);
  }

  /// Appends the data points defined by the coordinate lists [xIterable] and
  /// [yIterable] and the data lists [valueIterable] and [dataList].
  void addAllDataPoints(Iterable<int> xIterable, Iterable<int> yIterable,
      Iterable<num> valueIterable, Iterable<Map> dataIterable) {
    Iterator x = xIterable.iterator;
    Iterator y = yIterable.iterator;
    Iterator value = valueIterable.iterator;
    Iterator data = dataIterable.iterator;
    while (x.moveNext() && y.moveNext() && data.moveNext()) {
      addData(x.current, y.current, value.current, data.current);
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

    for (int i = 0; i < _xList.length; i++) {
      image.setPixel(_xList[i] - _xRange.min, _yList[i] - _yRange.min, _colorList[i]);
    }
    _logger.info('Pixel values set. Duration/ms: ${sw.elapsedMilliseconds}');
    sw.reset();

    if (width != -1) {
      image = copyResize(image, width, height, NEAREST);
      _logger.info('Image resized. Duration/ms: ${sw.elapsedMilliseconds}');
      sw.reset();
    }

    // Writing the image.
    String imageFilePath = _computeFilePath("${new DateTime.now()}.png", false);
    _writeImageSync(imageFilePath, image);
    _logger
        .info('Image written to file. Duration/ms: ${sw.elapsedMilliseconds}');
    sw.reset();

    // Writing the data dump.
    String dataFilePath = _computeFilePath("${new DateTime.now()}.freckl", true);
    List data = _buildDataPointList();
    _writeDataSync(dataFilePath, data);
    _logger
        .info('Data written to file. Duration/ms: ${sw.elapsedMilliseconds}');
  }

  void render_SCALING_HACK(num width, num height) {
    Stopwatch sw = new Stopwatch()..start();
    _applyTransforms();
    _logger.info('Transforms applied. Duration/ms: ${sw.elapsedMilliseconds}');
    sw.reset();

    int w = (_xRange.max - _xRange.min).ceil() + 1;
    int h = (_yRange.max - _yRange.min).ceil() + 1;
    Image image = new Image(width, height);

    for (int i = 0; i < _xList.length; i++) {
      image.setPixel((((_xList[i] - _xRange.min) / w) * width).floor(),
          (((_yList[i] - _yRange.min) / h) * height).floor(), _colorList[i]);
    }
    _logger.info('Pixel values set. Duration/ms: ${sw.elapsedMilliseconds}');
    sw.reset();

//    if (width != -1) {
//      image = copyResize(image, width, height, NEAREST);
//    }

    // Writing the image.
    String imageFilePath = _computeFilePath("${new DateTime.now()}.png", false);
    _writeImageSync(imageFilePath, image);
    _logger
        .info('Image written to file. Duration/ms: ${sw.elapsedMilliseconds}');
    sw.reset();

    // Writing the data dump.
    String dataFilePath = _computeFilePath("${new DateTime.now()}.freckl", true);
    List data = _buildDataPointList();
    _writeDataSync(dataFilePath, data);
    _logger
        .info('Data written to file. Duration/ms: ${sw.elapsedMilliseconds}');
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
    for (int i = 0; i < _xList.length; i++) {
      if (areaX.min <= _xList[i] &&
          _xList[i] <= areaY.max &&
          areaY.min <= _yList[i] &&
          _yList[i] <= areaY.max) {
        image.setPixel(_xList[i], _yList[i], _colorList[i]);
      }
    }
    _logger.info('Pixel values set. Duration/ms: ${sw.elapsedMilliseconds}');
    sw.reset();

    String autoFileName = "${new DateTime.now()}"
        "_${areaX.min},${areaX.max}_${areaY.min},${areaY.max}";

    // Writing the image.
    String imageFileName = autoFileName + '.png';
    String imageFilePath = _computeFilePath(imageFileName, false);
    _writeImageSync(imageFilePath, image);
    _logger
        .info('Image written to file. Duration/ms: ${sw.elapsedMilliseconds}');
    sw.reset();

    // Writing the data dump.
    String dataFileName = autoFileName + '.freckl';
    String dataFilePath = _computeFilePath(dataFileName, true);
    List data = _buildDataPointList();
    _writeDataSync(dataFilePath, data);
    _logger
        .info('Data written to file. Duration/ms: ${sw.elapsedMilliseconds}');
  }

  void _writeImageSync(String filePath, Image image) {
    var file = new io.File(filePath)..createSync(recursive: true);
    file.writeAsBytesSync(encodePng(image));
  }

  void _writeDataSync(String filePath, List data) {
    var file = new io.File(filePath)..createSync(recursive: true);
    file.writeAsStringSync(JSON.encode(data));
  }

  List _buildDataPointList() {
    List result = [];
    for (int i = 0; i < _xList.length; i++) {
      Map data = {
        'point': [_xList[i], _yList[i]],
        'value': _valueList[i],
        'color': _colorList[i]
      };
      data.addAll(_dataList[i]);
      result.add(data);
    }
    return result;
  }
  /// Compute a file path, using the supplied automatic name unless it is
  /// overridden. If [dataOutput] is true, then the path is the data files,
  /// otherwise for image files.
  String _computeFilePath(String autoFileName, bool dataOutput) {
    String filePath = dataOutput ? dataOutputFolder : imageOutputFolder;
    String outputFileName =
        dataOutput ? dataOutputFileName : imageOutputFileName;
    if (outputFileName == null) {
      filePath = filePath + autoFileName;
    } else {
      filePath = filePath + outputFileName;
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
    if (_transformsApplied) {
      return;
    }
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

      for (int i = 0; i < _xList.length; i++) {
        List result = transform(
            _xList[i], _yList[i], _valueList[i], _xRange, _yRange, _valueRange);

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
      _xList = newXs;
      _yList = newYs;
      _dataList = newDataList;
      _xRange = newXRange;
      _yRange = newYRange;
      _valueRange = newValueRange;
    }

    // Apply the color transform.
    if (_colorTransform != null) {
      for (int i = 0; i < _xList.length; i++) {
        num color = _colorTransform(
            _xList[i], _yList[i], _valueList[i], _xRange, _yRange, _valueRange);
        _colorList.add(color);
      }
    } else {
      for (int i = 0; i < _xList.length; i++) {
        _colorList.add(Color.fromRgb(0, 0, 0));
      }
    }
  }
}
