part of corsac_rpc;

class ApiError {
  final int statusCode;
  final String message;
  final List<String> errors;
  final exception;
  final StackTrace stackTrace;

  ApiError(this.statusCode, this.message,
      {this.errors, this.exception, this.stackTrace});

  @override
  String toString() => message;
}

class NotFoundApiError extends ApiError {
  NotFoundApiError([String message = 'Requested resource not found.'])
      : super(HttpStatus.NOT_FOUND, message);
}

class BadRequestApiError extends ApiError {
  BadRequestApiError(List<String> errors, [String message = 'Bad request.'])
      : super(HttpStatus.BAD_REQUEST, message, errors: errors);
}

class InternalServerApiError extends ApiError {
  InternalServerApiError(exception, StackTrace stackTrace,
      [String message = 'Internal server error.'])
      : super(HttpStatus.INTERNAL_SERVER_ERROR, message,
            exception: exception, stackTrace: stackTrace);
}
