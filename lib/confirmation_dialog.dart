import 'package:flutter/material.dart';

class ConfirmationDialog {
  static Future<bool?> show({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'Confirmar',
    String cancelText = 'Cancelar',
  }) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(cancelText),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }

  static Future<void> confirmAction({
    required BuildContext context,
    required String title,
    required String message,
    required String actionText,
    required Future<void> Function() action,
  }) async {
    final confirmed = await show(
      context: context,
      title: title,
      message: message,
      confirmText: actionText,
    );

    if (confirmed == true) {
      await action();
    }
  }
}