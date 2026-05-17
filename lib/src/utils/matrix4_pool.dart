import 'package:vector_math/vector_math_64.dart';

/// Lightweight Matrix4 pooling utility.
/// Use `Matrix4Pool.acquire()` to get a reusable Matrix4 you can mutate
/// for temporary calculations. Do NOT store the returned instance across
/// frames or async boundaries; copy values if you need to keep them.
class Matrix4Pool {
  static final Matrix4 _tmp = Matrix4.identity();

  /// Acquire a temporary Matrix4 initialized to identity.
  /// The same instance is returned on every call to minimize allocations.
  static Matrix4 acquire() {
    _tmp.setIdentity();
    return _tmp;
  }
}
