/// Matrix Client-Server paths reserved for a future live client.
/// The fake repositories do not call these endpoints.
class ApiEndpoints {
  const ApiEndpoints._();

  static const login = '/_matrix/client/v3/login';
  static const register = '/_matrix/client/v3/register';
  static const sync = '/_matrix/client/v3/sync';
  static const join = '/_matrix/client/v3/join';
  static const createRoom = '/_matrix/client/v3/createRoom';
  static const wellKnown = '/.well-known/matrix/client';
}
