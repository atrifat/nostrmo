import 'package:nostrmo/client/event.dart';
import 'package:nostrmo/client/signer/nostr_signer.dart';

class PubkeyOnlyNostrSigner implements NostrSigner {
  String pubkey;

  PubkeyOnlyNostrSigner(this.pubkey);

  @override
  Future<String?> decrypt(pubkey, ciphertext) {
    return pubkey;
  }

  @override
  Future<String?> encrypt(pubkey, plaintext) async {
    return null;
  }

  @override
  Future<String?> getPublicKey() async {
    return null;
  }

  @override
  Future<Map?> getRelays() async {
    return null;
  }

  @override
  Future<Event?> signEvent(Event event) async {
    return null;
  }

  @override
  Future<String?> nip44Decrypt(pubkey, ciphertext) async {
    return null;
  }

  @override
  Future<String?> nip44Encrypt(pubkey, plaintext) async {
    return null;
  }
}
