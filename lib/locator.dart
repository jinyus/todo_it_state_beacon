import 'package:flutter/widgets.dart' show WidgetsFlutterBinding;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:state_beacon/state_beacon.dart';
import 'package:todoit/features/todos/models/todo_dto.dart';

import 'services/storage/hive_storage_service.dart';
import 'features/todos/managers/todo_manager.dart';

late final ScopedRef<HiveStorageService>
hiveStorageServiceRef; // = Ref.scoped((_) => HiveStorageService());
final todoManagerRef = Ref.scoped(
  (ctx) => TodoManager(hiveStorageServiceRef.read(ctx)),
);

Future<void> startUp() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();

  // Register Hive adapters
  Hive.registerAdapter(TodoDTOAdapter());

  final hiveService = HiveStorageService();
  await hiveService.init();

  hiveStorageServiceRef = Ref.scoped((_) => hiveService);
}
