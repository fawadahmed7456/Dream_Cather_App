enum RequestStatus {
  initial,
  loading,
  success,
  failure,
}

enum UserRole {
  passenger('Passenger'),
  driver('Driver');

  final String label;
  const UserRole(this.label);
}

enum RideStatus {
  available('Available'),
  booked('Booked'),
  inProgress('In Progress'),
  completed('Completed'),
  cancelled('Cancelled');

  final String label;
  const RideStatus(this.label);
}
