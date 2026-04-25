sealed class DocumentPickResult {
  const DocumentPickResult();
}

final class DocumentPickCancelled extends DocumentPickResult {
  const DocumentPickCancelled();
}

final class DocumentPickSuccess extends DocumentPickResult {
  const DocumentPickSuccess({required this.path, required this.name});

  final String path;
  final String name;
}

final class DocumentPickFailure extends DocumentPickResult {
  const DocumentPickFailure({required this.errorMessage});

  final String errorMessage;
}
