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
