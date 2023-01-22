import 'package:mozersubtitlebot/features/subtitles/timecode.dart';

class Subs {
  static const srtLineDivider = '\r\n';

  String parseSubtitle(String subtitle, double multiplier) {
    final lines = subtitle.split(srtLineDivider);
    final buffer = StringBuffer();

    //1
    // 00:00:11,820 --> 00:00:18,771
    // Когда я был мальчиком, луна была жемчужной,
    // а солнце - золотым.
    for (final line in lines) {
      if (line.contains(TimeCode.divider)) {
        buffer.write(
          '${multiplyTimeCodeLine(line, multiplier)}$srtLineDivider',
        );
      } else {
        buffer.write('$line$srtLineDivider');
      }
    }
    return buffer.toString();
  }

  // 00:00:11,820 --> 00:00:18,771
  String multiplyTimeCodeLine(String timeCode, double multiplier) {
    final timeCods = timeCode.split(TimeCode.divider);
    assert(timeCods.length == 2);
    final timeCodeStartDuration = parseFromTimeCode(timeCods[0]) * multiplier;
    final timeCodeEndDuration = parseFromTimeCode(timeCods[1]) * multiplier;
    final newStartTimeCode = parseToTimeCode(timeCodeStartDuration);
    final newEndTimeCode = parseToTimeCode(timeCodeEndDuration);

    return '$newStartTimeCode${TimeCode.divider}$newEndTimeCode';
  }

  // 00:00:11,820
  Duration parseFromTimeCode(String timeCode) {
    final temp = timeCode.split(':');
    final hours = int.tryParse(temp[0]);
    final minutes = int.tryParse(temp[1]);
    final seconds = double.tryParse(temp[2].replaceFirst(',', '.'));
    final milliseconds = seconds != null ? seconds - seconds.toInt() : 0;
    if (hours == null || minutes == null || seconds == null) {
      throw FormatException('timeCode was null', timeCode);
    }

    return Duration(
      hours: hours,
      minutes: minutes,
      seconds: seconds.toInt(),
      milliseconds: milliseconds.toInt(),
    );
  }

  String parseToTimeCode(Duration duration) {
    final hoursDuration = Duration(
      hours: duration.inHours,
    );
    final minutesDuration = Duration(
      minutes: (duration - hoursDuration).inMinutes,
    );
    final secondsDuration = Duration(
      seconds: (duration - (hoursDuration + minutesDuration)).inSeconds,
    );
    final hoursCode = toCode(hoursDuration.inHours.toString());
    final minutesCode = toCode(minutesDuration.inMinutes.toString());
    final secondsCode = toCode(secondsDuration.inSeconds.toString());
    final milliseconds = toMillisecondsCode(
      (duration - (hoursDuration + minutesDuration + secondsDuration))
          .inMilliseconds
          .toString(),
    );

    return '$hoursCode:$minutesCode:$secondsCode,$milliseconds';
  }

  String toCode(String number) {
    if (number.length == 1) {
      return '0$number';
    } else if (number.length == 2) {
      return number;
    } else {
      throw Exception();
    }
  }

  String toMillisecondsCode(String number) {
    if (number.length == 1) {
      return '00$number';
    } else if (number.length == 2) {
      return '0$number';
    } else if (number.length == 3) {
      return number;
    } else {
      throw Exception();
    }
  }
}

class LengthException implements Exception {
  const LengthException([this.message = 'Неправильное количество аргументов.']);

  final String message;
}

class NotDoubleException implements Exception {
  const NotDoubleException([this.message = 'Аргументы не являются числами.']);

  final String message;
}

class EmptyDocumentException implements Exception {
  const EmptyDocumentException([this.message = 'Ошибка. Прикрепите документ.']);

  final String message;
}
