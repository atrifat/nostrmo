import 'package:nostrmo/client/relay_pool.dart';
import 'package:nostrmo/util/string_util.dart';

import 'client_utils/keys.dart';
import 'event.dart';
import 'event_kind.dart';
import 'nip02/cust_contact_list.dart';
import 'relay.dart';

class Nostr {
  String? _privateKey;

  late String _publicKey;

  late RelayPool _pool;

  Nostr({
    String? privateKey,
    String? publicKey,
    bool eventVerification = false,
  }) {
    if (StringUtil.isNotBlank(privateKey)) {
      _privateKey = privateKey!;
      _publicKey = getPublicKey(privateKey);
    } else {
      assert(publicKey != null);

      _privateKey = privateKey;
      _publicKey = publicKey!;
    }
    _pool = RelayPool(this, eventVerification);
  }

  String? get privateKey => _privateKey;

  String get publicKey => _publicKey;

  Event sendLike(String id) {
    Event event = Event(
        _publicKey,
        EventKind.REACTION,
        [
          ["e", id]
        ],
        "+");
    return sendEvent(event);
  }

  Event deleteEvent(String eventId) {
    Event event = Event(
        _publicKey,
        EventKind.EVENT_DELETION,
        [
          ["e", eventId]
        ],
        "delete");
    return sendEvent(event);
  }

  Event deleteEvents(List<String> eventIds) {
    List<List<dynamic>> tags = [];
    for (var eventId in eventIds) {
      tags.add(["e", eventId]);
    }

    Event event = Event(_publicKey, EventKind.EVENT_DELETION, tags, "delete");
    return sendEvent(event);
  }

  Event sendRepost(String id) {
    Event event = Event(
        _publicKey,
        EventKind.REPOST,
        [
          ["e", id]
        ],
        "#[0]");
    return sendEvent(event);
  }

  Event sendTextNote(String text, [List<dynamic> tags = const []]) {
    Event event = Event(_publicKey, EventKind.TEXT_NOTE, tags, text);
    return sendEvent(event);
  }

  Event recommendServer(String url) {
    if (!url.contains(RegExp(
        r'^(wss?:\/\/)([0-9]{1,3}(?:\.[0-9]{1,3}){3}|[^:]+):?([0-9]{1,5})?$'))) {
      throw ArgumentError.value(url, 'url', 'Not a valid relay URL');
    }
    final event = Event(_publicKey, EventKind.RECOMMEND_SERVER, [], url);
    return sendEvent(event);
  }

  Event sendContactList(CustContactList contacts) {
    final tags = contacts.toJson();
    final event = Event(_publicKey, EventKind.CONTACT_LIST, tags, "");
    return sendEvent(event);
  }

  Event sendEvent(Event event) {
    if (StringUtil.isBlank(_privateKey)) {
      // TODO to show Notice
      throw StateError("Private key is missing. Message can't be signed.");
    }
    event.sign(_privateKey!);
    _pool.send(["EVENT", event.toJson()]);
    return event;
  }

  Event broadcase(Event event) {
    _pool.send(["EVENT", event.toJson()]);
    return event;
  }

  void close() {
    _pool.removeAll();
  }

  void addInitQuery(List<Map<String, dynamic>> filters, Function(Event) onEvent,
      {String? id, Function? onComplete}) {
    _pool.addInitQuery(filters, onEvent, id: id, onComplete: onComplete);
  }

  String subscribe(List<Map<String, dynamic>> filters, Function(Event) onEvent,
      {String? id}) {
    return _pool.subscribe(filters, onEvent, id: id);
  }

  void unsubscribe(String id) {
    _pool.unsubscribe(id);
  }

  String query(List<Map<String, dynamic>> filters, Function(Event) onEvent,
      {String? id, Function? onComplete}) {
    return _pool.query(filters, onEvent, id: id, onComplete: onComplete);
  }

  Future<bool> addRelay(
    Relay relay, {
    bool autoSubscribe = false,
    bool init = false,
  }) async {
    return await _pool.add(relay, autoSubscribe: autoSubscribe, init: init);
  }

  void removeRelay(String url) {
    _pool.remove(url);
  }
}