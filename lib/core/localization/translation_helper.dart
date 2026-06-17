import 'package:translator/translator.dart';
import 'package:easysaloonapp/core/localization/language_service.dart';

class TranslationHelper {
  static final GoogleTranslator _translator = GoogleTranslator();

  static Future<String> translateText(String text) async {
    final targetLang = LanguageService.to.currentLanguage.value;
    if (targetLang == 'en' || text.isEmpty) return text;
    try {
      final translation = await _translator.translate(text, to: targetLang);
      return translation.text;
    } catch (e) {
      return text;
    }
  }

  static Future<List<dynamic>> translateList(List<dynamic> items, List<String> keys) async {
    final targetLang = LanguageService.to.currentLanguage.value;
    if (targetLang == 'en' || items.isEmpty) return items;

    try {
      List<String> textsToTranslate = [];
      for (var item in items) {
        for (var key in keys) {
          textsToTranslate.add((item[key] ?? '').toString());
        }
      }

      if (textsToTranslate.isEmpty) return items;

      // Join with a newline to preserve array length safely through translation
      String combinedText = textsToTranslate.join('\n');
      final translation = await _translator.translate(combinedText, to: targetLang);
      
      // Split by newline
      List<String> translatedTexts = translation.text.split('\n');

      if (translatedTexts.length == textsToTranslate.length) {
        List<dynamic> translatedItems = [];
        int textIndex = 0;
        
        for (var item in items) {
          var newItem = Map<String, dynamic>.from(item);
          for (var key in keys) {
            newItem[key] = translatedTexts[textIndex].trim();
            textIndex++;
          }
          translatedItems.add(newItem);
        }
        return translatedItems;
      } else {
        // If length mismatches, fallback to original
        return items;
      }
    } catch (e) {
      return items;
    }
  }
}
