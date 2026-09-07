import 'package:flutter_test/flutter_test.dart';

import 'package:gav_mobile/core/constants/roles.dart';

void main() {
  group('UserRoleHelper', () {
    test('normalizes roles from strings and defaults to patient', () {
      expect(UserRoleHelper.normalize('ADMIN'), UserRole.admin);
      expect(UserRoleHelper.normalize('receptionniste'), UserRole.receptionist);
      expect(UserRoleHelper.normalize('Opticien'), UserRole.optician);
      expect(UserRoleHelper.normalize(''), UserRole.patient);
      expect(UserRoleHelper.normalize(null), UserRole.patient);
    });

    test(
      'blocks unauthorized dashboard access while allowing admin access',
      () {
        expect(
          UserRoleHelper.canAccess(UserRole.patient, UserRole.patient),
          isTrue,
        );
        expect(
          UserRoleHelper.canAccess(UserRole.patient, UserRole.admin),
          isFalse,
        );
        expect(
          UserRoleHelper.canAccess(UserRole.admin, UserRole.patient),
          isTrue,
        );
        expect(
          UserRoleHelper.canAccess(
            UserRole.receptionist,
            UserRole.receptionist,
          ),
          isTrue,
        );
        expect(
          UserRoleHelper.canAccess(UserRole.receptionist, UserRole.optician),
          isFalse,
        );
      },
    );
  });
}
