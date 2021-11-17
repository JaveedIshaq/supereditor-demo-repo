import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:super_editor/super_editor.dart';
import 'package:website/config/logger.dart';

import 'editor_toolbar.dart';

/// A Super Editor that displays itself on top of a white sheet of paper
/// with a popup editor toolbar.
///
/// This editor adjusts its padding and text styles based on the given
/// [displayMode].
///
/// Most of the implementation of this widget is about implementing the
/// popup toolbar.

class FeaturedEditor extends StatefulWidget {
  const FeaturedEditor({
    Key key,
    this.displayMode,
    this.shadows = const [],
  }) : super(key: key);

  final DisplayMode displayMode;
  final List<BoxShadow> shadows;

  @override
  _FeaturedEditorState createState() => _FeaturedEditorState();
}

class _FeaturedEditorState extends State<FeaturedEditor> {
  /// Logger
  Logger log = getLogger('FeaturedEditor');

  final _docLayoutKey = GlobalKey();

  MutableDocument _doc;
  DocumentEditor _docEditor;
  DocumentComposer _composer;

  FocusNode _editorFocusNode;

  ScrollController _scrollController;

  OverlayEntry _formatBarOverlayEntry;
  final _selectionAnchor = ValueNotifier<Offset>(null);

  @override
  void initState() {
    super.initState();

    // Create the initial document content.
    _doc = _createInitialDocument()..addListener(_updateToolbarDisplay);

    // Create the DocumentEditor, which is responsible for applying all
    // content changes to the Document.
    _docEditor = DocumentEditor(document: _doc);

    // Create the DocumentComposer, which keeps track of the user's text
    // selection and the current input styles, e.g., bold or italics.
    //
    // This DocumentComposer is created because we want explicit control
    // over the initial caret position. If you don't need any external
    // control over content selection then you don't need to create your
    // own DocumentComposer. The Editor widget will do that on your behalf.
    _composer = DocumentComposer(
      initialSelection: DocumentSelection.collapsed(
        position: DocumentPosition(
          nodeId: _doc.nodes.last.id, // Place caret at end of document
          nodePosition: (_doc.nodes.last as TextNode).endPosition,
        ),
      ),
    )..addListener(_updateToolbarDisplay);

    // Create a FocusNode so that we can explicitly toggle editor focus.
    _editorFocusNode = FocusNode();

    // Use our own ScrollController for the editor so that we can refresh
    // our popup toolbar position as the user scrolls the editor.
    _scrollController = ScrollController()..addListener(_updateToolbarDisplay);
  }

  @override
  void dispose() {
    if (_formatBarOverlayEntry != null) {
      _formatBarOverlayEntry.remove();
    }

    _doc.dispose();
    _scrollController.dispose();
    _editorFocusNode.dispose();
    _composer.dispose();

    super.dispose();
  }

  void _showEditorToolbar() {
    if (_formatBarOverlayEntry == null) {
      _formatBarOverlayEntry ??= OverlayEntry(
        builder: (context) {
          return EditorToolbar(
            anchor: _selectionAnchor,
            editor: _docEditor,
            composer: _composer,
            closeToolbar: _hideEditorToolbar,
          );
        },
      );

      // Display the toolbar in the application overlay.
      final overlay = Overlay.of(context);
      overlay.insert(_formatBarOverlayEntry);

      // Schedule a callback after this frame to locate the selection
      // bounds on the screen and display the toolbar near the selected
      // text.
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        _updateToolbarOffset();
      });
    }
  }

  void _updateToolbarOffset() {
    if (_formatBarOverlayEntry == null) {
      return;
    }

    final docBoundingBox =
        (_docLayoutKey.currentState as DocumentLayout).getRectForSelection(
      _composer.selection.base,
      _composer.selection.extent,
    );
    final parentBox = context.findRenderObject() as RenderBox;
    final docBox = _docLayoutKey.currentContext.findRenderObject() as RenderBox;
    final parentInOverlayOffset = parentBox.localToGlobal(Offset.zero);
    final overlayBoundingBox = Rect.fromPoints(
      docBox.localToGlobal(docBoundingBox.topLeft, ancestor: parentBox),
      docBox.localToGlobal(docBoundingBox.bottomRight, ancestor: parentBox),
    ).translate(parentInOverlayOffset.dx, parentInOverlayOffset.dy);

    final offset = overlayBoundingBox.topCenter;

    _selectionAnchor.value = offset;
  }

  /// Hide Editor Toolbar
  void _hideEditorToolbar() {
    // Null out the selection anchor so that when it re-appears,
    // the bar doesn't momentarily "flash" at its old anchor position.
    _selectionAnchor.value = null;

    if (_formatBarOverlayEntry != null) {
      // Remove the toolbar overlay and null-out the entry.
      // We null out the entry because we can't query whether
      // or not the entry exists in the overlay, so in our
      // case, null implies the entry is not in the overlay,
      // and non-null implies the entry is in the overlay.
      _formatBarOverlayEntry.remove();
      _formatBarOverlayEntry = null;
    }

    // Ensure that focus returns to the editor.
    //
    // I tried explicitly unfocus()'ing the URL textfield
    // in the toolbar but it didn't return focus to the
    // editor. I'm not sure why.
    _editorFocusNode.requestFocus();
  }

  /// Toolbar Display
  void _updateToolbarDisplay() {
    //log.w('_updateToolbarDisplay is called');
    //log.w('_composer: $_composer');
    //log.w('_composer: $_doc');

    final selection = _composer.selection;
    if (selection == null) {
      // Nothing is selected. We don't want to show a toolbar
      // in this case.
      _hideEditorToolbar();

      return;
    }
    if (selection.base.nodeId != selection.extent.nodeId) {
      // More than one node is selected. We don't want to show
      // a toolbar in this case.
      _hideEditorToolbar();

      return;
    }

    if (selection.isCollapsed) {
      // We only want to show the toolbar when a span of text
      // is selected. Therefore, we ignore collapsed selections.
      _hideEditorToolbar();

      return;
    }

    final textNode = _doc.getNodeById(selection.extent.nodeId);
    if (textNode is! TextNode) {
      // The currently selected content is not a paragraph. We don't
      // want to show a toolbar in this case.
      _hideEditorToolbar();

      return;
    } else {
      log.w('======Selected Node is Following==========');
      log.w(textNode);
      log.w('Selected Node Id is: ${selection.extent.nodeId}');
    }

    if (_formatBarOverlayEntry == null) {
      // Show the editor's toolbar for text styling.
      _showEditorToolbar();
    } else {
      _updateToolbarOffset();
    }
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return SingleChildScrollView(
      child: Column(
        children: [
          Wrap(
            children: [
              ElevatedButton(
                onPressed: () {
                  _downloadAsText(_doc.nodes, true);
                },
                child: const Text('Download Document Delta as Json'),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: () {
                  _downloadAsText(_doc.nodes, false);
                },
                child: const Text('Download unformated content of Document'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: (size.width < 800) ? size.width * 0.90 : 800,
            height: size.height * 0.60,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: widget.shadows,
            ),
            child: SuperEditor.custom(
              editor: _docEditor,
              composer: _composer,
              documentLayoutKey: _docLayoutKey,
              focusNode: _editorFocusNode,
              maxWidth: 800,
              padding: _getEditorPadding(),
              textStyleBuilder: _getEditorStyleBuilder(),
              componentBuilders: [
                _blockquoteBuilder,
                ...defaultComponentBuilders,
              ],
            ),
          ),
        ],
      ),
    );
  }

  ///=== Download as Text
  void _downloadAsText(List<DocumentNode> nodes, bool allAtribute) {
    log.w('the document: ${_composer.preferences.currentAttributions.toSet()}');

    //log.w(nodes[0].toString());
    // log.w('ID: ${nodes[0].id}');
    // log.w('beginningPosition: ${nodes[0].beginningPosition}');
    // log.w('EndPosition: ${nodes[0].endPosition}');
    // log.w(nodes[0].copyContent(nodes[0].computeSelection(
    //     base: nodes[0].beginningPosition, extent: nodes[0].endPosition)));

    final text = StringBuffer();
    final valueArray = [];
    for (var i = 0; i < nodes.length; i++) {
      // log.w('$i Full Node: ${nodes[i]}');
      // log.w('$i ID: ${nodes[i].id}');
      // log.w('$i beginningPosition: ${nodes[i].beginningPosition}');
      // log.w('$i EndPosition: ${nodes[i].endPosition}');

      final String textContent = nodes[i].copyContent(nodes[i].computeSelection(
          base: nodes[i].beginningPosition, extent: nodes[i].endPosition));

      if (allAtribute) {
        valueArray.add(jsonEncode({
          "insert": textContent,
          "attributes": getMetaData(nodes[i] as TextNode)
        }));
      } else {
        text.write('$textContent\n');
      }
    }
    if (allAtribute) {
      text.write('$valueArray');
    }

    // prepare
    final bytes = utf8.encode(text.toString());
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.document.createElement('a') as html.AnchorElement
      ..href = url
      ..style.display = 'none'
      ..download = 'data.json';
    html.document.body.children.add(anchor);

    // download
    anchor.click();

    // cleanup
    html.document.body.children.remove(anchor);
    html.Url.revokeObjectUrl(url);
  }

  String getMetaData(TextNode node) {
    String thisMetaData = '';
    if (node is ParagraphNode) {
      thisMetaData =
          node.metadata.toString().replaceAll('[NamedAttribution]:', '');
    }

    return thisMetaData;
  }

  EdgeInsetsGeometry _getEditorPadding() {
    switch (widget.displayMode) {
      case DisplayMode.wide:
        return const EdgeInsets.symmetric(horizontal: 54, vertical: 60);
      case DisplayMode.compact:
        return const EdgeInsets.symmetric(horizontal: 32, vertical: 24);
      default:
        throw Exception('Invalid displayMode: ${widget.displayMode}');
    }
  }

  TextStyle Function(Set<Attribution> attributions) _getEditorStyleBuilder() {
    switch (widget.displayMode) {
      case DisplayMode.wide:
        return _editorStyleBuilderWide;
      case DisplayMode.compact:
        return _editorStyleBuilderCompact;
      default:
        throw Exception('Invalid displayMode: ${widget.displayMode}');
    }
  }
}

enum DisplayMode {
  wide,
  compact,
}

// The editor does not yet have an underline attribution and style by
// default. Until it does, we create our own attribution here and then
// we style the text ourselves in the "text style builders" that we
// provide to the Editor widget.
const _underlineAttribution = NamedAttribution('underline');

MutableDocument _createInitialDocument() {
  return MutableDocument(
    nodes: [
      ParagraphNode(
        id: DocumentEditor.createNodeId(),
        text: AttributedText(
          text: 'A supercharged rich text editor for Flutter',
        ),
        metadata: {
          'blockType': header1Attribution,
          'textAlign': 'center',
        },
      ),
      ParagraphNode(
        id: DocumentEditor.createNodeId(),
        text: AttributedText(
          text: 'A supercharged rich text editor for Flutter',
        ),
        metadata: {
          'blockType': header1Attribution,
          'textAlign': 'center',
        },
      ),
      ParagraphNode(
        id: DocumentEditor.createNodeId(),
        text: AttributedText(
          text: 'The missing WYSIWYG editor for Flutter.',
          spans: AttributedSpans(
            attributions: [
              const SpanMarker(
                attribution: boldAttribution,
                offset: 0,
                markerType: SpanMarkerType.start,
              ),
              const SpanMarker(
                attribution: boldAttribution,
                offset: 25,
                markerType: SpanMarkerType.end,
              ),
            ],
          ),
        ),
      ),
      ParagraphNode(
        id: DocumentEditor.createNodeId(),
        text: AttributedText(
          text:
              'Open source and written entirely in Dart. Comes with a modular architecture that allows you to customise it to your needs.',
          spans: AttributedSpans(
            attributions: [
              const SpanMarker(
                attribution: _underlineAttribution,
                offset: 16,
                markerType: SpanMarkerType.start,
              ),
              const SpanMarker(
                attribution: _underlineAttribution,
                offset: 40,
                markerType: SpanMarkerType.end,
              ),
            ],
          ),
        ),
      ),
      ParagraphNode(
        id: DocumentEditor.createNodeId(),
        text: AttributedText(
          text: 'Text Formatting Examples',
        ),
      ),
      ParagraphNode(
        id: DocumentEditor.createNodeId(),
        text: AttributedText(
          text: 'Largest Header',
        ),
        metadata: {
          'blockType': header1Attribution,
          'textAlign': 'left',
        },
      ),
      ParagraphNode(
        id: DocumentEditor.createNodeId(),
        text: AttributedText(
          text: 'Second Largest Header',
        ),
        metadata: {
          'blockType': header2Attribution,
          'textAlign': 'left',
        },
      ),
      ParagraphNode(
        id: DocumentEditor.createNodeId(),
        text: AttributedText(
          text: 'Third Largest Header',
        ),
        metadata: {
          'blockType': header3Attribution,
          'textAlign': 'left',
        },
      ),
      ParagraphNode(
        id: DocumentEditor.createNodeId(),
        text: AttributedText(
          text:
              'Blockquote Text representation will look some thing like this in the SuperEditor',
        ),
        metadata: {
          'blockType': blockquoteAttribution,
          'textAlign': 'left',
        },
      ),
      ParagraphNode(
        id: DocumentEditor.createNodeId(),
        text: AttributedText(
          text: 'This is some Text with Bold Attribution',
        ),
        metadata: {
          'blockType': boldAttribution,
          'textAlign': 'left',
        },
      ),
      ParagraphNode(
        id: DocumentEditor.createNodeId(),
        text: AttributedText(
          text: 'Italic attributed text will Look Like this',
        ),
        metadata: {
          'blockType': italicsAttribution,
          'textAlign': 'left',
        },
      ),
      ParagraphNode(
        id: DocumentEditor.createNodeId(),
        text: AttributedText(
          text: 'This is a Strike Through Text',
        ),
        metadata: {
          'blockType': strikethroughAttribution,
          'textAlign': 'left',
        },
      ),
      ParagraphNode(
        id: DocumentEditor.createNodeId(),
        text: AttributedText(
          text: 'Try it right here To Know More about SuperEditor >>',
        ),
      ),
    ],
  );
}

/// Produces all [TextStyle]s for the editor in wide mode.
TextStyle _editorStyleBuilderWide(Set<Attribution> attributions) {
  var result = const TextStyle(
    fontFamily: 'Aeonik',
    fontWeight: FontWeight.w400,
    fontSize: 18,
    height: 27 / 18,
    color: Color(0xFF003F51),
  );

  for (final attribution in attributions) {
    if (attribution == header1Attribution) {
      result = result.copyWith(
        fontSize: 40,
        fontWeight: FontWeight.w700,
        height: 1.2,
      );
    } else if (attribution == header2Attribution) {
      result = result.copyWith(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        height: 1.2,
      );
    } else if (attribution == header3Attribution) {
      result = result.copyWith(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        height: 1.2,
      );
    } else if (attribution == blockquoteAttribution) {
      result = result.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.black54,
      );
    } else if (attribution == boldAttribution) {
      result = result.copyWith(fontWeight: FontWeight.bold);
    } else if (attribution == italicsAttribution) {
      result = result.copyWith(fontStyle: FontStyle.italic);
    } else if (attribution == strikethroughAttribution) {
      result = result.copyWith(decoration: TextDecoration.lineThrough);
    } else if (attribution == _underlineAttribution) {
      result = result.copyWith(decoration: TextDecoration.underline);
    }
  }
  return result;
}

/// Produces all [TextStyle]s for the editor in compact mode.
TextStyle _editorStyleBuilderCompact(Set<Attribution> attributions) {
  var result = const TextStyle(
    fontFamily: 'Aeonik',
    fontWeight: FontWeight.w400,
    fontSize: 18,
    height: 27 / 18,
    color: Color(0xFF003F51),
  );

  for (final attribution in attributions) {
    if (attribution == header1Attribution) {
      result = result.copyWith(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        height: 1.2,
      );
    } else if (attribution == header2Attribution) {
      result = result.copyWith(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        height: 1.2,
      );
    } else if (attribution == header3Attribution) {
      result = result.copyWith(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        height: 1.2,
      );
    } else if (attribution == blockquoteAttribution) {
      result = result.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.black54,
      );
    } else if (attribution == boldAttribution) {
      result = result.copyWith(fontWeight: FontWeight.bold);
    } else if (attribution == italicsAttribution) {
      result = result.copyWith(fontStyle: FontStyle.italic);
    } else if (attribution == strikethroughAttribution) {
      result = result.copyWith(decoration: TextDecoration.lineThrough);
    } else if (attribution == _underlineAttribution) {
      result = result.copyWith(decoration: TextDecoration.underline);
    }
  }
  return result;
}

/// Creates the display for a paragraph with a blockquote block style.
///
/// The editor offers a default styling and display for blockquotes,
/// but this editor wants to display a vertical bar on the left side
/// of the blockquote, so we override the default behavior with this
/// builder and provide a different widget tree.
///
/// If you only want to change the style of blockquote text, use
/// the text style builder in the [Editor], instead.
Widget _blockquoteBuilder(ComponentContext context) {
  final node = context.documentNode;

  if (node is ParagraphNode &&
      node.metadata['blockType'] == blockquoteAttribution) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          left: BorderSide(
            color: Colors.black26,
            width: 4,
          ),
        ),
      ),
      padding: const EdgeInsets.only(left: 8),
      child: paragraphBuilder(context),
    );
  }

  return null;
}
