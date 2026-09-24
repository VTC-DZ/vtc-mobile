import 'dart:math';

final _rng = Random.secure();

/// RFC 4122 v4 UUID — no external package required.
String uuidV4() {
  final b = List<int>.generate(16, (_) => _rng.nextInt(256));
  b[6] = (b[6] & 0x0f) | 0x40;
  b[8] = (b[8] & 0x3f) | 0x80;
  String h(int n) => n.toRadixString(16).padLeft(2, '0');
  return '${b.sublist(0, 4).map(h).join()}'
      '-${b.sublist(4, 6).map(h).join()}'
      '-${b.sublist(6, 8).map(h).join()}'
      '-${b.sublist(8, 10).map(h).join()}'
      '-${b.sublist(10, 16).map(h).join()}';
}
