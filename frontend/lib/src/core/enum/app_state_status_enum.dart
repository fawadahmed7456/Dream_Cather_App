/// Generic enum for all state classes
enum AppStateStatus {
  /// The initial state of the app.
  initial,

  /// The app is currently loading data.
  loading,

  /// The app has successfully loaded data.
  success,

  /// The app has successfully logged out data.
  logoutSuccess,

  /// The app has encountered an error while loading data.
  failure,

  /// The app is currently deleting data.
  delete,

  /// The app is currently updating data.
  update,

  /// the app is currently empty data
  empty,

  /// unauthenticated
  unauthenticated,

  /// signup success
  signUpSuccess,
}
