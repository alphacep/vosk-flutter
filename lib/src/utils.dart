import 'dart:convert';
import 'dart:ffi';
import 'dart:typed_data';

/// FFI related string utils.
extension FFIStringUtils on String {
  /// Convert to a [Char] pointer. [allocator] is used for memory allocation.
  Pointer<Char> toCharPtr(Allocator allocator) {
    return utf8.encode(this).toCharPtr(allocator);
  }
}

/// FFI related int list utils.
extension FFIIntListUtils on List<int> {
  /// Convert to a [Char] pointer. [allocator] is used for memory allocation.
  Pointer<Char> toCharPtr(Allocator allocator) {
    final nativeLength = length + 1;
    final result = allocator<Uint8>(nativeLength);
    result.asTypedList(nativeLength)
      ..setAll(0, this) // copy
      ..last = 0; // zero terminate
    return result.cast();
  }
}

/// FFI related float list utils.
extension FFIFloatListUtils on Float32List {
  /// Convert to a [Float] pointer. [allocator] is used for memory allocation.
  Pointer<Float> toFloatPtr(Allocator allocator) {
    final nativeSize = length + 1;
    final result = allocator<Float>(nativeSize);
    result.asTypedList(nativeSize)
      ..setAll(0, this) // copy
      ..last = 0; // zero terminate
    return result.cast();
  }
}

/// FFI related char pointer utils.
extension FFICharPointerUtils on Pointer<Char> {
  /// Convert a zero terminated char string to a Dart String.
  String? toDartString() {
    if (this == nullptr) {
      return null;
    }

    final codeUnits = cast<Uint8>();
    return utf8.decode(codeUnits.asTypedList(_length(codeUnits)));
  }

  static int _length(Pointer<Uint8> codeUnits) {
    var length = 0;
    while (codeUnits[length] != 0) {
      length++;
    }
    return length;
  }
}
