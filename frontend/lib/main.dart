import 'package:sofawatch/app/app.dart';
import 'package:sofawatch/app/bootstrap.dart';

Future<void> main() async {
  await bootstrap((data) => SofaWatchApp(bootstrapData: data));
}
