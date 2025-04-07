/// Represents the result of an APK installation attempt
///
/// Contains information about whether the installation was successful
/// and any error message if it failed
class ManageInstallResult {
  final bool isSuccess;
  final String? message;

  ManageInstallResult({required this.isSuccess, this.message});

  ManageInstallResult.fromJson(Map<String, dynamic> data)
      : this(
    isSuccess: data['isSuccess'] ?? false,
    message: data['message'] ?? 'Unknown status',
  );

  Map<String, dynamic> toMap() {
    return {'isSuccess': isSuccess, 'message': message};
  }

  @override
  String toString() => 'ManageInstallResult(isSuccess: $isSuccess, message: $message)';
}
