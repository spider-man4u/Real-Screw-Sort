import 'dart:ui';

/// Visual theme per background key (PDR section 19).
class BoardTheme {
  const BoardTheme({
    required this.key,
    required this.name,
    required this.pegTop,
    required this.pegBottom,
    required this.hole,
    required this.frame,
    required this.plateA,
    required this.plateB,
    required this.plateEdge,
    required this.background,
    required this.accent,
  });

  final String key;
  final String name;
  final Color pegTop;
  final Color pegBottom;
  final Color hole;
  final Color frame;
  final Color plateA;
  final Color plateB;
  final Color plateEdge;
  final Color background;
  final Color accent;

  List<Color> get pegGradient => [pegTop, pegBottom];

  List<Color> get plateGradient => [plateA, plateB];
}

const List<BoardTheme> boardThemes = [
  BoardTheme(
    key: 'workshop',
    name: 'Workshop',
    pegTop: Color(0xFF5B6E99),
    pegBottom: Color(0xFF3D4C74),
    hole: Color(0xFF232B4A),
    frame: Color(0xFF2A3354),
    plateA: Color(0xFFD9A05F),
    plateB: Color(0xFFB97F42),
    plateEdge: Color(0xFF8E5F30),
    background: Color(0xFFEAF0FF),
    accent: Color(0xFFFFC93C),
  ),
  BoardTheme(
    key: 'construction',
    name: 'Construction Site',
    pegTop: Color(0xFF6B7280),
    pegBottom: Color(0xFF4B5563),
    hole: Color(0xFF1F2937),
    frame: Color(0xFF374151),
    plateA: Color(0xFFF59E0B),
    plateB: Color(0xFFD97706),
    plateEdge: Color(0xFF92400E),
    background: Color(0xFFFFF7E6),
    accent: Color(0xFFF59E0B),
  ),
  BoardTheme(
    key: 'space',
    name: 'Space Station',
    pegTop: Color(0xFF374151),
    pegBottom: Color(0xFF111827),
    hole: Color(0xFF000000),
    frame: Color(0xFF0B1220),
    plateA: Color(0xFF9CA3AF),
    plateB: Color(0xFF6B7280),
    plateEdge: Color(0xFF374151),
    background: Color(0xFF0F172A),
    accent: Color(0xFF60A5FA),
  ),
  BoardTheme(
    key: 'temple',
    name: 'Ancient Temple',
    pegTop: Color(0xFF8D6E63),
    pegBottom: Color(0xFF5D4037),
    hole: Color(0xFF3E2723),
    frame: Color(0xFF4E342E),
    plateA: Color(0xFFEFD9B0),
    plateB: Color(0xFFD8BE92),
    plateEdge: Color(0xFFA98E5E),
    background: Color(0xFFFFF3E0),
    accent: Color(0xFFFFB74D),
  ),
  BoardTheme(
    key: 'ice',
    name: 'Ice World',
    pegTop: Color(0xFF90CAF9),
    pegBottom: Color(0xFF4FC3F7),
    hole: Color(0xFF0288D1),
    frame: Color(0xFF0277BD),
    plateA: Color(0xFFE1F5FE),
    plateB: Color(0xFFB3E5FC),
    plateEdge: Color(0xFF81D4FA),
    background: Color(0xFFE1F5FE),
    accent: Color(0xFF4FC3F7),
  ),
  BoardTheme(
    key: 'steampunk',
    name: 'Steampunk Factory',
    pegTop: Color(0xFF7A6A5A),
    pegBottom: Color(0xFF4E4038),
    hole: Color(0xFF2A2118),
    frame: Color(0xFF3B2F24),
    plateA: Color(0xFFC08552),
    plateB: Color(0xFF9E6A3C),
    plateEdge: Color(0xFF6B4522),
    background: Color(0xFFF5E6D3),
    accent: Color(0xFFE0A458),
  ),
  BoardTheme(
    key: 'cyber',
    name: 'Cyber City',
    pegTop: Color(0xFF312E81),
    pegBottom: Color(0xFF1E1B4B),
    hole: Color(0xFF0B0A2E),
    frame: Color(0xFF151240),
    plateA: Color(0xFF8B5CF6),
    plateB: Color(0xFF6D28D9),
    plateEdge: Color(0xFF4C1D95),
    background: Color(0xFFEDE9FE),
    accent: Color(0xFF22D3EE),
  ),
  BoardTheme(
    key: 'volcano',
    name: 'Volcano',
    pegTop: Color(0xFF9E4A3F),
    pegBottom: Color(0xFF6B2A26),
    hole: Color(0xFF3E1412),
    frame: Color(0xFF4A1C18),
    plateA: Color(0xFFFF8A65),
    plateB: Color(0xFFD95B3D),
    plateEdge: Color(0xFFA63D24),
    background: Color(0xFFFFEBE4),
    accent: Color(0xFFFF6E40),
  ),
];

BoardTheme themeForKey(String key) =>
    boardThemes.firstWhere((t) => t.key == key, orElse: () => boardThemes.first);

/// Screw skin palettes.
class ScrewSkin {
  const ScrewSkin({
    required this.key,
    required this.name,
    required this.headA,
    required this.headB,
    required this.edge,
    required this.slot,
  });

  final String key;
  final String name;
  final Color headA;
  final Color headB;
  final Color edge;
  final Color slot;
}

const List<ScrewSkin> screwSkins = [
  ScrewSkin(
    key: 'classic', name: 'Classic',
    headA: Color(0xFFDDE3EE), headB: Color(0xFFAAB4C8),
    edge: Color(0xFF6E7891), slot: Color(0xFF4A5468),
  ),
  ScrewSkin(
    key: 'gold', name: 'Gold',
    headA: Color(0xFFFFE082), headB: Color(0xFFF5B301),
    edge: Color(0xFFC07F00), slot: Color(0xFF8A5A00),
  ),
  ScrewSkin(
    key: 'blue', name: 'Blue',
    headA: Color(0xFFB3D4FF), headB: Color(0xFF3B6BFF),
    edge: Color(0xFF1F3FA8), slot: Color(0xFF12245F),
  ),
  ScrewSkin(
    key: 'pink', name: 'Pink',
    headA: Color(0xFFFFC1E3), headB: Color(0xFFF062A6),
    edge: Color(0xFFB73A72), slot: Color(0xFF7E2250),
  ),
  ScrewSkin(
    key: 'robot', name: 'Robot',
    headA: Color(0xFFB2F0CE), headB: Color(0xFF2ECB8C),
    edge: Color(0xFF14764F), slot: Color(0xFF0A4A31),
  ),
];

ScrewSkin skinForKey(String key) =>
    screwSkins.firstWhere((s) => s.key == key, orElse: () => screwSkins.first);

/// Color palette for color screws / slots.
const List<Color> screwColors = [
  Color(0xFFFF5D6C),
  Color(0xFF2ECB8C),
  Color(0xFFFFC93C),
  Color(0xFF8E5BFF),
  Color(0xFF3B6BFF),
  Color(0xFFFF8A3D),
];
