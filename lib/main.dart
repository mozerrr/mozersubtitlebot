import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:teledart/teledart.dart';
import 'package:teledart/telegram.dart';
import 'package:teledart/model.dart' as TG;

main() {
 final String token = '1219961163:AAG7SlVIaMiSTY9F5SU_KTB_0T6bcOB2VGo';

 TeleDart teledart = TeleDart(Telegram(token), Event());
 Dio dio = Dio();
 teledart.start().then((me) => print('${me.username} is initialised'));

 //TODO добавить интерфейс
 //TODO поддержка utf8
 //TODO других форматов субтитров
 teledart
   .onMessage(keyword: 'convert')
   .listen((message) async {
     if (message.document != null) {
       String fileName = message.document.file_name;
       //await teledart.telegram.deleteMessage(message.chat.id, message.message_id);
       print('save');
       String fileID = message.document.file_id;
       //bool wasError = false;
       try {
         final TG.File tempSub = await teledart.telegram.getFile(fileID);
         await dio.download(
             "https://api.telegram.org/file/bot$token/${tempSub.file_path}",
             './download/$fileName',
             options: Options(responseType: ResponseType.plain)
         );
         File sub = await File('./download/$fileName');
         await sub.rename('./download/Fixed $fileName');
         sub = await File('./download/Fixed $fileName');
         String contents = await sub.readAsString(encoding: Encoding.getByName('latin1'));
         String fixedString = Sub.parseSubtitle(contents, Command.parse(message.caption));
         await sub.writeAsString(fixedString, encoding: Encoding.getByName('latin1'));
         await teledart.telegram.sendDocument(message.chat.id, sub);
       }
       on LengthException catch (e) {
         await teledart.telegram.sendMessage(message.chat.id, e.errorMessage());
       }
       on NotDoubleException catch (e) {
         await teledart.telegram.sendMessage(message.chat.id, e.errorMessage());
       }
       catch (e) {
         //wasError = true;
         await teledart.telegram.sendMessage(message.chat.id, 'Упс. Что-то пошло не так.');
       }
     }
     else {
       await teledart.telegram.sendMessage(message.chat.id,
           'Упс. Что-то пошло не так. Возможно не прикреплены субтитры.'
       );
     }
   }
 );
}

class Command {
  double originalFPS;
  double targetFPS;

  Command(double original, double target)
  {
    originalFPS = original;
    targetFPS = target;
  }

  static Command parse(String commandString) {
    var temp = commandString.split(' ');
    //print(temp);
    if (temp.length == 2) {
      temp.add('23.976');
    }
    else if (temp.length != 3) {
      throw LengthException();
    }
    var original = double.tryParse(temp[1].replaceFirst(',', '.'));
    var target = double.tryParse(temp[2].replaceFirst(',', '.'));

    if (original is double && target is double) {
      return Command(original, target);
    }
    else throw NotDoubleException();
  }
}

class Sub {

  static String parseSubtitle(String subtitle, Command command) {
    var temp = subtitle.split('\r\n');
    String newFile = '';
    for (String i in temp) {
      if (i.contains(' --> ')) {
        newFile+= "${parseTimecode(i, _multiply(command))}\r\n";
      } else {
        newFile+= '$i\r\n';
      }
    }
    return newFile;
  }

  //1
  // 00:00:11,820 --> 00:00:18,771
  // Когда я был мальчиком, луна была жемчужной,
  // а солнце - золотым.

  static String parseTimecode(String timecode, double multiplier) {
    var temp = timecode.split(' --> ');
    var timecode1 = parseFromTimecode(temp[0]);
    var timecode2 = parseFromTimecode(temp[1]);
    timecode1 *= multiplier;
    timecode2 *= multiplier;
    return '${parseToTimecode(timecode1)} --> ${parseToTimecode(timecode2)}';
  }

  static double parseFromTimecode(String timecode) {
    var temp = timecode.split(':');
    int hours = int.tryParse(temp[0]);
    int minutes = int.tryParse(temp[1]);
    double seconds = double.tryParse(temp[2].replaceFirst(',', '.'));
    double number = hours * 3600 + minutes * 60 + seconds;
    return number;
  }

  static String parseToTimecode(double number) {
    int hours = number ~/ 3600;
    int minutes = ((number * 1000 ~/ 1000) - (hours * 3600)) ~/ 60;
    int tempNumber = hours * 3600 + minutes * 60;
    double seconds = number - tempNumber;
    String hoursCode = toCode(hours.toString());
    String minutesCode = toCode(minutes.toString());
    String secondsCode = toCode((seconds * 1000 ~/ 1000).toString());
    String thousands = seconds.toStringAsFixed(3).split('.')[1];
    String timecode = '$hoursCode:$minutesCode:$secondsCode,$thousands';

    //print(timecode);
    return timecode;
  }

  static String toCode(String number) {
    if (number.length == 1) {
      return '0$number';
    }
    else if (number.length == 2) {
      return number;
    }
    else {
      throw Exception();
    }
  }

  static double _multiply(Command command) {
    return command.originalFPS / command.targetFPS;
  }
}

class LengthException implements Exception {
  String errorMessage() {
    return 'Неправильное количество аргументов.';
  }
}

class NotDoubleException implements Exception {
  String errorMessage() {
    return 'Аргументы не являются числами.';
  }
}

class EmptyDocumentException implements Exception {
  String errorMessage() {
    return 'Ошибка. Приложите документ.';
  }
}