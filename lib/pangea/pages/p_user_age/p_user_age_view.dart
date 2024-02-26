import 'package:fluffychat/pangea/pages/p_user_age/p_user_age.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

import '../../../widgets/layouts/login_scaffold.dart';

class PUserAgeView extends StatelessWidget {
  final PUserAgeController controller;
  const PUserAgeView(this.controller, {super.key});

  @override
  Widget build(BuildContext context) {
    return LoginScaffold(
      appBar: AppBar(
        automaticallyImplyLeading: !controller.loading,
      ),
      body: ListView(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 10),
            padding: const EdgeInsets.all(12),
            child: Text(
              L10n.of(context)!.yourBirthdayPlease,
              textAlign: TextAlign.justify,
              style: const TextStyle(color: Colors.white),
            ),
          ),
          const SizedBox(
            height: 10,
          ),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Theme.of(context)
                  .colorScheme
                  .onSecondaryContainer
                  .withAlpha(50),
            ),
            child: Column(
              children: [
                ListTile(
                  title: Text(
                    L10n.of(context)!.certifyAge(13),
                    style: const TextStyle(color: Colors.white),
                  ),
                  leading: Radio<int>(
                    value: 13,
                    groupValue: controller.selectedAge,
                    onChanged: controller.setSelectedAge,
                  ),
                ),
                ListTile(
                  title: Text(
                    L10n.of(context)!.certifyAge(18),
                    style: const TextStyle(color: Colors.white),
                  ),
                  leading: Radio<int>(
                    value: 18,
                    groupValue: controller.selectedAge,
                    onChanged: controller.setSelectedAge,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(
            height: 10,
          ),
          if (controller.error != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                controller.error!,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          Hero(
            tag: 'loginButton',
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: ElevatedButton(
                onPressed: controller.createUserInPangea,
                child: controller.loading
                    ? const LinearProgressIndicator()
                    : Text(L10n.of(context)!.getStarted),
              ),
            ),
          ),
        ],
      ),
      // ),
    );
  }
}
