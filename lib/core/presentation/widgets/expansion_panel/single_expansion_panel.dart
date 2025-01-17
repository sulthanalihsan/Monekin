import 'package:monekin/core/presentation/widgets/expansion_panel/expansion_panel_without_icon.dart';
import 'package:flutter/material.dart';

class SingleExpansionPanel extends StatefulWidget {
  const SingleExpansionPanel(
      {super.key, required this.child, this.sidePadding = 0});

  final Widget child;
  final double sidePadding;

  @override
  State<SingleExpansionPanel> createState() => _SingleExpansionPanelState();
}

class _SingleExpansionPanelState extends State<SingleExpansionPanel> {
  bool expanded = false;

  @override
  Widget build(BuildContext context) {
    return ExpansionPanelListWithoutIcon(
      elevation: 0,
      expansionCallback: (panelIndex, isExpanded) {
        setState(() {
          expanded = !expanded;
        });
      },
      children: [
        ExpansionPanel(
          // canTapOnHeader: true,
          headerBuilder: (context, isExpanded) {
            return Padding(
              padding: EdgeInsets.symmetric(
                  vertical: 0, horizontal: widget.sidePadding),
              child: Row(
                children: [
                  const Expanded(child: Divider()),
                  TextButton.icon(
                      onPressed: () {
                        setState(() {
                          expanded = !expanded;
                        });
                      },
                      icon: AnimatedRotation(
                          duration: const Duration(milliseconds: 250),
                          turns: expanded ? 0.5 : 0,
                          child: const Icon(Icons.arrow_drop_down)),
                      label: Text(expanded
                          ? 'Mostrar menos campos'
                          : 'Mostrar mas campos')),
                  const Expanded(child: Divider()),
                ],
              ),
            );
          },
          body: widget.child, isExpanded: expanded,
        ),
      ],
    );
  }
}
