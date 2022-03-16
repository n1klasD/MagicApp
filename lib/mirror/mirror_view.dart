import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:magic_app/mirror/mirror_edit.dart';
import 'package:magic_app/mirror/mirror_layout_handler.dart';
import 'package:magic_app/mirror/module_widget.dart';
import 'package:magic_app/util/text_types.dart';

import '../generated/l10n.dart';
import 'module.dart';

class MirrorView extends StatefulWidget {
  const MirrorView(
      {required this.height,
      this.enableClick = true,
      this.displayLoading = true,
      this.selectedModule,
      this.onModuleChanged = print,
      this.onModuleToCatalog = print,
      Key? key})
      : super(key: key);

  final double height;
  final bool enableClick;
  final bool displayLoading;
  final Module? selectedModule;
  final ValueChanged<Module?> onModuleChanged;

  /// A callback to inform the [MirrorEdit] that this module should be added to the catalog
  final Function(Module)? onModuleToCatalog;

  @override
  MirrorViewState createState() => MirrorViewState();
}

class MirrorViewState extends State<MirrorView> {
  // TODO: Convert this to a setting
  static const double mirrorRatio = 50 / 70;
  static final Iterable<ModulePosition> validModulePositions =
      ModulePosition.values.getRange(0, ModulePosition.values.length - 2);

  @override
  void initState() {
    super.initState();
    selectedModule = widget.selectedModule;

    // print("Loaded layout: $layout");
    // print(
    //     "MirrorView built with selected module $selectedModule (${widget.selectedModule}), enableClick: ${widget.enableClick}");
  }

  Module? selectedModule;

  Module? tempMovedModule;

  void openMirrorEdit(BuildContext context) {
    if (widget.enableClick && !widget.displayLoading) {
      Navigator.push(
        context,
        platformPageRoute(
          context: context,
          builder: (_) => MirrorEdit(
            selectedModule: selectedModule,
          ),
        ),
      );
    }
  }

  void setSelectedModule(Module? module, BuildContext context) {
    if (module != selectedModule) {
      setState(() {
        selectedModule = module;
      });

      widget.onModuleChanged(module);
    }

    openMirrorEdit(context);
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> modulesWidgets = [];
    for (ModulePosition modulePosition in validModulePositions) {
      dynamic targetChild = Container();

      if (MirrorLayoutHandler.isReady) {
        Module? m = MirrorLayoutHandler.layout.modules[modulePosition];

        if (m != null) {
          ModuleLayoutWidget moduleWidget = ModuleLayoutWidget(
            module: m,
            selectedCallback: setSelectedModule,
            isSelected: selectedModule != null &&
                m.name == selectedModule!.name &&
                !widget.enableClick,
          );

          targetChild = Draggable(
            data: m,
            maxSimultaneousDrags: widget.enableClick ? 0 : 1,
            child: moduleWidget,
            feedback: moduleWidget,
          );
        } else {
          // print("No module for position $modulePosition");
          targetChild = Container();
        }
      }

      modulesWidgets.add(
        Flexible(
          fit: FlexFit.tight,
          child: DragTarget(
            // Move module here if it's dropped on top of this target
            onAccept: (Module newModule) {
              setState(() {
                MirrorLayoutHandler.moveModule(newModule, modulePosition);
              });
            },

            // Swap the module if its hovering over this target
            onMove: (data) {
              // Grab the involved modules
              Module newModule = data.data as Module;

              setState(() {
                MirrorLayoutHandler.temporarilyMoveModule(
                  newModule,
                  modulePosition,
                );
              });
            },
            // Undo the temporary move if the module hover over this target ends
            onLeave: (data) {
              setState(() {
                MirrorLayoutHandler.undoTemporaryMove();
              });
            },
            builder: (_, __, ___) => targetChild,
          ),
        ),
      );
    }

    Container moduleContainer = Container(
      constraints: BoxConstraints(
        maxHeight: widget.height,
        maxWidth: widget.height * mirrorRatio,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          modulesWidgets[0],
          Flexible(
            fit: FlexFit.tight,
            child: Row(
              children: [
                modulesWidgets[1],
                modulesWidgets[2],
                modulesWidgets[3],
              ],
            ),
          ),
          modulesWidgets[4],
          modulesWidgets[5],
          modulesWidgets[6],
          Flexible(
            fit: FlexFit.tight,
            child: Row(
              children: [
                modulesWidgets[7],
                modulesWidgets[8],
                modulesWidgets[9],
              ],
            ),
          ),
          modulesWidgets[10],
        ],
      ),
      decoration: const BoxDecoration(
        color: Colors.black,
      ),
    );

    return widget.enableClick && !widget.displayLoading
        ? GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => openMirrorEdit(context),
            child: moduleContainer,
          )
        : widget.displayLoading
            ? Stack(
                alignment: Alignment.center,
                children: [
                  ImageFiltered(
                    imageFilter: ImageFilter.blur(
                      sigmaX: 0.55,
                      sigmaY: 0.55,
                    ),
                    child: moduleContainer,
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsetsDirectional.only(bottom: 25),
                        child: PlatformCircularProgressIndicator(),
                      ),
                      DefaultPlatformText(S.of(context).mirror_refresh)
                    ],
                  )
                ],
              )
            : moduleContainer;
  }
}
