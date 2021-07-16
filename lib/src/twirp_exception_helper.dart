import 'twirp_exception.dart';

final errorCodeToStringMap = <ErrorCode, String>{
  ErrorCode.Cancelled: 'canceled',
  ErrorCode.Unknown: 'unknown',
  ErrorCode.InvalidArgument: 'invalid_argument',
  ErrorCode.Malformed: 'malformed',
  ErrorCode.DeadlineExceeded: 'deadline_exceeded',
  ErrorCode.NotFound: 'not_found',
  ErrorCode.BadRoute: 'bad_route',
  ErrorCode.AlreadyExists: 'already_exists',
  ErrorCode.PermissionDenied: 'permission_denied',
  ErrorCode.Unauthenticated: 'unauthenticated',
  ErrorCode.ResourceExhausted: 'resource_exhausted',
  ErrorCode.FailedPrecondition: 'failed_precondition',
  ErrorCode.Aborted: 'aborted',
  ErrorCode.OutOfRange: 'out_of_range',
  ErrorCode.Unimplemented: 'unimplemented',
  ErrorCode.Internal: 'internal',
  ErrorCode.Unavailable: 'unavailable',
  ErrorCode.Dataloss: 'dataloss'
};

final stringToErrorCodeMap = <String, ErrorCode>{
  'canceled': ErrorCode.Cancelled,
  'unknown': ErrorCode.Unknown,
  'invalid_argument': ErrorCode.InvalidArgument,
  'malformed': ErrorCode.Malformed,
  'deadline_exceeded': ErrorCode.DeadlineExceeded,
  'not_found': ErrorCode.NotFound,
  'bad_route': ErrorCode.BadRoute,
  'already_exists': ErrorCode.AlreadyExists,
  'permission_denied': ErrorCode.PermissionDenied,
  'unauthenticated': ErrorCode.Unauthenticated,
  'resource_exhausted': ErrorCode.ResourceExhausted,
  'failed_precondition': ErrorCode.FailedPrecondition,
  'aborted': ErrorCode.Aborted,
  'out_of_range': ErrorCode.OutOfRange,
  'unimplemented': ErrorCode.Unimplemented,
  'internal': ErrorCode.Internal,
  'unavailable': ErrorCode.Unavailable,
  'dataloss': ErrorCode.Dataloss,
};
