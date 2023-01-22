import 'dart:io';

/// Выводит информацию об ошибке в консоль.
void printException([
  Object? object = '',
  StackTrace? stackTrace,
  String? source,
]) {
  final message =
      object != null ? '[Exception](${DateTime.now()}):\n$object' : object;
  stderr.writeln(message);
  if (source != null) stderr.writeln('source: $source');
  if (source != null) stderr.writeln(stackTrace);
}

/// Выводит логи в консоль.
void printLog([Object? object = '']) {
  stdout.writeln('[Log](${DateTime.now()}): $object');
}
