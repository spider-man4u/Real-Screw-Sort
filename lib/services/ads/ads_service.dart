import 'package:flutter/material.dart';

/// Where a rewarded ad was requested from.
enum RewardPlacement { hint, undo, continue_, doubleCoins, extraHint }

/// Abstract ads interface. The real AdMob implementation can be dropped in
/// behind this later (see README) - the mock keeps the app fully playable.
abstract class AdsService {
  bool get isLoaded;

  /// Rewarded ad. Returns true when the player was rewarded.
  Future<bool> showRewarded(RewardPlacement placement);

  /// Interstitial between levels. Never shown after a failure.
  Future<void> showInterstitial();

  void dispose();
}

/// In-app demo rewarded ad: a branded overlay with a short "watch" delay.
class MockAdsService implements AdsService {
  MockAdsService({
    this.rewardDelay = const Duration(seconds: 3),
    this.navigatorKey,
  });

  final Duration rewardDelay;
  final GlobalKey<NavigatorState>? navigatorKey;

  bool _showing = false;

  @override
  bool get isLoaded => !_showing;

  @override
  Future<bool> showRewarded(RewardPlacement placement) async {
    if (_showing) return false;
    _showing = true;
    final navigator = navigatorKey?.currentState;
    if (navigator == null) {
      _showing = false;
      return true;
    }
    final rewarded = await navigator.push<bool>(
      _AdOverlay(delay: rewardDelay),
    );
    _showing = false;
    return rewarded ?? false;
  }

  @override
  Future<void> showInterstitial() async {
    if (_showing) return;
    _showing = true;
    final navigator = navigatorKey?.currentState;
    if (navigator == null) {
      _showing = false;
      return;
    }
    await navigator.push(_InterstitialOverlay(delay: const Duration(seconds: 2)));
    _showing = false;
  }

  @override
  void dispose() {}
}

class _AdOverlay extends StatefulWidget {
  const _AdOverlay({required this.delay});

  final Duration delay;

  @override
  State<_AdOverlay> createState() => _AdOverlayState();
}

class _AdOverlayState extends State<_AdOverlay> {
  double _progress = 0;

  @override
  void initState() {
    super.initState();
    final totalMs = widget.delay.inMilliseconds;
    const step = 100;
    Future.doWhile(() async {
      await Future<void>.delayed(const Duration(milliseconds: step));
      if (!mounted) return false;
      setState(() => _progress += step / totalMs);
      return _progress < 1;
    });
  }

  void _close(bool rewarded) {
    Navigator.of(context).pop(rewarded);
  }

  @override
  Widget build(BuildContext context) {
    final done = _progress >= 1;
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFF11142B),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 110,
                height: 110,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFFFFC93C), Color(0xFFFF8A3D)],
                  ),
                ),
                child: const Icon(Icons.play_arrow_rounded, size: 56, color: Colors.white),
              ),
              const SizedBox(height: 24),
              const Text(
                'REWARDED VIDEO (DEMO)',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                done ? 'Watch complete - reward ready!' : 'Demo ad playing...',
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 24),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 220,
                  height: 8,
                  child: LinearProgressIndicator(
                    value: _progress.clamp(0.0, 1.0),
                    backgroundColor: Colors.white24,
                    color: const Color(0xFFFFC93C),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: done ? () => _close(true) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: done ? const Color(0xFFFFC93C) : Colors.white24,
                  foregroundColor: const Color(0xFF11142B),
                  disabledBackgroundColor: Colors.white24,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                ),
                child: Text(done ? 'CLAIM REWARD' : 'WATCHING...'),
              ),
              const SizedBox(height: 8),
              if (!done)
                TextButton(
                  onPressed: () => _close(false),
                  child: const Text('Skip (no reward)',
                      style: TextStyle(color: Colors.white54)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InterstitialOverlay extends StatefulWidget {
  const _InterstitialOverlay({required this.delay});

  final Duration delay;

  @override
  State<_InterstitialOverlay> createState() => _InterstitialOverlayState();
}

class _InterstitialOverlayState extends State<_InterstitialOverlay> {
  @override
  void initState() {
    super.initState();
    Future.delayed(widget.delay, () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF11142B),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.ad_units_rounded, color: Colors.white54, size: 72),
            const SizedBox(height: 16),
            const Text(
              'INTERSTITIAL (DEMO)',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
