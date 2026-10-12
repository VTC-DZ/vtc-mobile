/// Reads a loosely typed JSON object as a flat `string → string` map, the
/// shape of notification `data` in inbox items, FCM messages and
/// local-notification payloads. Anything that isn't a map reads as empty.
///
/// The server promises string values, but a number or bool slipping through
/// must not drop the whole item. A `null` value is skipped rather than turned
/// into the string `"null"`, which a lookup would take for a real id.
Map<String, String> asStringMap(Object? raw) => raw is Map
    ? {
        for (final entry in raw.entries)
          if (entry.value != null) entry.key.toString(): entry.value.toString(),
      }
    : const {};
