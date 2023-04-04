import 'package:flutter/material.dart';
import 'package:nostrmo/component/placeholder/metadata_placeholder.dart';

class MetadataListPlaceholder extends StatelessWidget {
  Function? onRefresh;

  MetadataListPlaceholder({this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        if (onRefresh != null) {
          onRefresh!();
        }
      },
      child: ListView.builder(
        itemBuilder: (BuildContext context, int index) {
          return MetadataPlaceholder();
        },
        itemCount: 10,
      ),
    );
  }
}
