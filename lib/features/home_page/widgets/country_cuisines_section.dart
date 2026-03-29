import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

const _kPrimary = Color(0xFF0B2416);
const _kAccent  = Color(0xFF2ECC71);

// ── 21 countries matching the webapp DEFAULT_COUNTRIES exactly ────────────────
// Uses flagcdn.com images (same source as webapp)
const _kFlags = [
  {'code': 'ug', 'name': 'Uganda'},
  {'code': 'ng', 'name': 'Nigeria'},
  {'code': 'ke', 'name': 'Kenya'},
  {'code': 'rw', 'name': 'Rwanda'},
  {'code': 'tz', 'name': 'Tanzania'},
  {'code': 'za', 'name': 'S. Africa'},
  {'code': 'et', 'name': 'Ethiopia'},
  {'code': 'gh', 'name': 'Ghana'},
  {'code': 'cd', 'name': 'Congo'},
  {'code': 'so', 'name': 'Somalia'},
  {'code': 'ss', 'name': 'S. Sudan'},
  {'code': 'ao', 'name': 'Angola'},
  {'code': 'ml', 'name': 'Mali'},
  {'code': 'ma', 'name': 'Morocco'},
  {'code': 'er', 'name': 'Eritrea'},
  {'code': 'br', 'name': 'Brazil'},
  {'code': 'fr', 'name': 'France'},
  {'code': 'it', 'name': 'Italy'},
  {'code': 'cn', 'name': 'China'},
  {'code': 'dk', 'name': 'Denmark'},
  {'code': 'ru', 'name': 'Russia'},
];

class CountryCuisinesSection extends ConsumerStatefulWidget {
  const CountryCuisinesSection({super.key});

  @override
  ConsumerState<CountryCuisinesSection> createState() => _CountryCuisinesSectionState();
}

class _CountryCuisinesSectionState extends ConsumerState<CountryCuisinesSection> {
  final ScrollController _scroll = ScrollController();
  Timer? _timer;
  double _offset = 0;
  bool _paused = false;
  int _selected = 0;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 1), _startScroll);
  }

  void _startScroll() {
    _timer = Timer.periodic(const Duration(milliseconds: 25), (_) {
      if (_paused || !mounted || !_scroll.hasClients) return;
      final max = _scroll.position.maxScrollExtent;
      if (max <= 0) return;
      _offset += 0.8;
      if (_offset >= max) _offset = 0;
      _scroll.jumpTo(_offset);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF112D1C),
        borderRadius: BorderRadius.circular(20),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.public_rounded, color: Colors.white38, size: 12),
                          const SizedBox(width: 5),
                          const Text(
                            'WORLD CUISINES',
                            style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: Colors.white38, letterSpacing: 0.7),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text('Choose Your Menu', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white, fontFamily: 'Raleway')),
                      const SizedBox(height: 2),
                      Text('Tap any country to preview & subscribe', style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.45))),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/subscription'),
                  child: const Text('View All →', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _kAccent)),
                ),
              ],
            ),
          ),

          // Flag chips
          NotificationListener<ScrollNotification>(
            onNotification: (n) {
              if (n is ScrollUpdateNotification && _scroll.hasClients) _offset = _scroll.offset;
              return false;
            },
            child: SizedBox(
              height: 92,
              child: Listener(
                onPointerDown: (_) => _paused = true,
                onPointerUp: (_) => Future.delayed(const Duration(seconds: 2), () => _paused = false),
                child: ListView.builder(
                  controller: _scroll,
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.only(left: 14, right: 14, bottom: 14),
                  physics: const BouncingScrollPhysics(),
                  itemCount: _kFlags.length,
                  itemBuilder: (context, i) {
                    final f = _kFlags[i];
                    final isOn = _selected == i;
                    return GestureDetector(
                      onTap: () {
                        setState(() => _selected = i);
                        Navigator.pushNamed(context, '/subscription');
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 9),
                        child: Column(
                          children: [
                            AnimatedScale(
                              scale: isOn ? 1.06 : 1.0,
                              duration: const Duration(milliseconds: 200),
                              child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isOn ? _kAccent : Colors.white.withOpacity(0.08),
                                  width: isOn ? 2.5 : 1.5,
                                ),
                              ),
                              clipBehavior: Clip.hardEdge,
                              child: CachedNetworkImage(
                                imageUrl: 'https://flagcdn.com/w160/${f['code']}.png',
                                fit: BoxFit.cover,
                                width: 52,
                                height: 52,
                                placeholder: (_, __) => Container(color: const Color(0xFF1A4A2A)),
                                errorWidget: (_, __, ___) => Container(
                                  color: const Color(0xFF1A4A2A),
                                  child: Center(
                                    child: Text(
                                      (f['code'] as String).toUpperCase(),
                                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              f['name'] as String,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: isOn ? FontWeight.w700 : FontWeight.w500,
                                color: isOn ? Colors.white : Colors.white.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

