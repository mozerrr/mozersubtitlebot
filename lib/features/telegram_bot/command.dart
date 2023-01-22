import 'package:args/args.dart';
import 'package:mozersubtitlebot/features/subtitles/frame_rate.dart';
import 'package:mozersubtitlebot/features/utils/dev.dart';

class ConvertCommand {
  const ConvertCommand();

  static ConvertCommandResult? parse(
    List<String> args, {
    bool throwException = true,
  }) {
    final results = ArgParser().parse(args);
    if (results.rest.first != name) {
      return throwOrNull(
        FormatException(
          "args doesn't contain $name command",
          _argsToCommand(results.arguments),
        ),
        throwException,
      );
    }

    // Убираем из результатов название команды оставляя только параметры.
    final restParams = results.rest.sublist(1);
    if (restParams.length != 2) {
      return throwOrNull(
        FormatException(
          'command not support ${restParams.length} args',
          _argsToCommand(results.rest),
        ),
        throwException,
      );
    }
    final originalFrameRate = parseFrameRate(restParams.first);
    final targetFrameRate = parseFrameRate(restParams.last);

    if (originalFrameRate == null) {
      return throwOrNull(
        FormatException('originalFrameRate not parsed', originalFrameRate),
        throwException,
      );
    }
    if (targetFrameRate == null) {
      return throwOrNull(
        FormatException('targetFrameRate not parsed', targetFrameRate),
        throwException,
      );
    }

    return ConvertCommandResult(
      originalFrameRate: originalFrameRate,
      targetFrameRate: targetFrameRate,
    );
  }

  static String _argsToCommand(Iterable<String> args) {
    return args.join(' ');
  }

  static String get name => 'convert';
}

class ConvertCommandResult {
  const ConvertCommandResult({
    required this.originalFrameRate,
    required this.targetFrameRate,
  });

  final double originalFrameRate;
  final double targetFrameRate;
}
