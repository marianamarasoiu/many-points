/// The visualise library.
library many_points;

import 'package:image/image.dart';
import 'dart:math' as math;
import 'dart:io' as io;
import 'package:logging/logging.dart' as logging;
import 'dart:convert' show JSON;

export 'package:image/image.dart' show Color;
part 'src/visualisation.dart';
part 'src/range.dart';

/// Returns [num x, num y, num value]
/// TODO(mariana): Explore using a const class instead of a List.
typedef List DataTransformFunction(
    int x, int y, num value, Range xRange, Range yRange, Range valueRange);

/// Returns the color of the point
typedef int ColorTransformFunction(
    int x, int y, num value, Range xRange, Range yRange, Range valueRange);
