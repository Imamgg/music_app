import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/offline_repository.dart';

final offlineProvider = ChangeNotifierProvider<OfflineRepository>(
  (ref) => OfflineRepository(),
);
