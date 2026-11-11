sealed class Failure {
  const Failure(this.message);

  final String message;
}

class FileFailure extends Failure {
  const FileFailure(super.message);
}

class ParsingFailure extends Failure {
  const ParsingFailure(super.message);
}

class StorageFailure extends Failure {
  const StorageFailure(super.message);
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

class ApiFailure extends Failure {
  const ApiFailure(
      super.message, {
        this.statusCode,
        this.retryAfterSeconds,
      });

  final int? statusCode;
  final int? retryAfterSeconds;
}
