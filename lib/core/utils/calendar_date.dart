// Formatting for calendar dates — values with no time of day, such as birth
// dates and licence or insurance expiries. (Timestamps from the API are
// formatted by `features/ride/shared/utils/date_formatter.dart`.)

/// `yyyy-MM-dd`, the `format: date` the API expects.
String toApiDate(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${_twoDigits(date.month)}-'
    '${_twoDigits(date.day)}';

/// `dd/MM/yyyy`, how dates are shown in forms.
String toDisplayDate(DateTime date) =>
    '${_twoDigits(date.day)}/${_twoDigits(date.month)}/${date.year}';

String _twoDigits(int value) => value.toString().padLeft(2, '0');
