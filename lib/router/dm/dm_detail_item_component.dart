import 'package:flutter/material.dart';
import 'package:get_time_ago/get_time_ago.dart';
import 'package:nostr_sdk/event.dart';
import 'package:nostr_sdk/event_kind.dart';
import 'package:nostrmo/component/content/content_component.dart';
import 'package:nostrmo/component/content/content_decoder.dart';
import 'package:nostrmo/consts/router_path.dart';
import 'package:nostrmo/util/router_util.dart';
import 'package:pointycastle/export.dart' as pointycastle;
import 'package:provider/provider.dart';

import '../../component/user/user_pic_component.dart';
import '../../consts/base.dart';
import '../../consts/base_consts.dart';
import '../../main.dart';
import '../../provider/setting_provider.dart';
import 'package:nostr_sdk/utils/string_util.dart';
import 'dm_plaintext_handle.dart';

class DMDetailItemComponent extends StatefulWidget {
  String sessionPubkey;

  Event event;

  bool isLocal;

  DMDetailItemComponent({
    required this.sessionPubkey,
    required this.event,
    required this.isLocal,
  });

  @override
  State<StatefulWidget> createState() {
    return _DMDetailItemComponent();
  }
}

class _DMDetailItemComponent extends State<DMDetailItemComponent>
    with DMPlaintextHandle {
  static const double IMAGE_WIDTH = 34;

  static const double BLANK_WIDTH = 50;

  @override
  Widget build(BuildContext context) {
    var _settingProvider = Provider.of<SettingProvider>(context);
    var themeData = Theme.of(context);
    var mainColor = themeData.primaryColor;
    Widget userHeadWidget = Container(
      margin: const EdgeInsets.only(top: 2),
      child: UserPicComponent(
        pubkey: widget.event.pubkey,
        width: IMAGE_WIDTH,
      ),
    );
    // var maxWidth = mediaDataCache.size.width;
    var smallTextSize = themeData.textTheme.bodySmall!.fontSize;
    var hintColor = themeData.hintColor;

    String timeStr = GetTimeAgo.parse(
        DateTime.fromMillisecondsSinceEpoch(widget.event.createdAt * 1000));

    if (currentPlainEventId != widget.event.id) {
      plainContent = null;
    }

    var content = widget.event.content;
    if (widget.event.kind == EventKind.DIRECT_MESSAGE &&
        StringUtil.isBlank(plainContent)) {
      handleEncryptedText(widget.event, widget.sessionPubkey);
    }
    if (StringUtil.isNotBlank(plainContent)) {
      content = plainContent!;
    }
    content = content.replaceAll("\r", " ");
    content = content.replaceAll("\n", " ");

    var timeWidget = Text(
      timeStr,
      style: TextStyle(
        color: hintColor,
        fontSize: smallTextSize,
      ),
    );
    Widget enhancedIcon = Container();
    if (widget.event.kind == EventKind.PRIVATE_DIRECT_MESSAGE) {
      enhancedIcon = Container(
        margin: const EdgeInsets.only(
          left: Base.BASE_PADDING_HALF,
          right: Base.BASE_PADDING_HALF,
        ),
        child: Icon(
          Icons.enhanced_encryption,
          size: smallTextSize! + 2,
          color: hintColor,
        ),
      );
    }
    List<Widget> topList = [];
    if (widget.isLocal) {
      topList.add(enhancedIcon);
      topList.add(timeWidget);
    } else {
      topList.add(timeWidget);
      topList.add(enhancedIcon);
    }

    var contentWidget = Container(
      margin: const EdgeInsets.only(
        left: Base.BASE_PADDING_HALF,
        right: Base.BASE_PADDING_HALF,
      ),
      child: Column(
        crossAxisAlignment:
            !widget.isLocal ? CrossAxisAlignment.start : CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: topList,
          ),
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.only(
              top: Base.BASE_PADDING_HALF - 1,
              right: Base.BASE_PADDING_HALF,
              bottom: Base.BASE_PADDING_HALF,
              left: Base.BASE_PADDING_HALF + 1,
            ),
            // constraints:
            //     BoxConstraints(maxWidth: (maxWidth - IMAGE_WIDTH) * 0.85),
            decoration: BoxDecoration(
              // color: Colors.red,
              color: mainColor.withOpacity(0.3),
              borderRadius: const BorderRadius.all(Radius.circular(5)),
            ),
            // child: SelectableText(content),
            child: Column(
              crossAxisAlignment: widget.isLocal
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                ContentComponent(
                  content: content,
                  event: widget.event,
                  showLinkPreview:
                      _settingProvider.linkPreview == OpenStatus.OPEN,
                  smallest: true,
                ),
              ],
              // children: ContentDecoder.decode(
              //   context,
              //   content,
              //   widget.event,
              //   showLinkPreview:
              //       _settingProvider.linkPreview == OpenStatus.OPEN,
              // ),
            ),
          ),
        ],
      ),
    );

    // if (!widget.isLocal) {
    userHeadWidget = GestureDetector(
      onTap: () {
        RouterUtil.router(context, RouterPath.USER, widget.event.pubkey);
      },
      child: userHeadWidget,
    );
    // }

    List<Widget> list = [];
    if (widget.isLocal) {
      list.add(Container(width: BLANK_WIDTH));
      list.add(Expanded(child: contentWidget));
      list.add(userHeadWidget);
    } else {
      list.add(userHeadWidget);
      list.add(Expanded(child: contentWidget));
      list.add(Container(width: BLANK_WIDTH));
    }

    return Container(
      padding: EdgeInsets.all(Base.BASE_PADDING_HALF),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: list,
      ),
    );
  }
}
