part of corsac_rpc;

class ApiError implements Exception {
  final int statusCode;
  final String message;
  final List<String> errors;

  ApiError(this.statusCode, this.message, {this.errors});

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
  InternalServerApiError([String message = 'Internal server error.'])
      : super(HttpStatus.INTERNAL_SERVER_ERROR, message);
}
