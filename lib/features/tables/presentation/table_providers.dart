import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/table_repository.dart';
import '../domain/models/table_model.dart';

final tableRepositoryProvider = Provider<FirestoreTableRepositoryImpl>((ref) {
  return FirestoreTableRepositoryImpl();
});

final tableListProvider = FutureProvider<List<TableModel>>((ref) async {
  final repository = ref.watch(tableRepositoryProvider);
  return repository.fetchTables();
});
