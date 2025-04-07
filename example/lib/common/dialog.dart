// ignore_for_file: avoid_shadowing_type_parameters

import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'style.dart';

class HDialog {
  static Future<T?> show<T>({
    required BuildContext context,
    String title = '温馨提示',
    String? content,
    bool barrierDismissible = true,
    Color? barrierColor = Colors.black54,
    bool? useSafeArea,
    bool? useRootNavigator,
    Widget? contentWidget,
    List<DialogAction> options = const [DialogAction(text: '知道了')],
  }) {
    return showDialog(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierColor: barrierColor,
      useSafeArea: useSafeArea ?? true,
      useRootNavigator: useRootNavigator ?? true,
      builder: (BuildContext context) => HDialogWidget(
        title: title,
        content: content,
        contentWidget: contentWidget,
        options: options,
        isSheetStyle: false,
      ),
    );
  }
}

class DialogAction<T> {
  final String? text;
  final ActionType type;
  final Widget? child;
  final T? actionValue;
  final VoidCallback? onPressed;

  const DialogAction({this.text, this.type = ActionType.positive, this.child, this.actionValue, this.onPressed});
}

enum ActionType { delete, positive, negative }

Color _getActionColor(ActionType type) {
  return switch (type) {
    ActionType.delete => HColors.secondary,
    ActionType.negative => HColors.mediumGrey,
    ActionType.positive => HColors.primary
  };
}

class HDialogWidget<T> extends StatelessWidget {
  final String? title;
  final String? content;
  final Widget? contentWidget;
  final bool isSheetStyle;
  final DialogAction<T>? bottomSheetCancel;
  final List<DialogAction<T>> options;

  const HDialogWidget({
    super.key,
    this.title,
    this.content,
    this.contentWidget,
    this.bottomSheetCancel,
    this.isSheetStyle = false,
    this.options = const [],
  });

  @override
  Widget build(BuildContext context) {
    // ignore: no_leading_underscores_for_local_identifiers, non_constant_identifier_names
    Function _Notification = Platform.isIOS ? createIOSDialog : createAndroidDialog;
    return _Notification(content: content, contentWidget: contentWidget, title: title, context: context, options: options);
  }

  AlertDialog createAndroidDialog<T>({
    required BuildContext context,
    String? title,
    String? content,
    required List<DialogAction<T>> options,
    Widget? contentWidget,
  }) {
    final actions = options.map((option) {
      return CupertinoButton(onPressed: () => onPress(context, option), child: getChild(option));
    }).toList();

    return AlertDialog(
      title: title == null ? null : Text(title),
      content: getContentMessage(content, contentWidget),
      actions: actions,
    );
  }

  CupertinoAlertDialog createIOSDialog<T>({
    required BuildContext context,
    String? title,
    String? content,
    Widget? contentWidget,
    required List<DialogAction<T>> options,
  }) {
    final actions = options.map((option) {
      return CupertinoButton(onPressed: () => onPress(context, option), child: getChild(option));
    }).toList();

    return CupertinoAlertDialog(
      title: title == null ? null : Text(title),
      content: getContentMessage(content, contentWidget),
      actions: actions,
    );
  }

  CupertinoActionSheet createIOSSheetDialog<T>({
    required BuildContext context,
    required List<DialogAction<T>> options,
    String? title,
    String? content,
    Widget? contentWidget,
    DialogAction<T>? bottomSheetCancel,
  }) {
    final List<CupertinoActionSheetAction> actions = options.map((option) {
      return CupertinoActionSheetAction(onPressed: () => onPress(context, option), child: getChild(option));
    }).toList();

    final CupertinoActionSheetAction? cancelButton = bottomSheetCancel == null
        ? null
        : CupertinoActionSheetAction(
      isDefaultAction: true,
      onPressed: () => onPress(context, bottomSheetCancel),
      child: getChild(bottomSheetCancel),
    );

    return CupertinoActionSheet(
      title: title == null ? null : Text(title),
      message: getContentMessage(content, contentWidget),
      actions: actions,
      cancelButton: cancelButton,
    );
  }

  void onPress(BuildContext ctx, DialogAction option) {
    Navigator.pop(ctx, option.actionValue);
    if (option.onPressed != null) option.onPressed!();
  }

  Widget getContentMessage(String? content, Widget? widget) {
    return widget != null && content == null ? widget : Text(content ?? '');
  }

  Widget getChild(DialogAction option) {
    return option.child ?? Text(option.text ?? '', style: TextStyle(color: _getActionColor(option.type)));
  }
}
