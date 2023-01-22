// ignore_for_file: cancel_subscriptions

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:mozersubtitlebot/features/console/std.dart';
import 'package:mozersubtitlebot/features/subtitles/frame_rate.dart';
import 'package:mozersubtitlebot/features/subtitles/subs.dart';
import 'package:mozersubtitlebot/features/subtitles/timecode.dart';
import 'package:mozersubtitlebot/features/telegram_bot/command.dart';
import 'package:teledart/model.dart' as tg;
import 'package:teledart/teledart.dart';
import 'package:teledart/telegram.dart';
import 'package:uuid/uuid.dart';

// TODO(mozerrr): поддержка utf8 [???] вроде работает
// TODO(mozerrr): поддержку других форматов субтитров
// TODO(mozerrr): поддержку задержки
class SubtitleBot {
  bool get isRunning => teleDart != null && _token != null;

  tg.BotCommand get helpCommand => tg.BotCommand(
        command: 'help',
        description: 'Информация о боте',
      );

  tg.BotCommand get convertCommand => tg.BotCommand(
        command: 'convert',
        description: 'Конвертация',
      );

  String get convertHelpDescription =>
      'convert {fps файла} {fps необходимый}\n|convert {fps файла} | - $defaultFrameRate - по умолчанию';

  static String get name => 'mozer subtitle bot';
  TeleDart? teleDart;
  String? _token;

  StreamSubscription<tg.TeleDartMessage>? _helpSubscription;
  StreamSubscription<tg.TeleDartMessage>? _convertSubscription;
  StreamSubscription<tg.TeleDartMessage>? _convertCommandSubscription;

  Future<void> launch(String token) async {
    if (isRunning) await terminate();
    await start(token);
    await setupCommands();
  }

  Future<void> start(String token) async {
    printLog('start');
    if (isRunning) {
      throw Exception('was called before terminating last session');
    }
    _token = token;
    teleDart = TeleDart(_token!, Event(name));
    teleDart?.start();
    final user = await Telegram(_token!).getMe();
    printLog('${user.username} is initialized');
  }

  Future<void> setupCommands() async {
    printLog('setup commands');
    _helpSubscription =
        teleDart?.onCommand(helpCommand.command).listen(_onHelp);

    _convertSubscription =
        teleDart?.onCommand(convertCommand.command).listen(_onHelp);

    _convertCommandSubscription = teleDart
        ?.onMessage(keyword: convertCommand.command)
        .listen(_onConvertCommand);

    await teleDart?.setMyCommands([
      helpCommand,
      convertCommand,
    ]);
  }

  Future<void> terminate() async {
    printLog('try terminate');
    final successful = (await teleDart?.close()) ?? true;
    if (!successful) throw Exception('Cant close connection.');

    await Future.wait([
      if (_helpSubscription != null) _helpSubscription!.cancel(),
      if (_convertSubscription != null) _convertSubscription!.cancel(),
      if (_convertCommandSubscription != null)
        _convertCommandSubscription!.cancel(),
    ]);
    teleDart = null;
    _token = null;
    _helpSubscription = null;
    _convertSubscription = null;
    _convertCommandSubscription = null;
  }

  Future<void> _onHelp(tg.TeleDartMessage message) async {
    await teleDart?.sendMessage(
      message.chat.id,
      convertHelpDescription,
    );
  }

  FutureOr<void> _onConvertCommand(tg.TeleDartMessage message) async {
    final rawCommand = message.caption?.split(' ');
    final id = Uuid().v4();
    final fileName = message.document?.fileName;
    final subSavePath = './download/$id';
    final fixedSubSavePath = './download/Fixed $fileName';
    try {
      if (fileName != null && rawCommand != null) {
        final commandParams = ConvertCommand.parse(rawCommand)!;
        final tempId = message.document!.fileId;
        final file = await teleDart!.getFile(tempId);
        final sub = await _downloadSubtitle(file.filePath!, subSavePath);
        final renamedSub = await sub.rename(fixedSubSavePath);
        final contents = await renamedSub.readAsString(encoding: latin1);
        final fixedString = Subs().parseSubtitle(
          contents,
          TimeCode.frameRateDifferenceMultiplier(
            commandParams.originalFrameRate,
            commandParams.targetFrameRate,
          ),
        );
        await renamedSub.writeAsString(fixedString, encoding: latin1);
        await teleDart?.sendDocument(message.chat.id, renamedSub);
        printLog('Изменение $id успешно завершено');
      } else {
        await teleDart?.sendMessage(
          message.chat.id,
          'Упс. Что-то пошло не так. Возможно не прикреплены субтитры.',
        );
      }
    } on LengthException catch (e) {
      await teleDart?.sendMessage(message.chat.id, e.message);
    } on NotDoubleException catch (e) {
      await teleDart?.sendMessage(message.chat.id, e.message);
    } on DioError catch (e, s) {
      printException(e, s);
      await teleDart?.sendMessage(
        message.chat.id,
        'Ошибка интернет соединения. Попробуйте еще раз.',
      );
    // ignore: avoid_catching_errors
    } on ArgumentError catch (e, s) {
      printException(e, s, 'ArgumentError');
      await teleDart?.sendMessage(
        message.chat.id,
        'Упс. Что-то пошло не так. Возможно неправильно введена команда.',
      );
    } on Exception catch (e, s) {
      printException(e, s);
      await teleDart?.sendMessage(
        message.chat.id,
        'Упс. Что-то пошло не так.\n$e',
      );
    } finally {
      final oldSub = File(subSavePath);
      if (oldSub.existsSync()) oldSub.deleteSync();

      final fixedSub = File(fixedSubSavePath);
      if (fixedSub.existsSync()) fixedSub.deleteSync();
    }
  }

  Future<File> _downloadSubtitle(String fileId, String savePath) async {
    assert(_token != null);
    await Dio().download(
      'https://api.telegram.org/file/bot$_token/$fileId',
      savePath,
      options: Options(responseType: ResponseType.plain),
    );
    return File(savePath);
  }
}
