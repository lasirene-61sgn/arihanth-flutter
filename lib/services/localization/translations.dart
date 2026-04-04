import 'languages/en.dart';
import 'languages/hi.dart';
import 'languages/ta.dart';
import 'languages/bn.dart';
import 'languages/mr.dart';
import 'languages/te.dart';
import 'languages/gu.dart';
import 'languages/ur.dart';
import 'languages/kn.dart';
import 'languages/or.dart';
import 'languages/ml.dart';
import 'languages/pa.dart';

class AppTranslations {
  static final Map<String, Map<String, String>> translations = {
    'en': en,
    'hi': hi,
    'ta': ta,
    'bn': bn,
    'mr': mr,
    'te': te,
    'gu': gu,
    'ur': ur,
    'kn': kn,
    'or': or,
    'ml': ml,
    'pa': pa,
  };

  static String translate(String key, String locale) {
    return translations[locale]?[key] ?? key;
  }
}
