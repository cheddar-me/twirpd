enum ErrorCode {
  Cancelled,
  Unknown,
  InvalidArgument,
  Malformed,
  DeadlineExceeded,
  NotFound,
  BadRoute,
  AlreadyExists,
  PermissionDenied,
  Unauthenticated,
  ResourceExhausted,
  FailedPrecondition,
  Aborted,
  OutOfRange,
  Unimplemented,
  Internal,
  Unavailable,
  Dataloss
}

class TwirpException implements Exception {
  final ErrorCode code;
  final String message;
  final Map<String, String> metadata;

  TwirpException(this.code, this.message, Map<String, String> metadata)
      : metadata = Map.unmodifiable(metadata);

  TwirpException.cancelled([String? message, Map<String, String>? metadata])
      : this(ErrorCode.Cancelled, message ?? 'canceled', metadata ?? {});

  TwirpException.unknown([String? message, Map<String, String>? metadata])
      : this(ErrorCode.Unknown, message ?? 'unknown', metadata ?? {});

  TwirpException.internal([String? message, Map<String, String>? metadata])
      : this(ErrorCode.Internal, message ?? 'internal', metadata ?? {});

  TwirpException.invalidArgument(
      [String? message, Map<String, String>? metadata])
      : this(ErrorCode.InvalidArgument, message ?? 'invalid_argument',
            metadata ?? {});

  TwirpException.unauthenticated(
      [String? message, Map<String, String>? metadata])
      : this(ErrorCode.Unauthenticated, message ?? 'unauthenticated',
            metadata ?? {});

  TwirpException.permissionDenied(
      [String? message, Map<String, String>? metadata])
      : this(ErrorCode.PermissionDenied, message ?? 'permission_denied',
            metadata ?? {});

  @override
  String toString() => 'TwirpException: $message, code: $code, metadata: $metadata';
}
