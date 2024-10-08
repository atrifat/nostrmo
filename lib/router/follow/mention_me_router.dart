import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:nostr_sdk/event_kind.dart';
import 'package:nostr_sdk/event_mem_box.dart';
import 'package:nostr_sdk/event_relation.dart';
import 'package:nostr_sdk/utils/string_util.dart';
import 'package:nostrmo/component/cust_state.dart';
import 'package:nostrmo/component/event/zap_event_main_component.dart';
import 'package:nostrmo/component/keep_alive_cust_state.dart';
import 'package:nostrmo/main.dart';
import 'package:nostrmo/provider/mention_me_new_provider.dart';
import 'package:nostrmo/provider/mention_me_provider.dart';
import 'package:nostrmo/util/load_more_event.dart';
import 'package:nostrmo/util/spider_util.dart';
import 'package:provider/provider.dart';

import '../../component/badge_award_component.dart';
import '../../component/event/event_list_component.dart';
import '../../component/event/zap_event_list_component.dart';
import '../../component/new_notes_updated_component.dart';
import '../../component/placeholder/event_list_placeholder.dart';
import '../../component/placeholder/event_placeholder.dart';
import '../../consts/base.dart';
import '../../consts/base_consts.dart';
import '../../consts/router_path.dart';
import '../../provider/setting_provider.dart';
import '../../util/router_util.dart';
import '../../util/table_mode_util.dart';

class MentionMeRouter extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _MentionMeRouter();
  }
}

class _MentionMeRouter extends KeepAliveCustState<MentionMeRouter>
    with LoadMoreEvent {
  ScrollController _controller = ScrollController();

  @override
  void initState() {
    super.initState();
    bindLoadMoreScroll(_controller);
  }

  @override
  Widget doBuild(BuildContext context) {
    var _settingProvider = Provider.of<SettingProvider>(context);
    var _mentionMeProvider = Provider.of<MentionMeProvider>(context);
    var eventBox = _mentionMeProvider.eventBox;
    var events = eventBox.all();
    if (events.isEmpty) {
      return EventListPlaceholder(
        onRefresh: () {
          mentionMeProvider.refresh();
        },
      );
    }
    indexProvider.setMentionedScrollController(_controller);
    preBuild();

    var main = ListView.builder(
      controller: _controller,
      itemBuilder: (BuildContext context, int index) {
        var event = events[index];
        if (event.kind == EventKind.BADGE_AWARD) {
          return BadgeAwardComponent(event: event);
        } else {
          if (event.kind == EventKind.ZAP) {
            if (StringUtil.isBlank(event.content)) {
              var innerZapContent = EventRelation.getInnerZapContent(event);
              if (StringUtil.isBlank(innerZapContent)) {
                return ZapEventListComponent(event: event);
              }
            }
          }

          return EventListComponent(
            event: event,
            showVideo: _settingProvider.videoPreviewInList != OpenStatus.CLOSE,
          );
        }
      },
      itemCount: events.length,
    );

    Widget ri = RefreshIndicator(
      onRefresh: () async {
        mentionMeProvider.refresh();
      },
      child: main,
    );

    if (TableModeUtil.isTableMode()) {
      ri = GestureDetector(
        onVerticalDragUpdate: (detail) {
          _controller.jumpTo(_controller.offset - detail.delta.dy);
        },
        behavior: HitTestBehavior.translucent,
        child: ri,
      );
    }

    List<Widget> stackList = [ri];
    stackList.add(Positioned(
      top: Base.BASE_PADDING,
      child: Selector<MentionMeNewProvider, int>(
        builder: (context, newEventNum, child) {
          if (newEventNum <= 0) {
            return Container();
          }

          return NewNotesUpdatedComponent(
            num: newEventNum,
            onTap: () {
              mentionMeProvider.mergeNewEvent();
              _controller.jumpTo(0);
            },
          );
        },
        selector: (context, _provider) {
          return _provider.eventMemBox.length();
        },
      ),
    ));
    return Stack(
      alignment: Alignment.center,
      children: stackList,
    );
  }

  @override
  void doQuery() {
    preQuery();
    mentionMeProvider.doQuery(until: until);
  }

  @override
  EventMemBox getEventBox() {
    return mentionMeProvider.eventBox;
  }

  @override
  Future<void> onReady(BuildContext context) async {}
}
