enum UserRole { admin, doctor, optician, receptionist, patient }

class UserRoleHelper {
  static UserRole normalize(String? role) {
    final normalized = (role ?? '').trim().toLowerCase();

    if (const {'admin', 'administrateur', 'administrator'}.contains(normalized)) {
      return UserRole.admin;
    }
    if (const {'doctor', 'medecin', 'médecin'}.contains(normalized)) {
      return UserRole.doctor;
    }
    if (const {'optician', 'opticien'}.contains(normalized)) {
      return UserRole.optician;
    }
    if (const {
      'reception',
      'receptionniste',
      'receptioniste',
      'receptionist',
    }.contains(normalized)) {
      return UserRole.receptionist;
    }
    return UserRole.patient;
  }

  static bool canAccess(UserRole currentRole, UserRole requiredRole) {
    if (currentRole == requiredRole) return true;
    if (currentRole == UserRole.admin) return true;
    return false;
  }

  static String label(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'admin';
      case UserRole.doctor:
        return 'doctor';
      case UserRole.optician:
        return 'opticien';
      case UserRole.receptionist:
        return 'receptionniste';
      case UserRole.patient:
        return 'patient';
    }
  }
}
