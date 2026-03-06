typedef CsvDropCallback =
    Future<void> Function(String fileName, String content);
typedef ShouldAcceptDropCallback = bool Function(double x, double y);

typedef DropErrorCallback = void Function(String message);

class WebDropHandler {
  WebDropHandler({
    required this.onHover,
    required this.onLeave,
    required this.onCsvDropped,
    required this.shouldAcceptDrop,
    required this.onError,
  });

  final void Function() onHover;
  final void Function() onLeave;
  final CsvDropCallback onCsvDropped;
  final ShouldAcceptDropCallback shouldAcceptDrop;
  final DropErrorCallback onError;

  void attach() {}

  void dispose() {}
}
