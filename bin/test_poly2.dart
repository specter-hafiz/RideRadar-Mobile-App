import 'package:shuttletrack/core/services/directions_service.dart';
import 'dart:math';

void main() {
  String encoded = r"ytvg@x}pH?jBGt@_BPyAAqACwBUwA_@eAk@_GkDiHgEw@q@UW_@u@eAiDyAuFMWYSaF{AwDgAyCs@mCw@H{BJ_@t@qAp@uAL_@Lk@?m@Ey@yAy@yA_AcCqAe@Yg@M[EsAO}@GE?D?|@F`@DlANf@LIkA@cAPsDTqCZsCD]DMf@o@PMZEpAXb@@JAPMP]DeCAyBBi@\iBTg@^m@fAaBPOXKjF]dEKp@Gx@K";
  
  var points = DirectionsService.decodePolyline(encoded);
  double maxLat = points.map((p) => p[0]).reduce(max);
  print("Max Lat in polyline: $maxLat");
  print("Gaza Stop Lat: 6.687602");
}
