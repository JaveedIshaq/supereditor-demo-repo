import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:website/components/app_drawer.dart';
import 'package:website/config/breakpoints.dart';
import 'package:website/config/helpers.dart';
import 'package:website/feature_editor/featured_editor.dart';
import 'components/super_editor_logo.dart';

void main() {
  setUrlStrategy(PathUrlStrategy());
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SuperEditor - A supercharged rich text editor for Flutter',
      theme: ThemeData(primarySwatch: Colors.blue, fontFamily: 'Aeonik'),
      home: const HomePage(),
    );
  }
}

// ======================
// Home Widget
// ======================

class HomePage extends StatelessWidget {
  const HomePage();

  @override
  Widget build(BuildContext context) {
    final isSingleColumnLayout = Breakpoints.collapsedNavigation(context);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF003F51),
      ),
      drawer: const Drawer(
        child: AppDrawer(),
      ),
      backgroundColor: const Color(0xFF003F51),
      body: _buildContent(
        isSingleColumnLayout: isSingleColumnLayout,
      ),
    );
  }

  Widget _buildContent({@required bool isSingleColumnLayout}) {
    return SizedBox(
      width: double.infinity,
      child: Column(
        children: [
          const SuperEditorLogo(),
          _buildFeaturedEditor(
            displayMode:
                isSingleColumnLayout ? DisplayMode.compact : DisplayMode.wide,
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedEditor({@required DisplayMode displayMode}) {
    return Center(
      child: FeaturedEditor(
        displayMode: displayMode,
        shadows: [editorBoxShadow],
      ),
    );
  }
}
