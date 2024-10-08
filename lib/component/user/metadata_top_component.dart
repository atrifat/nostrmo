import 'package:bot_toast/bot_toast.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_image_viewer/easy_image_viewer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nostr_sdk/event_relation.dart';
import 'package:nostr_sdk/nip19/nip19.dart';
import 'package:nostr_sdk/nip19/nip19_tlv.dart';
import 'package:nostr_sdk/utils/platform_util.dart';
import 'package:nostrmo/component/follow_set_follow_bottom_sheet.dart';
import 'package:nostrmo/component/nip05_valid_component.dart';
import 'package:nostrmo/component/qrcode_dialog.dart';
import 'package:nostrmo/component/user/user_pic_component.dart';
import 'package:nostrmo/component/webview_router.dart';
import 'package:nostrmo/consts/router_path.dart';
import 'package:nostrmo/generated/l10n.dart';
import 'package:nostrmo/main.dart';
import 'package:nostrmo/provider/contact_list_provider.dart';
import 'package:nostrmo/util/router_util.dart';
import 'package:nostrmo/util/table_mode_util.dart';
import 'package:provider/provider.dart';

import '../../consts/base.dart';
import '../../data/metadata.dart';
import 'package:nostr_sdk/utils/string_util.dart';
import '../confirm_dialog.dart';
import '../image_component.dart';
import '../image_preview_dialog.dart';
import '../zap/zap_bottom_sheet_component.dart';
import 'follow_btn_component.dart';
import 'metadata_component.dart';

class MetadataTopComponent extends StatefulWidget {
  static double getPcBannerHeight(double maxHeight) {
    var height = maxHeight * 0.2;
    if (height > 200) {
      return 200;
    }

    return height;
  }

  String pubkey;

  Metadata? metadata;

  // is local user
  bool isLocal;

  bool jumpable;

  bool userPicturePreview;

  MetadataTopComponent({
    required this.pubkey,
    this.metadata,
    this.isLocal = false,
    this.jumpable = false,
    this.userPicturePreview = false,
  });

  @override
  State<StatefulWidget> createState() {
    return _MetadataTopComponent();
  }
}

class _MetadataTopComponent extends State<MetadataTopComponent> {
  static const double IMAGE_BORDER = 4;

  static const double IMAGE_WIDTH = 80;

  static const double HALF_IMAGE_WIDTH = 40;

  late String nip19PubKey;

  @override
  void initState() {
    super.initState();

    nip19PubKey = Nip19.encodePubKey(widget.pubkey);
  }

  @override
  Widget build(BuildContext context) {
    var themeData = Theme.of(context);
    var mainColor = themeData.primaryColor;
    var hintColor = themeData.hintColor;
    var scaffoldBackgroundColor = themeData.scaffoldBackgroundColor;
    var maxWidth = mediaDataCache.size.width;
    var largeFontSize = themeData.textTheme.bodyLarge!.fontSize;
    var fontSize = themeData.textTheme.bodyMedium!.fontSize;
    var bannerHeight = maxWidth / 3;
    if (TableModeUtil.isTableMode()) {
      bannerHeight =
          MetadataTopComponent.getPcBannerHeight(mediaDataCache.size.height);
    }

    String nip19Name = Nip19.encodeSimplePubKey(widget.pubkey);
    String displayName = "";
    String? name;
    if (widget.metadata != null) {
      if (StringUtil.isNotBlank(widget.metadata!.displayName)) {
        displayName = widget.metadata!.displayName!;
        if (StringUtil.isNotBlank(widget.metadata!.name)) {
          name = widget.metadata!.name;
        }
      } else if (StringUtil.isNotBlank(widget.metadata!.name)) {
        displayName = widget.metadata!.name!;
      }
    }

    Widget? bannerImage;
    if (widget.metadata != null &&
        StringUtil.isNotBlank(widget.metadata!.banner)) {
      bannerImage = ImageComponent(
        imageUrl: widget.metadata!.banner!,
        width: maxWidth,
        height: bannerHeight,
        fit: BoxFit.cover,
      );
    }

    List<Widget> topBtnList = [
      Expanded(
        child: Container(),
      )
    ];

    if (!TableModeUtil.isTableMode() && widget.pubkey == nostr!.publicKey) {
      // is phont and local
      topBtnList.add(wrapBtn(MetadataIconBtn(
        iconData: Icons.qr_code_scanner,
        onTap: handleScanner,
      )));
    }

    topBtnList.add(wrapBtn(MetadataIconBtn(
      iconData: Icons.qr_code,
      onTap: () {
        QrcodeDialog.show(context, widget.pubkey);
      },
    )));

    if (!widget.isLocal) {
      if (widget.metadata != null &&
          (StringUtil.isNotBlank(widget.metadata!.lud06) ||
              StringUtil.isNotBlank(widget.metadata!.lud16))) {
        topBtnList.add(wrapBtn(MetadataIconBtn(
          onTap: openZapDialog,
          iconData: Icons.currency_bitcoin,
        )));
      }

      topBtnList.add(wrapBtn(MetadataIconBtn(
        iconData: Icons.mail,
        onTap: openDMSession,
      )));
      topBtnList.add(wrapBtn(FollowBtnComponent(
        pubkey: widget.pubkey,
        followedBorderColor: mainColor,
      )));
    }

    if (StringUtil.isBlank(displayName)) {
      displayName = nip19Name;
    }
    List<TextSpan> nameSpans = [];
    nameSpans.add(TextSpan(
      text: displayName,
      style: TextStyle(
        fontSize: largeFontSize,
        fontWeight: FontWeight.bold,
      ),
    ));
    if (StringUtil.isNotBlank(name)) {
      nameSpans.add(TextSpan(
        text: name != null ? "@$name" : "",
        style: TextStyle(
          fontSize: fontSize,
          color: hintColor,
        ),
      ));
    }

    Widget userNameComponent = Container(
      // height: 40,
      width: double.maxFinite,
      margin: const EdgeInsets.only(
        left: Base.BASE_PADDING,
        right: Base.BASE_PADDING,
        // top: Base.BASE_PADDING_HALF,
        bottom: Base.BASE_PADDING_HALF,
      ),
      // color: Colors.green,
      child: Text.rich(
        TextSpan(
          children: nameSpans,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
    if (widget.jumpable) {
      userNameComponent = GestureDetector(
        onTap: jumpToUserRouter,
        child: userNameComponent,
      );
    }

    List<Widget> topList = [];
    topList.add(Container(
      width: maxWidth,
      height: bannerHeight,
      color: hintColor.withOpacity(0.5),
      child: bannerImage,
    ));
    topList.add(Container(
      height: 50,
      // color: Colors.red,
      child: Row(
        children: topBtnList,
      ),
    ));
    topList.add(userNameComponent);
    if (widget.metadata != null) {
      topList.add(MetadataIconDataComp(
        iconData: Icons.key,
        text: nip19PubKey,
        textBG: true,
        onTap: copyPubKey,
      ));
      if (StringUtil.isNotBlank(widget.metadata!.nip05)) {
        topList.add(MetadataIconDataComp(
          text: widget.metadata!.nip05!,
          leftWidget: Container(
            margin: const EdgeInsets.only(right: 2),
            child: Nip05ValidComponent(pubkey: widget.pubkey),
          ),
        ));
      }
      if (widget.metadata != null) {
        if (StringUtil.isNotBlank(widget.metadata!.website)) {
          topList.add(MetadataIconDataComp(
            iconData: Icons.link,
            text: widget.metadata!.website!,
            onTap: () {
              WebViewRouter.open(context, widget.metadata!.website!);
            },
          ));
        }
        if (StringUtil.isNotBlank(widget.metadata!.lud16)) {
          topList.add(MetadataIconDataComp(
            iconData: Icons.bolt,
            iconColor: Colors.orange,
            text: widget.metadata!.lud16!,
          ));
        }
      }
    }

    Widget userImageWidget = UserPicComponent(
      pubkey: widget.pubkey,
      width: IMAGE_WIDTH,
      metadata: widget.metadata,
    );
    if (widget.userPicturePreview) {
      userImageWidget = GestureDetector(
        onTap: userPicturePreview,
        child: userImageWidget,
      );
    } else if (widget.jumpable) {
      userImageWidget = GestureDetector(
        onTap: jumpToUserRouter,
        child: userImageWidget,
      );
    }

    return Stack(
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          children: topList,
        ),
        Positioned(
          left: Base.BASE_PADDING,
          top: bannerHeight - HALF_IMAGE_WIDTH,
          child: Container(
            height: IMAGE_WIDTH + IMAGE_BORDER * 2,
            width: IMAGE_WIDTH + IMAGE_BORDER * 2,
            decoration: BoxDecoration(
              borderRadius:
                  BorderRadius.circular(HALF_IMAGE_WIDTH + IMAGE_BORDER),
              border: Border.all(
                width: IMAGE_BORDER,
                color: scaffoldBackgroundColor,
              ),
            ),
            child: userImageWidget,
          ),
        )
      ],
    );
  }

  Widget wrapBtn(Widget child) {
    return Container(
      margin: EdgeInsets.only(right: 8),
      child: child,
    );
  }

  copyPubKey() {
    Clipboard.setData(ClipboardData(text: nip19PubKey)).then((_) {
      BotToast.showText(text: S.of(context).key_has_been_copy);
    });
  }

  void jumpToUserRouter() {
    RouterUtil.router(context, RouterPath.USER, widget.pubkey);
  }

  void openDMSession() {
    var detail = dmProvider.findOrNewADetail(widget.pubkey);
    RouterUtil.router(context, RouterPath.DM_DETAIL, detail);
  }

  Future<void> handleScanner() async {
    var result = await RouterUtil.router(context, RouterPath.QRSCANNER);
    if (StringUtil.isNotBlank(result)) {
      if (Nip19.isPubkey(result)) {
        var pubkey = Nip19.decode(result);
        RouterUtil.router(context, RouterPath.USER, pubkey);
      } else if (NIP19Tlv.isNprofile(result)) {
        var nprofile = NIP19Tlv.decodeNprofile(result);
        if (nprofile != null) {
          RouterUtil.router(context, RouterPath.USER, nprofile!.pubkey);
        }
      } else if (Nip19.isNoteId(result)) {
        var noteId = Nip19.decode(result);
        RouterUtil.router(context, RouterPath.EVENT_DETAIL, noteId);
      } else if (NIP19Tlv.isNevent(result)) {
        var nevent = NIP19Tlv.decodeNevent(result);
        if (nevent != null) {
          RouterUtil.router(context, RouterPath.EVENT_DETAIL, nevent.id);
        }
      } else if (NIP19Tlv.isNrelay(result)) {
        var nrelay = NIP19Tlv.decodeNrelay(result);
        if (nrelay != null) {
          var result = await ConfirmDialog.show(
              context, S.of(context).Add_this_relay_to_local);
          if (result == true) {
            relayProvider.addRelay(nrelay.addr);
          }
        }
      } else if (result.indexOf("http") == 0) {
        WebViewRouter.open(context, result);
      } else {
        Clipboard.setData(ClipboardData(text: result)).then((_) {
          BotToast.showText(text: S.of(context).Copy_success);
        });
      }
    }
  }

  void userPicturePreview() {
    if (widget.metadata != null &&
        StringUtil.isNotBlank(widget.metadata!.picture)) {
      List<ImageProvider> imageProviders = [];
      imageProviders.add(CachedNetworkImageProvider(widget.metadata!.picture!));

      MultiImageProvider multiImageProvider =
          MultiImageProvider(imageProviders, initialIndex: 0);

      ImagePreviewDialog.show(context, multiImageProvider,
          doubleTapZoomable: true, swipeDismissible: true);
    }
  }

  void openZapDialog() {
    List<EventZapInfo> list = [];
    String relayAddr = "";
    var relayListMetadata =
        metadataProvider.getRelayListMetadata(widget.pubkey);
    if (relayListMetadata != null &&
        relayListMetadata.writeAbleRelays.isNotEmpty) {
      relayAddr = relayListMetadata.writeAbleRelays.first;
    }
    list.add(EventZapInfo(widget.pubkey, relayAddr, 1));

    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      builder: (BuildContext _context) {
        return ZapBottomSheetComponent(context, list);
      },
    );
  }
}

class MetadataIconBtn extends StatelessWidget {
  void Function()? onTap;

  void Function()? onLongPress;

  IconData iconData;

  MetadataIconBtn({required this.iconData, this.onTap, this.onLongPress});

  @override
  Widget build(BuildContext context) {
    var themeData = Theme.of(context);

    var decoration = BoxDecoration(
      borderRadius: BorderRadius.circular(14),
      border: Border.all(
        width: 1,
        color: themeData.textTheme.bodyMedium!.color ?? Colors.black,
      ),
    );
    var main = Container(
      height: 28,
      width: 28,
      child: Icon(
        iconData,
        size: 18,
      ),
    );

    if (onTap != null || onLongPress != null) {
      // return Ink(
      //   decoration: decoration,
      //   child: InkWell(
      //     onTap: onTap,
      //     onLongPress: onLongPress,
      //     child: main,
      //   ),
      // );
      return GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
          decoration: decoration,
          child: main,
        ),
      );
    } else {
      return Container(
        decoration: decoration,
        child: main,
      );
    }
  }
}

class MetadataTextBtn extends StatelessWidget {
  void Function() onTap;

  void Function()? onLongPress;

  String text;

  Color? borderColor;

  MetadataTextBtn({
    required this.text,
    required this.onTap,
    this.onLongPress,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    var themeData = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      onLongPress: () {
        if (onLongPress != null) {
          onLongPress!();
        }
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: borderColor != null
              ? Border.all(width: 1, color: borderColor!)
              : Border.all(
                  width: 1,
                  color: themeData.textTheme.bodyMedium!.color ?? Colors.black,
                ),
        ),
        height: 32,
        padding: EdgeInsets.only(left: 8, right: 8, bottom: 1),
        alignment: Alignment.center,
        child: Text(
          text,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: borderColor,
          ),
        ),
      ),
    );
  }
}

class MetadataIconDataComp extends StatelessWidget {
  String text;

  IconData? iconData;

  Color? iconColor;

  bool textBG;

  Function? onTap;

  Widget? leftWidget;

  MetadataIconDataComp({
    required this.text,
    this.iconData,
    this.leftWidget,
    this.iconColor,
    this.textBG = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    var themeData = Theme.of(context);
    Color? cardColor = themeData.cardColor;
    if (cardColor == Colors.white) {
      cardColor = Colors.grey[300];
    }

    iconData ??= Icons.circle;

    return Container(
      padding: const EdgeInsets.only(
        bottom: Base.BASE_PADDING_HALF,
        left: Base.BASE_PADDING,
        right: Base.BASE_PADDING,
      ),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          if (onTap != null) {
            onTap!();
          }
        },
        child: Row(
          children: [
            Container(
              margin: const EdgeInsets.only(
                right: Base.BASE_PADDING_HALF,
              ),
              child: leftWidget ??
                  Icon(
                    iconData,
                    color: iconColor,
                    size: 16,
                  ),
            ),
            Expanded(
              child: Container(
                padding: textBG
                    ? const EdgeInsets.only(
                        left: Base.BASE_PADDING_HALF,
                        right: Base.BASE_PADDING_HALF,
                        top: 4,
                        bottom: 4,
                      )
                    : null,
                decoration: BoxDecoration(
                  color: textBG ? cardColor : null,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  text,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
