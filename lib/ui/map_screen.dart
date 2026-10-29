import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../core/lesson_stage_plan.dart';
import '../models/curriculum_models.dart';
import '../models/progress_models.dart';
import '../providers/providers.dart';
import 'artwork_catalog.dart';
import 'lesson/lesson_overview_screen.dart';
import 'lesson/stage_briefing_screen.dart';
import 'lesson/level_map_screen.dart';
import 'map/map_terrain_painter.dart';
import 'theme.dart';
import 'widgets/common.dart';

/// A single stop on the full adventure route. Unlike the old map, each practice
/// level, mastery review, and boss is a tappable stop of its own.
class _AdventureMapStop {
  const _AdventureMapStop({
    required this.section,
    this.lesson,
    this.stage,
    this.chapterLabel,
  });

  final Section section;
  final Lesson? lesson;
  final LessonStage? stage;

  /// Shown only above the first stop in a chapter to keep the map readable.
  final String? chapterLabel;

  bool get isReference => section.type == 'reference';

  bool get isBoss => stage?.isBoss ?? false;
}

final _adventureMapStopsProvider =
    FutureProvider<List<_AdventureMapStop>>((ref) async {
  final repository = ref.watch(curriculumRepositoryProvider);
  final sections = await repository.loadSections();
  final stops = <_AdventureMapStop>[];

  for (final section in sections) {
    if (section.type == 'reference') {
      stops.add(_AdventureMapStop(section: section));
      continue;
    }

    final lesson = await repository.loadLesson(section.id);
    if (lesson == null) {
      // Preserve a route entry if a lesson file cannot be loaded, so the user
      // can still open the existing section screen and see its error state.
      stops.add(_AdventureMapStop(section: section));
      continue;
    }

    final stages = LessonStagePlan.build(section: section, lesson: lesson);
    if (stages.isEmpty) {
      stops.add(_AdventureMapStop(section: section, lesson: lesson));
      continue;
    }

    for (var i = 0; i < stages.length; i++) {
      stops.add(_AdventureMapStop(
        section: section,
        lesson: lesson,
        stage: stages[i],
        chapterLabel: i == 0 ? section.title : null,
      ));
    }
  }

  return stops;
});

/// The adventure map: a single tall world with one trail that climbs from the
/// first chapter at the bottom to later chapters near the top.
class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  static const double _maxMapWidth = 520;

  final TransformationController _mapTransformationController =
      TransformationController();
  bool _initialMapPositionSet = false;

  @override
  void dispose() {
    _mapTransformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stopsAsync = ref.watch(_adventureMapStopsProvider);
    final unlockedAsync = ref.watch(unlockedSectionsProvider);
    final progress = ref.watch(progressProvider);

    return SafeArea(
      child: stopsAsync.when(
        // Static placeholders avoid animating while this screen sits inside
        // the app shell's IndexedStack on another tab.
        loading: () => const _MapLoading(message: 'Drawing the map…'),
        error: (e, _) => AppErrorState(
          message: 'Could not load the map: $e',
          onRetry: () => ref.invalidate(_adventureMapStopsProvider),
        ),
        data: (stops) => unlockedAsync.when(
          loading: () => const _MapLoading(message: 'Checking your progress…'),
          error: (e, _) => AppErrorState(
            message: 'Could not load your progress: $e',
            onRetry: () => ref.invalidate(unlockedSectionsProvider),
          ),
          data: (unlockedSections) => LayoutBuilder(
            builder: (context, constraints) {
              final mapWidth = math.min(constraints.maxWidth, _maxMapWidth);
              final mapHeight = MapLayout.heightFor(stops.length);
              final anchors = MapLayout.anchors(stops.length, mapWidth);
              final stopUnlocked = [
                for (var i = 0; i < stops.length; i++)
                  _isStopUnlocked(
                    i: i,
                    stops: stops,
                    unlockedSections: unlockedSections,
                    progress: progress,
                  ),
              ];
              final openCount = stopUnlocked.where((value) => value).length;

              return Column(
                children: [
                  _MapHeader(
                    stopCount: stops.length,
                    unlockedCount: openCount,
                  ),
                  const SizedBox(height: AppTheme.spaceSm),
                  const _MapLegend(),
                  const SizedBox(height: AppTheme.spaceMd),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, viewportConstraints) {
                        // The starting lessons sit at the bottom of the world,
                        // like a Candy Crush map. Open there on first display;
                        // subsequent rebuilds keep the player's current pan.
                        if (!_initialMapPositionSet) {
                          final viewportHeight = viewportConstraints.maxHeight;
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (!mounted || _initialMapPositionSet) return;
                            final initialY = math.min(
                              0.0,
                              viewportHeight - mapHeight,
                            ).toDouble();
                            _mapTransformationController.value =
                                Matrix4.translationValues(0, initialY, 0);
                            _initialMapPositionSet = true;
                          });
                        }

                        return ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFE6F0E0),
                              border: Border.all(color: AppTheme.outline),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: InteractiveViewer(
                              transformationController:
                                  _mapTransformationController,
                              constrained: false,
                              clipBehavior: Clip.hardEdge,
                              alignment: Alignment.topCenter,
                              minScale: 0.8,
                              maxScale: 2.6,
                              child: SizedBox(
                                width: mapWidth,
                                height: mapHeight,
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Positioned.fill(
                                      child: CustomPaint(
                                        painter: MapTerrainPainter(
                                          anchors: anchors,
                                          nodeCount: stops.length,
                                          biomeStops: _buildBiomeStops(stops, anchors),
                                          drawRoute: false,
                                        ),
                                      ),
                                    ),
                                    ..._buildRegionArtwork(
                                      stops: stops,
                                      anchors: anchors,
                                      mapWidth: mapWidth,
                                      mapHeight: mapHeight,
                                    ),
                                    Positioned.fill(
                                      child: IgnorePointer(
                                        child: CustomPaint(
                                          painter: MapRoutePainter(
                                            anchors: anchors,
                                          ),
                                        ),
                                      ),
                                    ),
                                    for (var i = 0; i < stops.length; i++)
                                      _buildNode(
                                        stop: stops[i],
                                        anchor: anchors[i],
                                        isUnlocked: stopUnlocked[i],
                                        progress: progress,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  /// Places portrait-native, transparent environmental illustrations along the
  /// route. The SVGs are decorative vignettes, not map screenshots: the
  /// terrain and the single connected path are painted by Flutter underneath
  /// and above them. Their artwork fades into transparent space at both ends,
  /// so neighboring chapters overlap organically without rectangular seams.
  List<Widget> _buildRegionArtwork({
    required List<_AdventureMapStop> stops,
    required List<Offset> anchors,
    required double mapWidth,
    required double mapHeight,
  }) {
    final layers = <Widget>[];
    var start = 0;

    while (start < stops.length) {
      var end = start;
      final sectionId = stops[start].section.id;
      while (end + 1 < stops.length &&
          stops[end + 1].section.id == sectionId) {
        end++;
      }

      // Curriculum progression climbs from bottom to top. Work from the outer
      // edge of this chapter to the neighboring stage anchors to locate its
      // natural center; no rectangular chapter background is added here.
      final lowerBoundary = start == 0
          ? mapHeight
          : (anchors[start - 1].dy + anchors[start].dy) / 2;
      final upperBoundary = end == stops.length - 1
          ? 0.0
          : (anchors[end].dy + anchors[end + 1].dy) / 2;
      final segmentTop = math.min(lowerBoundary, upperBoundary).toDouble();
      final segmentBottom = math.max(lowerBoundary, upperBoundary).toDouble();
      final segmentHeight = math.max(1.0, segmentBottom - segmentTop).toDouble();

      final asset = ChapterArtwork.regionAssetForSection(sectionId);
      if (asset != null) {
        // Preserve the original 9:16 SVG proportions. A small overscan lets
        // the vignette feather into nearby terrain, but the artwork is never
        // enlarged arbitrarily to fill a very long chapter (which would crop
        // landmarks and make ponds/bridges feel unnaturally oversized).
        final maxPortraitHeight = mapWidth * 2.0;
        final artHeight =
            math.min(maxPortraitHeight, segmentHeight * 1.08).toDouble();
        final artWidth = artHeight * (720 / 1280);
        final centerY = (segmentTop + segmentBottom) / 2;
        final artTop = centerY - artHeight / 2;
        final artLeft = (mapWidth - artWidth) / 2;

        layers.add(
          Positioned(
            left: artLeft,
            top: artTop,
            width: artWidth,
            height: artHeight,
            child: IgnorePointer(
              child: RepaintBoundary(
                child: ShaderMask(
                  blendMode: BlendMode.dstIn,
                  shaderCallback: (bounds) => const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    // Small edge fades blend each transparent illustration into
                    // the continuous terrain and any neighboring vignette. No
                    // opaque image edge can create a rectangular chapter seam.
                    colors: [
                      Colors.transparent,
                      Color(0x80FFFFFF),
                      Colors.white,
                      Colors.white,
                      Color(0x80FFFFFF),
                      Colors.transparent,
                    ],
                    stops: [0.0, 0.055, 0.12, 0.88, 0.945, 1.0],
                  ).createShader(bounds),
                  child: SvgPicture.asset(
                    asset,
                    fit: BoxFit.contain,
                    alignment: Alignment.center,
                    semanticsLabel:
                        '${ChapterArtwork.regionNameForSection(sectionId)} portrait environment',
                  ),
                ),
              ),
            ),
          ),
        );
      }
      start = end + 1;
    }

    return layers;
  }

  /// One biome color sample per chapter, in visual top-to-bottom order. The
  /// terrain painter interpolates between these samples across the whole world
  /// rather than painting chapter-colored rectangles with visible boundaries.
  List<MapBiomeStop> _buildBiomeStops(
    List<_AdventureMapStop> stops,
    List<Offset> anchors,
  ) {
    final result = <MapBiomeStop>[];
    var start = 0;
    while (start < stops.length) {
      var end = start;
      final sectionId = stops[start].section.id;
      while (end + 1 < stops.length &&
          stops[end + 1].section.id == sectionId) {
        end++;
      }
      result.add(MapBiomeStop(
        y: (anchors[start].dy + anchors[end].dy) / 2,
        color: _regionWashColor(sectionId),
      ));
      start = end + 1;
    }
    result.sort((a, b) => a.y.compareTo(b.y));
    return result;
  }

  Color _regionWashColor(String sectionId) {
    const colors = <String, Color>{
      '01': Color(0xFF6A9EB9), // misty mountain village
      '02': Color(0xFF58AAB6), // creek water
      '03': Color(0xFFE5A5B0), // lantern bridge
      '04': Color(0xFFB7A0C7), // station twilight
      '05': Color(0xFFD9C36D), // golden plains
      '06': Color(0xFF80A96F), // terraced fields
      '07': Color(0xFF6577AE), // rainy alley
      '08': Color(0xFF5DADBB), // koi ponds
      '09': Color(0xFFE6A4B7), // sakura hill
      '10': Color(0xFFD5A75F), // treasure mountain
      '11': Color(0xFF6F9B72), // kodama grove
      '12': Color(0xFFD68A45), // autumn trail
      '13': Color(0xFF697FB8), // moonlit garden
      '14': Color(0xFFD97859), // festival street
      '15': Color(0xFF4E9DB3), // coastal cove
      '16': Color(0xFFD96B42), // volcano
      '17': Color(0xFF9D91C5), // time temple
    };
    final chapter = ChapterArtwork.numberForSection(sectionId);
    return chapter == null ? const Color(0xFFB5C7A4) : colors[chapter]!;
  }

  bool _isStopUnlocked({
    required int i,
    required List<_AdventureMapStop> stops,
    required Set<String> unlockedSections,
    required ProgressData progress,
  }) {
    final stop = stops[i];
    if (stop.isReference) return true;

    final sectionComplete = progress.lessons[stop.section.id]?.completed ?? false;
    if (sectionComplete) return true;

    final stage = stop.stage;
    if (stage == null) return unlockedSections.contains(stop.section.id);

    // The first stage in each chapter opens with that chapter. Later stages
    // open one at a time when the immediately preceding stage is completed.
    if (i == 0 || stops[i - 1].section.id != stop.section.id) {
      return unlockedSections.contains(stop.section.id);
    }

    final previousStage = stops[i - 1].stage;
    if (previousStage == null) return unlockedSections.contains(stop.section.id);
    return progress.completedStageIds.contains(previousStage.id);
  }

  Widget _buildNode({
    required _AdventureMapStop stop,
    required Offset anchor,
    required bool isUnlocked,
    required ProgressData progress,
  }) {
    final sectionProgress = progress.lessons[stop.section.id];
    final isCompleted = !stop.isReference &&
        ((sectionProgress?.completed ?? false) ||
            (stop.stage != null &&
                progress.completedStageIds.contains(stop.stage!.id)));
    final bestScore = sectionProgress != null && sectionProgress.bestQuizTotal > 0
        ? '${sectionProgress.bestQuizScore}/${sectionProgress.bestQuizTotal}'
        : null;

    return Positioned(
      left: anchor.dx - 88,
      top: anchor.dy - MapLayout.nodeRadius,
      width: 176,
      height: MapLayout.verticalStep,
      child: _MapNode(
        stop: stop,
        isUnlocked: isUnlocked,
        isCompleted: isCompleted,
        bestScore: bestScore,
      ),
    );
  }
}

/// Non-animating loading placeholder for the map.
class _MapLoading extends StatelessWidget {
  const _MapLoading({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.map_outlined, size: 40, color: AppTheme.indigoSoft),
            const SizedBox(height: AppTheme.spaceSm),
            Text(message, style: AppTheme.caption(context)),
          ],
        ),
      );
}

/// Small progress summary shown above the map.
class _MapHeader extends StatelessWidget {
  const _MapHeader({required this.stopCount, required this.unlockedCount});

  final int stopCount;
  final int unlockedCount;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppTheme.outline),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFDDF2CE),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.explore_rounded,
                    color: AppTheme.matchaDark, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Your adventure',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text('Follow the trail, one level at a time.',
                        style: AppTheme.caption(context)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.paperAlt,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text('$unlockedCount/$stopCount',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.indigoInk,
                          fontWeight: FontWeight.w900,
                        )),
                    const Text('OPEN',
                        style: TextStyle(
                          fontSize: 8,
                          letterSpacing: 1,
                          color: AppTheme.inkMuted,
                          fontWeight: FontWeight.w900,
                        )),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}

/// Explains the node states without relying on emoji.
class _MapLegend extends StatelessWidget {
  const _MapLegend();

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F5EA),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.outline),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _LegendItem(icon: nodeStateIcon('completed'), color: AppTheme.matchaDark, label: 'Completed'),
              _LegendItem(icon: nodeStateIcon('current'), color: AppTheme.indigoInk, label: 'Open'),
              _LegendItem(icon: nodeStateIcon('locked'), color: AppTheme.locked, label: 'Locked'),
              _LegendItem(icon: nodeStateIcon('reference'), color: AppTheme.sakuraDeep, label: 'Reference'),
            ],
          ),
        ),
      );
}

class _LegendItem extends StatelessWidget {
  const _LegendItem(
      {required this.icon, required this.color, required this.label});

  final IconData icon;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(right: 14),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: AppTheme.spaceXs),
            Text(label, style: AppTheme.caption(context)),
          ],
        ),
      );
}

/// A compact map node opens its actual lesson stage directly.
class _MapNode extends ConsumerWidget {
  const _MapNode({
    required this.stop,
    required this.isUnlocked,
    required this.isCompleted,
    required this.bestScore,
  });

  final _AdventureMapStop stop;
  final bool isUnlocked;
  final bool isCompleted;
  final String? bestScore;

  String get _state => !isUnlocked
      ? 'locked'
      : stop.isReference
          ? 'reference'
          : isCompleted
              ? 'completed'
              : 'current';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = _state;
    final isBoss = stop.isBoss;
    final color = switch (state) {
      'completed' => AppTheme.matchaDark,
      'reference' => AppTheme.sakuraDeep,
      'current' when isBoss => AppTheme.shu,
      'current' => AppTheme.indigoInk,
      _ => AppTheme.locked,
    };
    final markerSize = isBoss ? MapLayout.nodeRadius * 2 + 5 : MapLayout.nodeRadius * 2;
    final markerIcon = state == 'locked'
        ? nodeStateIcon(state)
        : state == 'completed'
            ? nodeStateIcon(state)
            : isBoss
                ? Icons.sports_martial_arts
                : nodeStateIcon(state);
    final displayTitle = stop.stage == null
        ? stop.section.title
        : '${stop.stage!.levelLabel} · ${stop.stage!.title}';

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: isUnlocked ? () => _handleOpen(context, ref) : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.82, end: 1),
            duration: const Duration(milliseconds: 420),
            curve: Curves.easeOutBack,
            builder: (context, scale, child) => Transform.scale(
              scale: scale,
              child: Container(
                width: markerSize + (state == 'current' ? 6 : 0),
                height: markerSize + (state == 'current' ? 6 : 0),
                decoration: BoxDecoration(
                  color: state == 'current' ? color.withValues(alpha: 0.10) : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 240),
                  curve: Curves.easeOut,
                  width: markerSize,
                  height: markerSize,
                  decoration: BoxDecoration(
                    gradient: state == 'completed'
                        ? const LinearGradient(colors: [AppTheme.matcha, AppTheme.matchaDark])
                        : null,
                    color: state == 'locked'
                        ? AppTheme.paperAlt
                        : state == 'reference'
                            ? AppTheme.sakuraDeep
                            : state == 'current' && isBoss
                            ? const Color(0xFFFFF0E8)
                            : state == 'current'
                                ? Colors.white
                                : null,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: color,
                      width: state == 'current' ? 2.5 : 1.8,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: state == 'current' ? 0.22 : 0.12),
                        blurRadius: state == 'current' ? 12 : 4,
                        spreadRadius: state == 'current' ? 1.5 : 0,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(
                    markerIcon,
                    color: state == 'locked'
                        ? AppTheme.locked
                        : state == 'current'
                            ? color
                            : Colors.white,
                    size: isBoss ? 21 : 19,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spaceXs),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 168),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: state == 'locked' ? const Color(0xFFF0F2EC) : Colors.white.withValues(alpha: 0.96),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.outline),
                boxShadow: [
                  BoxShadow(color: AppTheme.shadow, blurRadius: 7, offset: const Offset(0, 3)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (stop.chapterLabel != null)
                    Text(
                      stop.chapterLabel!.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.caption(context).copyWith(
                        color: AppTheme.indigoSoft,
                        fontSize: 9,
                        letterSpacing: 0.45,
                      ),
                    ),
                  Text(
                    displayTitle,
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.5,
                      height: 1.15,
                      fontWeight: FontWeight.w800,
                      color: isUnlocked ? AppTheme.ink : AppTheme.inkMuted,
                    ),
                  ),
                  if (isBoss && isUnlocked && !isCompleted)
                    Text(
                      'BOSS',
                      style: AppTheme.caption(context).copyWith(
                        fontSize: 9,
                        letterSpacing: 0.7,
                        color: AppTheme.shu,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  if (bestScore != null && stop.stage?.isBoss == true)
                    Text(
                      'Best $bestScore',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.caption(context).copyWith(
                          fontSize: 9, color: AppTheme.matchaDark),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleOpen(BuildContext context, WidgetRef ref) {
    final lesson = stop.lesson;
    final stage = stop.stage;
    if (stop.isReference) {
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => LessonOverviewScreen(sectionId: stop.section.id),
      ));
      return;
    }
    if (lesson == null || stage == null) {
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => LevelMapScreen(sectionId: stop.section.id),
      ));
      return;
    }

    ref.read(progressProvider.notifier).registerVocab(
          lesson.vocab.map((vocab) => vocab.id).toList(),
          sectionId: stop.section.id,
        );
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => StageBriefingScreen(
        sectionId: stop.section.id,
        lesson: lesson,
        stage: stage,
      ),
    ));
  }
}
