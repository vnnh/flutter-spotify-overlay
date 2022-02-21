import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

//https://github.com/flutter/flutter/issues/12990#issuecomment-808789897
ColorFilter tintMatrix({
  Color tintColor = Colors.grey,
  double scale = 1,
}) {
  final int r = tintColor.red;
  final int g = tintColor.green;
  final int b = tintColor.blue;

  final double rTint = r / 255;
  final double gTint = g / 255;
  final double bTint = b / 255;

  final double rL = 0.2126;
  final double gL = 0.7152;
  final double bL = 0.0722;

  final double translate = 1 - scale * 0.5;

  return ColorFilter.matrix(<double>[
    (rL * rTint * scale),
    (gL * rTint * scale),
    (bL * rTint * scale),
    (0),
    (r * translate),
    (rL * gTint * scale),
    (gL * gTint * scale),
    (bL * gTint * scale),
    (0),
    (g * translate),
    (rL * bTint * scale),
    (gL * bTint * scale),
    (bL * bTint * scale),
    (0),
    (b * translate),
    (0),
    (0),
    (0),
    (1),
    (0),
  ]);
}
