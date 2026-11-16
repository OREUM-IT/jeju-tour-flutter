import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';

class TripStore extends ChangeNotifier {
  TripStore(this.preferences) {
    _load();
  }
  final SharedPreferences preferences;
  static const key = 'oreum.flutter.saved.v1';
  List<SavedItem> _items = [];
  List<SavedItem> get items => List.unmodifiable(_items);
  void _load() {
    try {
      _items = objects(
        jsonDecode(preferences.getString(key) ?? '[]'),
      ).map(SavedItem.fromJson).toList();
    } on FormatException {
      _items = [];
    }
  }

  Future<SavedItem> save(String title, String kind, Json data) async {
    final now = DateTime.now();
    final item = SavedItem(
      id: '${now.microsecondsSinceEpoch}',
      title: title,
      kind: kind,
      data: data,
      savedAt: now,
    );
    await _persist([item, ..._items]);
    return item;
  }

  Future<void> remove(String id) =>
      _persist(_items.where((i) => i.id != id).toList());
  Future<void> restore(SavedItem item) =>
      _persist([item, ..._items.where((i) => i.id != item.id)]);
  Future<void> _persist(List<SavedItem> updated) async {
    final ok = await preferences.setString(
      key,
      jsonEncode(updated.map((e) => e.toJson()).toList()),
    );
    if (!ok) throw StateError('저장 공간을 확인해 주세요.');
    _items = updated;
    notifyListeners();
  }
}
