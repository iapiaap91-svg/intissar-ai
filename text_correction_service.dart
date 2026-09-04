/// خدمة تصحيح لغوي محلية خفيفة (بدون اتصال بالإنترنت) تعتمد على قواعد
/// وتُطبَّق بعد خروج النص من Whisper مباشرة قبل عرضه أو تصديره.
class TextCorrectionService {
  /// تشغيل جميع خطوات التصحيح على نص مفرغ خام
  String correct(String rawText, {String language = 'auto'}) {
    var text = rawText;
    text = _normalizeWhitespace(text);
    text = _fixArabicPunctuationSpacing(text);
    text = _fixLatinPunctuationSpacing(text);
    text = _capitalizeSentences(text);
    text = _mergeRepeatedFillers(text);
    return text.trim();
  }

  /// إزالة المسافات المتكررة والأسطر الفارغة الزائدة
  String _normalizeWhitespace(String text) {
    return text
        .replaceAll(RegExp(r'[ \t]+'), ' ')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n');
  }

  /// تصحيح المسافات حول علامات الترقيم العربية (؟ ، ؛)
  ///
  /// ملاحظة: `String.replaceAll` في Dart لا يدعم مراجع المجموعات ($1) في
  /// نص الاستبدال (خلافاً لـ JavaScript/بايثون) — كانت النسخة السابقة
  /// تُدرج الحرفين $1 حرفياً بدل النص الملتقط فعلياً. تم إصلاحه هنا
  /// باستخدام `replaceAllMapped` مع `match.group(1)`.
  String _fixArabicPunctuationSpacing(String text) {
    text = text.replaceAllMapped(
      RegExp(r'\s+([،؛؟])'),
      (m) => m.group(1)!,
    );
    text = text.replaceAllMapped(
      RegExp(r'([،؛؟])(?!\s)'),
      (m) => '${m.group(1)} ',
    );
    return text;
  }

  /// تصحيح المسافات حول علامات الترقيم اللاتينية (فرنسية/إنجليزية)
  /// (نفس ملاحظة `replaceAllMapped` أعلاه)
  String _fixLatinPunctuationSpacing(String text) {
    text = text.replaceAllMapped(
      RegExp(r'\s+([.,;:!?])'),
      (m) => m.group(1)!,
    );
    text = text.replaceAllMapped(
      RegExp(r'([.,;:!?])(?!\s|$)'),
      (m) => '${m.group(1)} ',
    );
    return text;
  }

  /// وضع حرف كبير في بداية كل جملة لاتينية جديدة
  String _capitalizeSentences(String text) {
    final buffer = StringBuffer();
    var capitalizeNext = true;
    for (final rune in text.runes) {
      final char = String.fromCharCode(rune);
      if (capitalizeNext && RegExp(r'[a-z]').hasMatch(char)) {
        buffer.write(char.toUpperCase());
        capitalizeNext = false;
      } else {
        buffer.write(char);
        if (RegExp(r'[.!?]').hasMatch(char)) {
          capitalizeNext = true;
        } else if (char.trim().isNotEmpty) {
          capitalizeNext = false;
        }
      }
    }
    return buffer.toString();
  }

  /// دمج كلمات الحشو المتكررة الناتجة عن التقطيع الصوتي (مثل: "يعني يعني يعني")
  String _mergeRepeatedFillers(String text) {
    return text.replaceAllMapped(
      RegExp(r'\b(\w+)(\s+\1\b){2,}', unicode: true),
      (m) => m.group(1)!,
    );
  }
}
