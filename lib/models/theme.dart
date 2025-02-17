import 'dart:io';
import 'dart:async';
import 'package:fimber/fimber.dart';
import 'package:fluro/fluro.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:git_touch/widgets/action_button.dart';
import 'package:primer/primer.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DialogOption<T> {
  final T value;
  final Widget widget;
  DialogOption({this.value, this.widget});
}

class AppThemeType {
  static const material = 0;
  static const cupertino = 1;
  static const values = [AppThemeType.material, AppThemeType.cupertino];
}

class PickerItem<T> {
  final T value;
  final String text;
  PickerItem(this.value, {@required this.text});
}

class PickerGroupItem<T> {
  final T value;
  final List<PickerItem<T>> items;
  final Function(T value) onChange;
  final Function(T value) onClose;

  PickerGroupItem({
    @required this.value,
    @required this.items,
    this.onChange,
    this.onClose,
  });
}

class SelectorItem<T> {
  T value;
  String text;
  SelectorItem({@required this.value, @required this.text});
}

// No animation. For replacing route
// TODO: Go back
class StaticRoute extends PageRouteBuilder {
  final WidgetBuilder builder;
  StaticRoute({this.builder})
      : super(
          pageBuilder: (BuildContext context, Animation<double> animation,
              Animation<double> secondaryAnimation) {
            return builder(context);
          },
          transitionsBuilder: (BuildContext context,
              Animation<double> animation,
              Animation<double> secondaryAnimation,
              Widget child) {
            return child;
          },
        );
}

class Palette {
  Color primary;
  Color text;
  Color secondaryText;
  Color tertiaryText;
  Color background;
  Color border;

  Palette({
    this.primary,
    this.text,
    this.secondaryText,
    this.tertiaryText,
    this.background,
    this.border,
  });
}

class ThemeModel with ChangeNotifier {
  static const storageKey = 'theme';

  int _theme;
  int get theme => _theme;
  bool get ready => _theme != null;

  Brightness _brightness = Brightness.light;
  Brightness get brightness => _brightness;
  Future<void> toggleBrightness() async {
    // TODO: Save
    _brightness =
        _brightness == Brightness.dark ? Brightness.light : Brightness.dark;
    notifyListeners();
  }

  final router = Router();

  Palette get palette {
    switch (brightness) {
      case Brightness.light:
        return Palette(
          primary: PrimerColors.blue500,
          text: PrimerColors.gray900,
          secondaryText: PrimerColors.gray700,
          tertiaryText: PrimerColors.gray500,
          background: PrimerColors.white,
          border: PrimerColors.gray100,
        );
      case Brightness.dark:
        return Palette(
          primary: PrimerColors.blue400,
          text: PrimerColors.gray300,
          secondaryText: PrimerColors.gray400,
          tertiaryText: PrimerColors.gray500,
          background: PrimerColors.black,
          border: PrimerColors.gray900,
        );
      default:
        return null;
    }
  }

  Future<void> init() async {
    var prefs = await SharedPreferences.getInstance();

    int v = prefs.getInt(storageKey);
    Fimber.d('read theme: $v');
    if (AppThemeType.values.contains(v)) {
      _theme = v;
    } else if (Platform.isIOS) {
      _theme = AppThemeType.cupertino;
    } else {
      _theme = AppThemeType.material;
    }

    notifyListeners();
  }

  Future<void> setTheme(int v) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    _theme = v;
    await prefs.setInt(storageKey, v);
    Fimber.d('write theme: $v');

    notifyListeners();
  }

  push(BuildContext context, String path, {bool replace = false}) {
    return router.navigateTo(
      context,
      path,
      transition: replace
          ? TransitionType.fadeIn
          : theme == AppThemeType.cupertino
              ? TransitionType.cupertino
              : TransitionType.material,
      replace: replace,
    );
  }

  Future<bool> showConfirm(BuildContext context, Widget content) {
    switch (theme) {
      case AppThemeType.cupertino:
        return showCupertinoDialog(
          context: context,
          builder: (context) {
            return CupertinoAlertDialog(
              title: content,
              actions: <Widget>[
                CupertinoDialogAction(
                  child: const Text('cancel'),
                  isDefaultAction: true,
                  onPressed: () {
                    Navigator.pop(context, false);
                  },
                ),
                CupertinoDialogAction(
                  child: const Text('OK'),
                  onPressed: () {
                    Navigator.pop(context, true);
                  },
                ),
              ],
            );
          },
        );
      default:
        return showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              content: content,
              actions: <Widget>[
                FlatButton(
                  child: const Text('CANCEL'),
                  onPressed: () {
                    Navigator.pop(context, false);
                  },
                ),
                FlatButton(
                  child: const Text('OK'),
                  onPressed: () {
                    Navigator.pop(context, true);
                  },
                )
              ],
            );
          },
        );
    }
  }

  Future<T> showDialogOptions<T>(
      BuildContext context, List<DialogOption<T>> options) {
    var title = Text('Pick your reaction');
    var cancelWidget = Text('Cancel');

    switch (theme) {
      case AppThemeType.cupertino:
        return showCupertinoDialog<T>(
          context: context,
          builder: (BuildContext context) {
            return CupertinoAlertDialog(
              title: title,
              actions: options.map((option) {
                return CupertinoDialogAction(
                  child: option.widget,
                  onPressed: () {
                    Navigator.pop(context, option.value);
                  },
                );
              }).toList()
                ..add(
                  CupertinoDialogAction(
                    child: cancelWidget,
                    isDestructiveAction: true,
                    onPressed: () {
                      Navigator.pop(context, null);
                    },
                  ),
                ),
            );
          },
        );
      default:
        return showDialog(
          context: context,
          builder: (BuildContext context) {
            return SimpleDialog(
              title: title,
              children: options.map<Widget>((option) {
                return SimpleDialogOption(
                  child: option.widget,
                  onPressed: () {
                    Navigator.pop(context, option.value);
                  },
                );
              }).toList()
                ..add(SimpleDialogOption(
                  child: cancelWidget,
                  onPressed: () {
                    Navigator.pop(context, null);
                  },
                )),
            );
          },
        );
    }
  }

  showSelector<T>({
    @required BuildContext context,
    @required Iterable<SelectorItem<T>> items,
    @required T selected,
  }) async {
    switch (theme) {
      case AppThemeType.cupertino:
      default:
        return showMenu<T>(
          context: context,
          initialValue: selected,
          items: items
              .map((item) =>
                  PopupMenuItem(value: item.value, child: Text(item.text)))
              .toList(),
          position: RelativeRect.fromLTRB(1, 10, 0, 0),
        );
    }
  }

  static Timer _debounce;
  String _selectedItem;

  showPicker(BuildContext context, PickerGroupItem<String> groupItem) async {
    switch (theme) {
      case AppThemeType.cupertino:
      default:
        await showCupertinoModalPopup(
          context: context,
          builder: (context) {
            return Container(
              height: 216,
              child: CupertinoPicker(
                backgroundColor: CupertinoColors.white,
                children: groupItem.items.map((v) => Text(v.text)).toList(),
                itemExtent: 40,
                scrollController: FixedExtentScrollController(
                    initialItem: groupItem.items
                        .toList()
                        .indexWhere((v) => v.value == groupItem.value)),
                onSelectedItemChanged: (index) {
                  _selectedItem = groupItem.items[index].value;

                  if (groupItem.onChange != null) {
                    if (_debounce?.isActive ?? false) {
                      _debounce.cancel();
                    }

                    _debounce = Timer(const Duration(milliseconds: 500), () {
                      groupItem.onChange(_selectedItem);
                    });
                  }
                },
              ),
            );
          },
        );
        if (groupItem.onClose != null) {
          groupItem.onClose(_selectedItem);
        }
    }
  }

  showActions(BuildContext context, List<ActionItem> actionItems) async {
    if (actionItems == null) return;
    final value = await showCupertinoModalPopup<int>(
      context: context,
      builder: (BuildContext context) {
        return CupertinoActionSheet(
          title: Text('Actions'),
          actions: actionItems.asMap().entries.map((entry) {
            return CupertinoActionSheetAction(
              child: Text(entry.value.text),
              onPressed: () {
                Navigator.pop(context, entry.key);
              },
            );
          }).toList(),
          cancelButton: CupertinoActionSheetAction(
            child: const Text('Cancel'),
            isDefaultAction: true,
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        );
      },
    );

    if (value != null) {
      actionItems[value].onPress(context);
    }
  }
}
