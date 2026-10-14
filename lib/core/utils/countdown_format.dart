/// A countdown of [seconds] as `mm:ss`, e.g. `90` → `01:30`.
String formatMmSs(int seconds) {
  final minutes = seconds ~/ 60;
  final rest = seconds % 60;
  return '${minutes.toString().padLeft(2, '0')}:'
      '${rest.toString().padLeft(2, '0')}';
}
