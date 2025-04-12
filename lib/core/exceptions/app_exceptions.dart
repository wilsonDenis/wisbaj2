class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic details;

  AppException(this.message, {this.code, this.details});

  @override
  String toString() {
    return 'AppException{message: $message, code: $code, details: $details}';
  }
}

class BluetoothException extends AppException {
  BluetoothException(String message, {String? code, dynamic details})
      : super(message, code: code, details: details);
}

class AlarmException extends AppException {
  AlarmException(String message, {String? code, dynamic details})
      : super(message, code: code, details: details);
}

class StorageException extends AppException {
  StorageException(String message, {String? code, dynamic details})
      : super(message, code: code, details: details);
}