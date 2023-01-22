// ignore_for_file: prefer_void_to_null, avoid_positional_boolean_parameters

Null throwOrNull(
    Object error,
    bool willThrow,
    ) {
  if (willThrow) {
    // ignore: only_throw_errors
    throw error;
  }

  return null;
}