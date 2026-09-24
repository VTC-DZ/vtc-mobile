import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';

/// Gesture recognizers handed to every [GoogleMap] in the app.
///
/// A map is a platform view: without this, Flutter's gesture arena awards
/// pan/drag gestures to the surrounding widgets (the `Stack`s the maps sit in,
/// and the `DraggableScrollableSheet` on the active-ride screens), so the map
/// never pans. [EagerGestureRecognizer] claims the gesture immediately.
final Set<Factory<OneSequenceGestureRecognizer>> mapGestureRecognizers = {
  const Factory<OneSequenceGestureRecognizer>(EagerGestureRecognizer.new),
};
