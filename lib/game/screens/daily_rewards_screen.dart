import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../data/progress/progress_store.dart';
import '../../widgets/dialogs.dart';
import '../../widgets/game_button.dart';
import '../audio/audio_manager.dart';

/// Daily reward calendar (PDR section 17): 7-day streak, one claim per day.
class DailyRewardsScreen extends StatefulWidget {
  const DailyRewardsScreen({super.key});

  @override
  State<DailyRewardsScreen> createState() => _DailyRewardsScreenState();
}

class _DailyRewardsScreenState extends State<DailyRewardsScreen> {
  @override
  Widget build(BuildContext context) {
    final progress = context.watch<ProgressStore>();
    final canClaim = progress.canClaimDaily;
    final streak = progress.dailyStreak;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: Palette.screenBackdrop),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    _backButton(context),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Daily Rewards',
                        style: TextStyle(
                          fontFamily: 'Baloo2',
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Palette.ink,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Palette.yellow.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.local_fire_department_rounded,
                              color: Palette.orange, size: 18),
                          const SizedBox(width: 4),
                          Text(
                            'Day $streak',
                            style: const TextStyle(
                              fontFamily: 'Baloo2',
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: Palette.ink,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: GridView.count(
                  padding: const EdgeInsets.all(20),
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 1.35,
                  children: [
                    for (var i = 0; i < dailyRewards.length; i++)
                      _rewardCard(context, progress, i, canClaim),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: GameButton(
                  label: canClaim ? 'Claim reward' : 'Come back tomorrow',
                  icon: canClaim ? Icons.card_giftcard_rounded : Icons.schedule_rounded,
                  height: 54,
                  fontSize: 18,
                  onPressed: canClaim ? () => _claim(progress) : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _claim(ProgressStore progress) {
    progress.claimDaily();
    context.read<AudioManager>().coin();
    showToast(context, 'Reward claimed!');
    setState(() {});
  }

  Widget _rewardCard(
    BuildContext context,
    ProgressStore progress,
    int index,
    bool canClaim,
  ) {
    final reward = dailyRewards[index];
    final streak = progress.dailyStreak;
    final todayIdx = (streak - 1) % dailyRewards.length;
    final today = index == todayIdx;
    final next = index == (todayIdx + 1) % dailyRewards.length;
    final past = index < todayIdx;

    final Color bg;
    final Color fg;
    if (today && canClaim) {
      bg = Palette.yellow;
      fg = Palette.ink;
    } else if (today) {
      bg = Palette.green;
      fg = Colors.white;
    } else if (past) {
      bg = const Color(0xFFDDE3F2);
      fg = Palette.inkSoft;
    } else {
      bg = Colors.white;
      fg = Palette.inkSoft;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: next ? Border.all(color: Palette.blue, width: 3) : null,
        boxShadow: const [
          BoxShadow(color: Color(0x14000000), blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(reward.icon, style: const TextStyle(fontSize: 30)),
          const SizedBox(height: 6),
          Text(
            'Day ${reward.day}',
            style: TextStyle(
              fontFamily: 'Baloo2',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
          Text(
            '${reward.label} ×${reward.amount}',
            style: TextStyle(
              fontFamily: 'Baloo2',
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: fg,
            ),
          ),
          if (next)
            const Text(
              'NEXT',
              style: TextStyle(
                fontFamily: 'Baloo2',
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: Palette.blue,
              ),
            ),
        ],
      ),
    );
  }

  Widget _backButton(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 2,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () {
          context.read<AudioManager>().click();
          Navigator.pop(context);
        },
        child: const Padding(
          padding: EdgeInsets.all(10),
          child: Icon(Icons.arrow_back_rounded, color: Palette.ink),
        ),
      ),
    );
  }
}
