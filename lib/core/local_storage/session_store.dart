import 'package:hive_ce/hive.dart';

/// Small key-value session store. Hive is the app implementation; tests use memory.
abstract class SessionStore {
  Object? read(String key, {Object? defaultValue});

  Future<void> write(String key, Object? value);

  Future<void> clear();
}

class MemorySessionStore implements SessionStore {
  final Map<String, Object?> _values = {};

  @override
  Object? read(String key, {Object? defaultValue}) {
    return _values.containsKey(key) ? _values[key] : defaultValue;
  }

  @override
  Future<void> write(String key, Object? value) async {
    _values[key] = value;
  }

  @override
  Future<void> clear() async {
    _values.clear();
  }
}

class HiveSessionStore implements SessionStore {
  HiveSessionStore(this._box);

  final Box<dynamic> _box;

  @override
  Object? read(String key, {Object? defaultValue}) {
    return _box.get(key, defaultValue: defaultValue);
  }

  @override
  Future<void> write(String key, Object? value) {
    return _box.put(key, value);
  }

  @override
  Future<void> clear() async {
    await _box.clear();
  }
}
