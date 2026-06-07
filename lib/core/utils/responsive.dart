import 'package:flutter/widgets.dart';

double rs(BuildContext context, double value) {
  final size = MediaQuery.of(context).size.shortestSide;
  // Base design width (shortestSide) is ~380; scale proportionally
  return value * (size / 380.0);
}

double rw(BuildContext context, double value) {
  final width = MediaQuery.of(context).size.width;
  return value * (width / 390.0);
}

double rh(BuildContext context, double value) {
  final height = MediaQuery.of(context).size.height;
  return value * (height / 844.0);
}
