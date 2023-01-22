import 'dart:io';

import 'package:mozersubtitlebot/features/console/std.dart';
import 'package:mozersubtitlebot/features/telegram_bot/telegram.dart';

void main(List<String> args) async {
  if (args.isEmpty) {
    printException("Token wasn't provided.");
    exit(1);
  }
  final token = args.first;
  final bot = SubtitleBot();
  try {
    await bot.launch(token);
    printLog('bot is launched');
  } on Exception catch (e) {
    printException(e);
    await bot.terminate();
    exit(2);
  }
}
