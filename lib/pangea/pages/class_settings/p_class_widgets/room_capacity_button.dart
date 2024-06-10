import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:fluffychat/pages/chat_details/chat_details.dart';
import 'package:fluffychat/pangea/extensions/pangea_room_extension/pangea_room_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:future_loading_dialog/future_loading_dialog.dart';
import 'package:matrix/matrix.dart';

class RoomCapacityButton extends StatefulWidget {
  final Room? room;
  final ChatDetailsController? controller;
  const RoomCapacityButton({
    super.key,
    this.room,
    this.controller,
  });

  @override
  RoomCapacityButtonState createState() => RoomCapacityButtonState();
}

class RoomCapacityButtonState extends State<RoomCapacityButton> {
  Room? room;
  ChatDetailsController? controller;
  int? capacity;
  String? nonAdmins;

  RoomCapacityButtonState({Key? key});

  @override
  void initState() {
    super.initState();
    room = widget.room;
    controller = widget.controller;
    capacity = room?.capacity;
    room?.numNonAdmins.then(
      (value) => setState(() {
        nonAdmins = value.toString();
        overCapacity();
      }),
    );
  }

  Future<void> overCapacity() async {
    if ((room?.isRoomAdmin ?? false) &&
        capacity != null &&
        nonAdmins != null &&
        int.parse(nonAdmins!) > capacity!) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            L10n.of(context)!.roomExceedsCapacity,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final iconColor = Theme.of(context).textTheme.bodyLarge!.color;
    return Column(
      children: [
        ListTile(
          onTap: () =>
              ((room?.isRoomAdmin ?? true) ? (setRoomCapacity()) : null),
          leading: CircleAvatar(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            foregroundColor: iconColor,
            child: const Icon(Icons.reduce_capacity),
          ),
          subtitle: Text(
            (capacity == null)
                ? L10n.of(context)!.capacityNotSet
                : (nonAdmins != null)
                    ? '$nonAdmins/$capacity'
                    : '$capacity',
          ),
          title: Text(
            L10n.of(context)!.roomCapacity,
            style: TextStyle(
              color: Theme.of(context).colorScheme.secondary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> setCapacity(int newCapacity) async {
    capacity = newCapacity;
  }

  Future<void> setRoomCapacity() async {
    final input = await showTextInputDialog(
      context: context,
      title: L10n.of(context)!.roomCapacity,
      message: L10n.of(context)!.roomCapacityExplanation,
      okLabel: L10n.of(context)!.ok,
      cancelLabel: L10n.of(context)!.cancel,
      textFields: [
        DialogTextField(
          initialText: ((capacity != null) ? '$capacity' : ''),
          keyboardType: TextInputType.number,
          maxLength: 3,
          validator: (value) {
            if (value == null ||
                value.isEmpty ||
                int.tryParse(value) == null ||
                int.parse(value) < 0) {
              return L10n.of(context)!.enterNumber;
            }
            if (nonAdmins != null && int.parse(value) < int.parse(nonAdmins!)) {
              return L10n.of(context)!.capacitySetTooLow;
            }
            return null;
          },
        ),
      ],
    );
    if (input == null ||
        input.first == "" ||
        int.tryParse(input.first) == null) {
      return;
    }

    final newCapacity = int.parse(input.first);
    final success = await showFutureLoadingDialog(
      context: context,
      future: () => ((room != null)
          ? (room!.updateRoomCapacity(
              capacity = newCapacity,
            ))
          : setCapacity(newCapacity)),
    );
    if (success.error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            L10n.of(context)!.roomCapacityHasBeenChanged,
          ),
        ),
      );
      setState(() {});
    }
  }
}
