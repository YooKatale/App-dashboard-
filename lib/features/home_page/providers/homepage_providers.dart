import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../services/api_service.dart';

/// Homepage config (hero slides, side cards, promo banners)
final homepageConfigProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  try {
    final res = await ApiService.fetchHomepageConfig();
    return res['data'] as Map<String, dynamic>? ?? {};
  } catch (_) {
    return {};
  }
});

/// Country cuisines for World Cuisines section
final countryCuisinesProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  try {
    final res = await ApiService.fetchCountryCuisines();
    final data = res['data'];
    if (data is List) {
      return data.map((e) => e is Map ? Map<String, dynamic>.from(e as Map) : <String, dynamic>{}).toList();
    }
    return [];
  } catch (_) {
    return _defaultCountries;
  }
});

const List<Map<String, dynamic>> _defaultCountries = [
  {'code': 'UG', 'name': 'Uganda', 'flag': 'https://flagcdn.com/w160/ug.png', 'specialty': 'Matooke, Rolex & Luwombo', 'isDefault': true},
  {'code': 'NG', 'name': 'Nigeria', 'flag': 'https://flagcdn.com/w160/ng.png', 'specialty': 'Jollof, Suya & Egusi'},
  {'code': 'KE', 'name': 'Kenya', 'flag': 'https://flagcdn.com/w160/ke.png', 'specialty': 'Nyama Choma & Ugali'},
  {'code': 'RW', 'name': 'Rwanda', 'flag': 'https://flagcdn.com/w160/rw.png', 'specialty': 'Isombe & Ibirayi'},
  {'code': 'TZ', 'name': 'Tanzania', 'flag': 'https://flagcdn.com/w160/tz.png', 'specialty': 'Pilau & Zanzibar Mix'},
  {'code': 'ZA', 'name': 'S. Africa', 'flag': 'https://flagcdn.com/w160/za.png', 'specialty': 'Braai & Bobotie'},
  {'code': 'ET', 'name': 'Ethiopia', 'flag': 'https://flagcdn.com/w160/et.png', 'specialty': 'Injera & Doro Wat'},
  {'code': 'GH', 'name': 'Ghana', 'flag': 'https://flagcdn.com/w160/gh.png', 'specialty': 'Fufu & Light Soup'},
];
