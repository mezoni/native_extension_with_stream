import "package:lists/lists.dart";
import "package:native_extension_with_stream/sample_extension.dart";

void main() {
  print("Range from 0 to 5");
  var stream = NativeStream.createStream(new RangeList(0, 5));
  stream.listen((data) {
    print(data);
  }, onDone: () {
    print("Collection from -5 to 5 with step 2");
    var stream = NativeStream.createStream(new StepList(-5, 5, 2));
    stream.listen((data) {
      print(data);
    });
  });
}
