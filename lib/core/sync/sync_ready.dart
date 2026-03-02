abstract class LocalDataSource<T> {
  Future<List<T>> getAll();
  Future<T?> getById(String id);
  Future<void> save(T item);
  Future<void> delete(String id);
}

abstract class RemoteDataSource<T> {
  Future<List<T>> search(String query, {Map<String, dynamic>? params});
  Future<T> getDetails(String id);
}

class SyncManager {
  // Placeholder for future sync logic
  Future<void> sync() async {
    // TODO: Implement sync logic
  }
}
