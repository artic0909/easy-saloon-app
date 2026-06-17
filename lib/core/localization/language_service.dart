import 'dart:ui';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageService extends GetxService {
  static LanguageService get to => Get.find();
  
  static const String _languageKey = 'user_language';
  
  late SharedPreferences _prefs;
  final RxString currentLanguage = 'en'.obs;

  Future<LanguageService> init() async {
    _prefs = await SharedPreferences.getInstance();
    final savedLang = _prefs.getString(_languageKey);
    if (savedLang != null) {
      currentLanguage.value = savedLang;
    }
    return this;
  }

  bool get hasSelectedLanguage => _prefs.containsKey(_languageKey);

  Future<void> changeLanguage(String langCode) async {
    currentLanguage.value = langCode;
    await _prefs.setString(_languageKey, langCode);
    Get.updateLocale(Locale(langCode));
  }

  Locale get locale => Locale(currentLanguage.value);
}
