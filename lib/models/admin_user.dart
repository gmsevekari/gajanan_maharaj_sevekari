class AdminUser {
  final String email;
  final List<String> roles;
  final bool typoNotificationsEnabled;
  final String? groupId;

  const AdminUser({
    required this.email,
    required this.roles,
    this.typoNotificationsEnabled = false,
    this.groupId,
  });

  factory AdminUser.fromFirestore(Map<String, dynamic> data, String email) {
    final rolesData = data['roles'];
    final List<String> rolesList;
    if (rolesData is List) {
      rolesList = rolesData.map((e) => e.toString()).toList();
    } else {
      rolesList = [];
    }
    return AdminUser(
      email: email,
      roles: rolesList,
      typoNotificationsEnabled: data['typoNotificationsEnabled'] ?? false,
      groupId: data['groupId'],
    );
  }

  bool hasRole(String role) {
    return roles.contains('super_admin') || roles.contains(role);
  }

  bool hasAnyRole(List<String> requiredRoles) {
    if (roles.contains('super_admin')) return true;
    return requiredRoles.any((role) => roles.contains(role));
  }
}
