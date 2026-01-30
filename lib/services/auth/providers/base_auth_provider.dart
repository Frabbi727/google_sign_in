/// Callback types for auth events
typedef AuthSuccessCallback = void Function(dynamic credential);
typedef AuthErrorCallback = void Function(String error);

/// Base interface for all authentication providers
///
/// Each authentication method (Magic Link, Email/Password, Google, Facebook)
/// implements this interface to provide a consistent API
abstract class BaseAuthProvider {
  /// The unique name/identifier for this provider
  String get providerName;

  /// Initialize the provider (setup listeners, check state, etc.)
  Future<void> initialize();

  /// Check if this provider is currently available/configured
  bool get isAvailable;

  /// Callback for successful authentication
  AuthSuccessCallback? onSuccess;

  /// Callback for authentication errors
  AuthErrorCallback? onError;

  /// Clean up resources when provider is no longer needed
  void dispose();
}
