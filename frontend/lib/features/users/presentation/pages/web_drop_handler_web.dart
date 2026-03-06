import 'dart:async';

import 'package:universal_html/html.dart' as html;
import 'package:frontend/constants/texts/texts_csv_drop.dart';

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

  StreamSubscription<html.MouseEvent>? _dragOverSub;
  StreamSubscription<html.MouseEvent>? _dragLeaveSub;
  StreamSubscription<html.MouseEvent>? _dropSub;

  void attach() {
    _dragOverSub = html.document.onDragOver.listen((event) {
      event.preventDefault();
      if (shouldAcceptDrop(
        event.client.x.toDouble(),
        event.client.y.toDouble(),
      )) {
        onHover();
      } else {
        onLeave();
      }
    });

    _dragLeaveSub = html.document.onDragLeave.listen((event) {
      event.preventDefault();
      onLeave();
    });

    _dropSub = html.document.onDrop.listen((event) async {
      event.preventDefault();

      final isInsideZone = shouldAcceptDrop(
        event.client.x.toDouble(),
        event.client.y.toDouble(),
      );
      onLeave();

      if (!isInsideZone) {
        return;
      }

      final files = event.dataTransfer?.files;
      if (files == null || files.isEmpty) {
        return;
      }

      final file = files.first;
      final fileName = file.name;
      if (!fileName.toLowerCase().endsWith('.csv')) {
        onError(CsvDropTexts.onlyCsvDrop);
        return;
      }

      final reader = html.FileReader();
      final completer = Completer<String>();

      reader.onLoadEnd.listen((_) {
        final result = reader.result;
        if (result is String) {
          completer.complete(result);
          return;
        }
        completer.completeError(Exception(CsvDropTexts.unreadableFile));
      });

      reader.onError.listen((_) {
            completer.completeError(
              Exception(CsvDropTexts.dropReadFailed),
            );
      });

      reader.readAsText(file, 'utf-8');

      try {
        final content = await completer.future;
        await onCsvDropped(fileName, content);
      } catch (_) {
            onError(CsvDropTexts.dropReadFailed);
      }
    });
  }

  void dispose() {
    _dragOverSub?.cancel();
    _dragLeaveSub?.cancel();
    _dropSub?.cancel();
  }
}
