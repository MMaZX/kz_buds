// T1 spike (odd/tasks/design-system.md): does shadcn_ui work under our own
// WidgetsApp, without ShadApp and without a Material Theme?
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

const _bg = Color(0xFF0E1014);

class _Home extends StatefulWidget {
  const _Home();

  @override
  State<_Home> createState() => _HomeState();
}

class _HomeState extends State<_Home> {
  final popover = ShadPopoverController();

  @override
  void dispose() {
    popover.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ShadButton(
              onPressed: () =>
                  ShadToaster.of(context)
                      .show(const ShadToast(title: Text('toast-shown'))),
              child: const Text('toast'),
            ),
            ShadButton.outline(
              onPressed: () => showShadDialog<void>(
                context: context,
                builder: (_) => const ShadDialog(
                  title: Text('dialog-open'),
                  child: Text('body'),
                ),
              ),
              child: const Text('dialog'),
            ),
            ShadButton.ghost(
              onPressed: () => showShadSheet<void>(
                context: context,
                side: ShadSheetSide.bottom,
                builder: (_) => const ShadSheet(title: Text('sheet-open')),
              ),
              child: const Text('sheet'),
            ),
            ShadSwitch(value: true, onChanged: (_) {}),
            SizedBox(
              width: 200,
              child: ShadSlider(initialValue: 0.4, max: 1, onChanged: (_) {}),
            ),
            const SizedBox(
              width: 200,
              child: ShadInput(placeholder: Text('input-placeholder')),
            ),
            SizedBox(
              width: 200,
              child: ShadSelect<String>(
                placeholder: const Text('select-placeholder'),
                options: const [
                  ShadOption(value: 'a', child: Text('option-a')),
                ],
                selectedOptionBuilder: (context, value) => Text(value),
              ),
            ),
            ShadPopover(
              controller: popover,
              popover: (_) => const Text('popover-open'),
              child: ShadButton(
                onPressed: popover.toggle,
                child: const Text('popover'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _app({Brightness brightness = Brightness.dark}) {
  return WidgetsApp(
    color: _bg,
    localizationsDelegates: const [
      GlobalShadLocalizations.delegate,
      DefaultWidgetsLocalizations.delegate,
    ],
    pageRouteBuilder: <T>(RouteSettings settings, WidgetBuilder builder) =>
        PageRouteBuilder<T>(
          settings: settings,
          pageBuilder: (context, _, _) => builder(context),
        ),
    builder: (context, navigator) => ShadAnimatedTheme(
      data: ShadThemeData(
        brightness: brightness,
        colorScheme: ShadColorScheme.fromName('slate', brightness: brightness),
      ),
      child: DefaultTextStyle(
        style: const TextStyle(color: Color(0xFFECEEF1), fontSize: 15),
        child: ShadAppBuilder(child: navigator),
      ),
    ),
    home: const _Home(),
  );
}

void main() {
  testWidgets('shad components render under WidgetsApp', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('toast'), findsOneWidget);
    expect(find.text('input-placeholder'), findsOneWidget);
    expect(find.text('select-placeholder'), findsOneWidget);
  });

  testWidgets('overlays work: select, popover, dialog, sheet, toast', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('select-placeholder'));
    await tester.pumpAndSettle();
    expect(find.text('option-a'), findsOneWidget);
    await tester.tapAt(const Offset(2, 2));
    await tester.pumpAndSettle();

    await tester.tap(find.text('popover'));
    await tester.pumpAndSettle();
    expect(find.text('popover-open'), findsOneWidget);
    await tester.tapAt(const Offset(2, 2));
    await tester.pumpAndSettle();

    await tester.tap(find.text('dialog'));
    await tester.pumpAndSettle();
    expect(find.text('dialog-open'), findsOneWidget);
    await tester.tapAt(const Offset(2, 2));
    await tester.pumpAndSettle();

    await tester.tap(find.text('sheet'));
    await tester.pumpAndSettle();
    expect(find.text('sheet-open'), findsOneWidget);
    await tester.tapAt(const Offset(2, 2));
    await tester.pumpAndSettle();

    await tester.tap(find.text('toast'));
    await tester.pumpAndSettle();
    expect(find.text('toast-shown'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ShadTheme exposes the configured background', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    final theme = ShadTheme.of(tester.element(find.text('toast')));
    expect(theme.brightness, Brightness.dark);
    expect(theme.colorScheme.background, isNot(const Color(0x00000000)));
  });
}
