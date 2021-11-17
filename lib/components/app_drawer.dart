import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:website/default_editor_demo/default_editor_demo.dart';

/// Application Drawer Widget
class AppDrawer extends StatelessWidget {
  /// Constructor values
  const AppDrawer({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        color: const Color(0xFF003F51),
        child: Column(
          children: <Widget>[
            Expanded(
              child: ListView(
                shrinkWrap: true,
                children: <Widget>[
                  const DrawerHeader(),
                  const SizedBox(height: 10),
                  DrawerListTile(
                    onTap: () => Navigator.of(context).pop(),
                    icon: Icons.home,
                    linkTitle: 'Home',
                  ),
                  ListTile(
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const DefaultEditorDemo()),
                      );
                    },
                    leading: const Icon(
                      Icons.person,
                      color: Colors.white,
                    ),
                    title: const Text(
                      'Default Editor Demoe',
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const Divider(),
                  const SizedBox(height: 60),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchURL({@required String url}) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      // ignore: only_throw_errors
      throw 'Could not launch $url';
    }
  }
}

/// Drawer List Tile Widget
class DrawerListTile extends StatelessWidget {
  ///
  const DrawerListTile({
    Key key,
    @required this.onTap,
    @required this.icon,
    @required this.linkTitle,
  }) : super(key: key);

  /// onTap VoidCallback function
  final VoidCallback onTap;

  /// Icon Name
  final IconData icon;

  /// Link Title Text
  final String linkTitle;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: Colors.white),
      title: Text(
        linkTitle,
        style: const TextStyle(
          color: Colors.white,
        ),
      ),
    );
  }
}

/// Drawer Header Widget
class DrawerHeader extends StatelessWidget {
  /// Constructor values
  const DrawerHeader({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 80,
      child: Padding(
        padding: const EdgeInsets.only(left: 18),
        child: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              SizedBox(height: 25),
              Text(
                'SuperEditor',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
