library native_extension_with_stream.sample_extension;

import "dart-ext:sample_extension";
import "dart:async";

class NativeStream {
  static Stream<int> createStream(Iterable<int> collection) {
    if (collection == null) {
      throw new ArgumentError("collection: $collection");
    }

    return _createStream(collection);
  }

  static Stream<int> _createStream(Iterable<int> collection) native
      "CreateStream";
}
