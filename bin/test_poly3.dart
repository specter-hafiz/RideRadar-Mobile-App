import 'package:shuttletrack/core/services/directions_service.dart';

void main() {
  // Same string but WITHOUT the backslash at BBi@\iBTg
  String encoded = "ytvg@x}pH?jBGt@_BPyAAqACwBUwA_@eAk@_GkDiHgEw@q@UW_@u@eAiDyAuFMWYSaF{AwDgAyCs@mCw@H{BJ_@t@qAp@uAL_@Lk@?m@Ey@yAy@yA_AcCqAe@Yg@M[EsAO}@GE?D?|@F`@DlANf@LIkA@cAPsDTqCZsCD]DMf@o@PMZEpAXb@@JAPMP]DeCAyBBi@iBTg@^m@fAaBPOXKjF]dEKp@Gx@K";
  
  var points = DirectionsService.decodePolyline(encoded);
  print("Decoded ${points.length} points");
  print("First: ${points.first}");
  print("Last: ${points.last}");
}
