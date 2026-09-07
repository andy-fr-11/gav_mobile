import 'package:flutter_test/flutter_test.dart';

import 'package:gav_mobile/services/supabase_storage_service.dart';

void main() {
  group('SupabaseStorageService', () {
    test('builds a public URL from a bucket and path', () {
      final url = SupabaseStorageService.buildPublicUrl(
        'avatars',
        'user-123/photo.png',
      );

      expect(
        url,
        contains('/storage/v1/object/public/avatars/user-123/photo.png'),
      );
    });

    test('returns null when the bucket or path is missing', () {
      expect(SupabaseStorageService.buildPublicUrl('', 'user-123/photo.png'), isNull);
      expect(SupabaseStorageService.buildPublicUrl('avatars', ''), isNull);
    });
    test('returns fallback when the image path is absent', () {
      const fallback = 'https://cdn.example.com/default-avatar.png';

      expect(
        SupabaseStorageService.buildPublicUrlOrFallback('', 'user-123/photo.png', fallback: fallback),
        fallback,
      );
      expect(
        SupabaseStorageService.buildPublicUrlOrFallback('avatars', '', fallback: fallback),
        fallback,
      );
    });  });
}
