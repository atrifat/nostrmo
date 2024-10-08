import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_image_viewer/easy_image_viewer.dart';
import 'package:flutter/material.dart';
import 'package:nostr_sdk/nip94/file_metadata.dart';
import 'package:nostr_sdk/utils/platform_util.dart';
import 'package:nostr_sdk/utils/string_util.dart';
import 'package:nostrmo/component/blurhash_image_component/blurhash_image_component.dart'
    if (dart.library.io) 'package:nostrmo/component/blurhash_image_component/blurhash_image_component_io.dart'
    if (dart.library.js) 'package:nostrmo/component/blurhash_image_component/blurhash_image_component_web.dart';
import 'package:nostrmo/component/cust_state.dart';
import 'package:nostrmo/consts/base_consts.dart';
import 'package:nostrmo/main.dart';

import '../../consts/base.dart';
import '../image_component.dart';
import '../image_preview_dialog.dart';

class ContentImageComponent extends StatefulWidget {
  String imageUrl;

  List<String>? imageList;

  int imageIndex;

  double? width;

  double? height;

  BoxFit imageBoxFix;

  FileMetadata? fileMetadata;

  ContentImageComponent({
    required this.imageUrl,
    this.imageList,
    this.imageIndex = 0,
    this.width,
    this.height,
    this.imageBoxFix = BoxFit.cover,
    this.fileMetadata,
  });

  @override
  State<StatefulWidget> createState() {
    return _ContentImageComponent();
  }
}

class _ContentImageComponent extends CustState<ContentImageComponent> {
  Future<void> onReady(BuildContext context) async {}

  @override
  Widget doBuild(BuildContext context) {
    var themeData = Theme.of(context);

    Widget? main;
    Widget? placeholder;
    // needn't get from provider
    if (settingProvider.openBlurhashImage != OpenStatus.CLOSE &&
        (widget.fileMetadata != null &&
            StringUtil.isNotBlank(widget.fileMetadata!.blurhash)) &&
        !PlatformUtil.isWeb()) {
      placeholder = genBlurhashImageComponent(
          widget.fileMetadata!, themeData.hintColor, widget.imageBoxFix);
    }
    main = GestureDetector(
      onTap: () {
        previewImages(context);
      },
      child: Center(
        child: ImageComponent(
          imageUrl: widget.imageUrl,
          fit: widget.imageBoxFix,
          width: widget.width,
          height: widget.height,
          placeholder:
              placeholder != null ? (context, url) => placeholder! : null,
        ),
      ),
    );

    return Container(
      width: widget.width,
      height: widget.height,
      margin: const EdgeInsets.only(
        top: Base.BASE_PADDING_HALF / 2,
        bottom: Base.BASE_PADDING_HALF / 2,
      ),
      child: main,
    );
  }

  void previewImages(context) {
    if (widget.imageList == null || widget.imageList!.isEmpty) {
      widget.imageList = [widget.imageUrl];
    }

    List<ImageProvider> imageProviders = [];
    for (var imageUrl in widget.imageList!) {
      imageProviders.add(CachedNetworkImageProvider(imageUrl));
    }

    MultiImageProvider multiImageProvider =
        MultiImageProvider(imageProviders, initialIndex: widget.imageIndex);

    ImagePreviewDialog.show(context, multiImageProvider,
        doubleTapZoomable: true, swipeDismissible: true);
  }
}
