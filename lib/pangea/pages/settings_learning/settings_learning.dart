import 'package:country_picker/country_picker.dart';
import 'package:fluffychat/pangea/controllers/pangea_controller.dart';
import 'package:fluffychat/pangea/models/space_model.dart';
import 'package:fluffychat/pangea/models/user_model.dart';
import 'package:fluffychat/pangea/pages/settings_learning/settings_learning_view.dart';
import 'package:fluffychat/pangea/widgets/chat/tts_controller.dart';
import 'package:fluffychat/pangea/widgets/user_settings/p_language_dialog.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:flutter/material.dart';

class SettingsLearning extends StatefulWidget {
  const SettingsLearning({super.key});

  @override
  SettingsLearningController createState() => SettingsLearningController();
}

class SettingsLearningController extends State<SettingsLearning> {
  PangeaController pangeaController = MatrixState.pangeaController;
  final tts = TtsController();

  @override
  void initState() {
    super.initState();
    tts.setupTTS().then((_) => setState(() {}));
  }

  @override
  void dispose() {
    tts.dispose();
    super.dispose();
  }

  setPublicProfile(bool isPublic) {
    pangeaController.userController.updateProfile((profile) {
      profile.userSettings.publicProfile = isPublic;
      return profile;
    });
    setState(() {});
  }

  void changeLanguage() {
    pLanguageDialog(context, () {}).then((_) => setState(() {}));
  }

  void changeCountry(Country country) {
    pangeaController.userController.updateProfile((Profile profile) {
      profile.userSettings.country = country.displayNameNoCountryCode;
      return profile;
    });
    setState(() {});
  }

  void updateToolSetting(ToolSetting toolSetting, bool value) {
    pangeaController.userController.updateProfile((Profile profile) {
      switch (toolSetting) {
        case ToolSetting.interactiveTranslator:
          return profile..toolSettings.interactiveTranslator = value;
        case ToolSetting.interactiveGrammar:
          return profile..toolSettings.interactiveGrammar = value;
        case ToolSetting.immersionMode:
          return profile..toolSettings.immersionMode = value;
        case ToolSetting.definitions:
          return profile..toolSettings.definitions = value;
        case ToolSetting.autoIGC:
          return profile..toolSettings.autoIGC = value;
        case ToolSetting.enableTTS:
          return profile..toolSettings.enableTTS = value;
      }
    });
  }

  bool getToolSetting(ToolSetting toolSetting) {
    final toolSettings = pangeaController.userController.profile.toolSettings;
    switch (toolSetting) {
      case ToolSetting.interactiveTranslator:
        return toolSettings.interactiveTranslator;
      case ToolSetting.interactiveGrammar:
        return toolSettings.interactiveGrammar;
      case ToolSetting.immersionMode:
        return toolSettings.immersionMode;
      case ToolSetting.definitions:
        return toolSettings.definitions;
      case ToolSetting.autoIGC:
        return toolSettings.autoIGC;
      case ToolSetting.enableTTS:
        return toolSettings.enableTTS;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SettingsLearningView(this);
  }
}
