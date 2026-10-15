import 'package:everafter/data/gallery_memory_content.dart';
import 'package:everafter/models/gallery_media.dart';
import 'package:everafter/theme/everafter_theme.dart';
import 'package:everafter/widgets/museum_widgets.dart';
import 'package:everafter/data/trip_catalog.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class TripTasteMenuScreen extends StatefulWidget {
  const TripTasteMenuScreen({required this.trip, super.key});

  final TripGalleryItem trip;

  @override
  State<TripTasteMenuScreen> createState() => _TripTasteMenuScreenState();
}

class _TripTasteMenuScreenState extends State<TripTasteMenuScreen>
    with SingleTickerProviderStateMixin {
  final ScrollController _ledgerController = ScrollController();
  late final AnimationController _contentController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
    reverseDuration: const Duration(milliseconds: 280),
  );
  int _selectedIndex = 0;
  bool _closing = false;
  bool _allowPop = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 110));
      if (mounted && !_closing) {
        await _contentController.forward();
      }
    });
  }

  @override
  void dispose() {
    _contentController.dispose();
    _ledgerController.dispose();
    super.dispose();
  }

  Future<void> _closeToGallery() async {
    if (_closing) return;
    _closing = true;
    await _contentController.reverse();
    if (!mounted) return;

    if (!context.canPop()) {
      context.go('/trips/${widget.trip.slug}');
      return;
    }

    setState(() => _allowPop = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && context.canPop()) {
        context.pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final memories = galleryTasteMemoriesFor(widget.trip.slug);
    final selected = memories.isEmpty
        ? null
        : memories[_selectedIndex.clamp(0, memories.length - 1).toInt()];
    return PopScope<void>(
      canPop: _allowPop,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _closeToGallery();
      },
      child: PaperScaffold(
        includeDust: true,
        backgroundAsset: 'assets/textures/warm_linen_canvas_visible.jpg',
        child: FadeTransition(
          key: const ValueKey('taste-menu-content-reveal'),
          opacity: CurvedAnimation(
            parent: _contentController,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact =
                  constraints.maxWidth < 700 || constraints.maxHeight < 620;
              final header = _TasteRevealStage(
                key: const ValueKey('taste-reveal-header'),
                animation: _contentController,
                start: 0,
                end: 0.36,
                child: _TasteHeader(trip: widget.trip, onBack: _closeToGallery),
              );
              final memory = selected == null
                  ? const SizedBox.shrink()
                  : _TasteRevealStage(
                      key: const ValueKey('taste-reveal-memory'),
                      animation: _contentController,
                      start: 0.16,
                      end: 0.7,
                      child: _LayeredPaperCard(
                        child: _SelectedTasteMemory(
                          key: ValueKey(
                            'taste-detail-${selected.accessionNumber}',
                          ),
                          memory: selected,
                          totalCount: memories.length,
                          index: _selectedIndex,
                        ),
                      ),
                    );
              final ledger = _TasteRevealStage(
                key: const ValueKey('taste-reveal-ledger'),
                animation: _contentController,
                start: 0.38,
                end: 1,
                child: _LayeredPaperCard(
                  child: _TasteLedger(
                    memories: memories,
                    controller: _ledgerController,
                    selectedIndex: _selectedIndex,
                    onSelected: (index) =>
                        setState(() => _selectedIndex = index),
                  ),
                ),
              );
              final uncurated = _TasteRevealStage(
                key: const ValueKey('taste-reveal-empty-collection'),
                animation: _contentController,
                start: 0.16,
                end: 0.82,
                child: _UncuratedTasteCollection(trip: widget.trip),
              );
              if (compact) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
                  child: Column(
                    children: <Widget>[
                      header,
                      const SizedBox(height: 12),
                      if (memories.isNotEmpty) ...<Widget>[
                        SizedBox(height: 600, child: memory),
                        const SizedBox(height: 20),
                        SizedBox(height: 600, child: ledger),
                      ] else
                        SizedBox(height: 600, child: uncurated),
                    ],
                  ),
                );
              }
              return Padding(
                padding: const EdgeInsets.fromLTRB(36, 22, 36, 28),
                child: Column(
                  children: <Widget>[
                    header,
                    const SizedBox(height: 12),
                    Expanded(
                      child: memories.isNotEmpty
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: <Widget>[
                                Expanded(child: memory),
                                const SizedBox(width: 28),
                                Expanded(child: ledger),
                              ],
                            )
                          : uncurated,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _TasteRevealStage extends StatelessWidget {
  const _TasteRevealStage({
    required this.animation,
    required this.start,
    required this.end,
    required this.child,
    super.key,
  });

  final Animation<double> animation;
  final double start;
  final double end;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) {
        final progress = Interval(
          start,
          end,
          curve: Curves.easeOutCubic,
        ).transform(animation.value);
        return IgnorePointer(
          ignoring: progress < 0.98,
          child: Opacity(
            opacity: progress,
            child: Transform.translate(
              offset: Offset(0, 12 * (1 - progress)),
              child: Transform.scale(
                alignment: Alignment.center,
                scale: 0.992 + (0.008 * progress),
                child: child,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TasteHeader extends StatelessWidget {
  const _TasteHeader({required this.trip, required this.onBack});

  final TripGalleryItem trip;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final compact = MediaQuery.sizeOf(context).width < 700;
    return SizedBox(
      height: 68,
      child: Row(
        children: <Widget>[
          SizedBox(
            width: compact ? 48 : 220,
            child: Align(
              alignment: Alignment.centerLeft,
              child: compact
                  ? IconButton(
                      key: const ValueKey('taste-back-to-gallery'),
                      tooltip: 'Back to gallery',
                      onPressed: onBack,
                      icon: const Icon(Icons.arrow_back),
                    )
                  : TextButton.icon(
                      key: const ValueKey('taste-back-to-gallery'),
                      onPressed: onBack,
                      icon: const Icon(Icons.arrow_back, size: 16),
                      label: const Text('BACK TO GALLERY'),
                    ),
            ),
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                SizedBox(
                  height: 42,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'TASTES OF ${trip.name.toUpperCase()}',
                      maxLines: 1,
                      textAlign: TextAlign.center,
                      style: textTheme.displayMedium?.copyWith(
                        fontFamily: 'Georgia',
                        fontSize: 38,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 3.4,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  height: 12,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'A LEDGER OF CAFÉS, MARKETS, AND MEALS TO REMEMBER',
                      maxLines: 1,
                      textAlign: TextAlign.center,
                      style: textTheme.labelSmall?.copyWith(
                        color: EverAfterColors.warmBrown,
                        fontSize: 8.5,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: compact ? 48 : 220),
        ],
      ),
    );
  }
}

class _UncuratedTasteCollection extends StatelessWidget {
  const _UncuratedTasteCollection({required this.trip});

  final TripGalleryItem trip;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: SizedBox(
        key: ValueKey('taste-empty-${trip.slug}'),
        width: 620,
        height: 480,
        child: _LayeredPaperCard(
          arched: true,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(38, 42, 38, 34),
            child: Column(
              children: <Widget>[
                Text(
                  'EVERAFTER · MENU ${trip.number.toString().padLeft(2, '0')}',
                  style: textTheme.labelSmall?.copyWith(
                    fontSize: 8,
                    letterSpacing: 2.2,
                  ),
                ),
                const SizedBox(height: 18),
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(180),
                      bottom: Radius.circular(5),
                    ),
                    child: Image.asset(
                      trip.assetPath,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      filterQuality: FilterQuality.high,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  '${trip.name.toUpperCase()}\nCOLLECTION',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Georgia',
                    color: EverAfterColors.ink,
                    fontSize: 31,
                    height: 1,
                    letterSpacing: 2.8,
                    decoration: TextDecoration.none,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'MENU COLLECTION IN PROGRESS',
                  key: const ValueKey('taste-menu-in-progress'),
                  style: textTheme.labelLarge?.copyWith(
                    color: EverAfterColors.warmBrown,
                    fontSize: 9,
                    letterSpacing: 2.4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'CAFÉS · MARKETS · MEALS',
                  style: textTheme.labelSmall?.copyWith(
                    fontSize: 8,
                    letterSpacing: 1.8,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectedTasteMemory extends StatelessWidget {
  const _SelectedTasteMemory({
    required this.memory,
    required this.index,
    required this.totalCount,
    super.key,
  });

  final TasteMemory memory;
  final int index;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 320),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: Padding(
        key: ValueKey(memory.accessionNumber),
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                Text(
                  'MEMORY ${(index + 1).toString().padLeft(2, '0')}',
                  style: textTheme.labelSmall?.copyWith(fontSize: 8),
                ),
                const Spacer(),
                Text(
                  memory.accessionNumber,
                  style: textTheme.labelSmall?.copyWith(fontSize: 8),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              flex: 5,
              child: Transform.scale(
                scale: 1.18,
                child: _EmbossedFoodImageFrame(memory: memory),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              memory.place.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: textTheme.headlineMedium?.copyWith(
                fontFamily: 'Georgia',
                fontSize: 26,
                fontWeight: FontWeight.w400,
                letterSpacing: 0.9,
              ),
            ),
            const SizedBox(height: 5),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                Text(
                  memory.dish.toUpperCase(),
                  style: textTheme.labelLarge?.copyWith(fontSize: 9),
                ),
                const SizedBox(width: 9),
                const Icon(Icons.diamond_outlined, size: 8),
                const SizedBox(width: 9),
                Text(
                  memory.city.toUpperCase(),
                  style: textTheme.labelSmall?.copyWith(fontSize: 8),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              memory.note,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'ErraticCursive',
                color: EverAfterColors.ink,
                fontSize: 21,
                height: 1.04,
                letterSpacing: 0.1,
                decoration: TextDecoration.none,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              memory.detail,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: EverAfterColors.ink.withValues(alpha: 0.7),
                fontSize: 12,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              height: 1,
              color: EverAfterColors.ink.withValues(alpha: 0.22),
            ),
            const SizedBox(height: 9),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                Text(
                  'EVERAFTER COLLECTION',
                  style: textTheme.labelSmall?.copyWith(fontSize: 7.5),
                ),
                const SizedBox(width: 12),
                const Icon(Icons.diamond_outlined, size: 8),
                const SizedBox(width: 12),
                Text(
                  '${index + 1} OF $totalCount',
                  style: textTheme.labelSmall?.copyWith(fontSize: 7.5),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmbossedFoodImageFrame extends StatelessWidget {
  const _EmbossedFoodImageFrame({required this.memory});

  final TasteMemory memory;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontalInset = constraints.maxWidth * 0.13;
        final verticalInset = constraints.maxHeight * 0.18;

        return Stack(
          fit: StackFit.expand,
          children: <Widget>[
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalInset,
                vertical: verticalInset,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Image.asset(
                  memory.assetPath,
                  key: ValueKey('taste-image-${memory.accessionNumber}'),
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.high,
                ),
              ),
            ),
            IgnorePointer(
              child: ColorFiltered(
                colorFilter: const ColorFilter.matrix(<double>[
                  0.17008,
                  0.57216,
                  0.05776,
                  0,
                  60,
                  0.17008,
                  0.57216,
                  0.05776,
                  0,
                  52,
                  0.17008,
                  0.57216,
                  0.05776,
                  0,
                  33,
                  0,
                  0,
                  0,
                  1,
                  0,
                ]),
                child: Image.asset(
                  'assets/images/taste/embossed_food_frame.png',
                  key: const ValueKey('taste-embossed-food-frame'),
                  fit: BoxFit.fill,
                  filterQuality: FilterQuality.high,
                  excludeFromSemantics: true,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _LayeredPaperCard extends StatelessWidget {
  const _LayeredPaperCard({required this.child, this.arched = false});

  final Widget child;
  final bool arched;

  BorderRadius get _radius => BorderRadius.vertical(
    top: Radius.circular(arched ? 190 : 7),
    bottom: const Radius.circular(7),
  );

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        Positioned.fill(
          child: Transform.translate(
            offset: const Offset(10, 9),
            child: Transform.rotate(
              angle: 0.006,
              child: DecoratedBox(
                key: const ValueKey('taste-background-card-back'),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3D2AF),
                  border: Border.all(color: const Color(0x5E5C4933)),
                  borderRadius: _radius,
                  boxShadow: const <BoxShadow>[
                    BoxShadow(
                      color: Color(0x2B3A2C1E),
                      blurRadius: 14,
                      offset: Offset(4, 7),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: Transform.translate(
            offset: const Offset(5, 4),
            child: Transform.rotate(
              angle: -0.004,
              child: DecoratedBox(
                key: const ValueKey('taste-background-card-middle'),
                decoration: BoxDecoration(
                  color: const Color(0xFFECE0C5),
                  border: Border.all(color: const Color(0x665C4933)),
                  borderRadius: _radius,
                ),
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: ClipRRect(
            borderRadius: _radius,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFFF4ECD9),
                border: Border.all(
                  color: EverAfterColors.ink.withValues(alpha: 0.46),
                  width: 1.1,
                ),
                borderRadius: _radius,
                boxShadow: const <BoxShadow>[
                  BoxShadow(
                    color: Color(0x1F3A2C1E),
                    blurRadius: 7,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  Opacity(
                    opacity: 0.18,
                    child: Image.asset(
                      'assets/textures/warm_linen_canvas_fine.jpg',
                      fit: BoxFit.cover,
                      color: const Color(0xFFE3D2AF),
                      colorBlendMode: BlendMode.multiply,
                      excludeFromSemantics: true,
                    ),
                  ),
                  child,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Retained as an unused archive of the later lace-menu experiment.
// ignore: unused_element

class _TasteLedger extends StatelessWidget {
  const _TasteLedger({
    required this.controller,
    required this.memories,
    required this.selectedIndex,
    required this.onSelected,
  });

  final ScrollController controller;
  final List<TasteMemory> memories;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              const Expanded(
                child: Text(
                  'THE LEDGER',
                  style: TextStyle(
                    fontFamily: 'Georgia',
                    color: EverAfterColors.ink,
                    fontSize: 23,
                    height: 1,
                    letterSpacing: 1.2,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${memories.length} MEMORIES',
                style: textTheme.labelSmall?.copyWith(fontSize: 7.5),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            height: 1,
            color: EverAfterColors.ink.withValues(alpha: 0.36),
          ),
          const SizedBox(height: 5),
          Expanded(
            child: Scrollbar(
              controller: controller,
              thumbVisibility: true,
              interactive: true,
              child: ListView.separated(
                key: const ValueKey('taste-ledger-list'),
                controller: controller,
                padding: const EdgeInsets.only(right: 11),
                itemCount: memories.length,
                separatorBuilder: (context, index) => Divider(
                  height: 1,
                  thickness: 1,
                  color: EverAfterColors.ink.withValues(alpha: 0.19),
                ),
                itemBuilder: (context, index) => _TasteLedgerRow(
                  memory: memories[index],
                  index: index,
                  selected: index == selectedIndex,
                  onTap: () => onSelected(index),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          const _SelectMemoryCard(),
        ],
      ),
    );
  }
}

class _SelectMemoryCard extends StatelessWidget {
  const _SelectMemoryCard();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        key: const ValueKey('taste-select-a-memory-card'),
        width: 300,
        height: 46,
        decoration: BoxDecoration(
          color: const Color(0xFFF8F1E2),
          border: Border.all(
            color: EverAfterColors.ink.withValues(alpha: 0.55),
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Color(0x263A2C1E),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(Icons.diamond_outlined, size: 10),
            SizedBox(width: 16),
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'SELECT A MEMORY',
                  style: TextStyle(
                    fontFamily: 'Georgia',
                    color: EverAfterColors.ink,
                    fontSize: 18,
                    letterSpacing: 2.2,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
            ),
            SizedBox(width: 16),
            Icon(Icons.diamond_outlined, size: 10),
          ],
        ),
      ),
    );
  }
}

class _TasteLedgerRow extends StatelessWidget {
  const _TasteLedgerRow({
    required this.memory,
    required this.index,
    required this.selected,
    required this.onTap,
  });

  final TasteMemory memory;
  final int index;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Semantics(
      selected: selected,
      button: true,
      label: 'Open ${memory.place}, ${memory.dish}',
      child: Material(
        color: selected
            ? EverAfterColors.agedPaper.withValues(alpha: 0.62)
            : Colors.transparent,
        shape: selected
            ? RoundedRectangleBorder(
                side: BorderSide(
                  color: EverAfterColors.ink.withValues(alpha: 0.36),
                ),
                borderRadius: BorderRadius.circular(5),
              )
            : null,
        child: InkWell(
          key: ValueKey('taste-ledger-item-$index'),
          onTap: onTap,
          borderRadius: BorderRadius.circular(5),
          child: SizedBox(
            height: 82,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
              child: Row(
                children: <Widget>[
                  SizedBox(
                    width: 28,
                    child: Text(
                      (index + 1).toString().padLeft(2, '0'),
                      style: textTheme.titleLarge?.copyWith(
                        fontSize: 18,
                        color: selected
                            ? EverAfterColors.ink
                            : EverAfterColors.warmBrown,
                      ),
                    ),
                  ),
                  const SizedBox(width: 7),
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(32),
                      bottom: Radius.circular(3),
                    ),
                    child: SizedBox(
                      width: 92,
                      height: 64,
                      child: Image.asset(
                        memory.assetPath,
                        fit: BoxFit.cover,
                        filterQuality: FilterQuality.medium,
                      ),
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          memory.place.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.titleLarge?.copyWith(
                            fontFamily: 'Georgia',
                            fontSize: 17,
                            fontWeight: FontWeight.w400,
                            letterSpacing: 0.45,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${memory.dish.toUpperCase()}  ·  ${memory.city.toUpperCase()}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.labelSmall?.copyWith(fontSize: 7),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          memory.note.replaceAll('\n', ' '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'ErraticCursive',
                            color: EverAfterColors.ink,
                            fontSize: 13,
                            height: 1,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  SizedBox(
                    width: 34,
                    child: Text(
                      memory.accessionNumber.replaceFirst('EA-JP-', 'NO.\n'),
                      textAlign: TextAlign.center,
                      style: textTheme.labelSmall?.copyWith(
                        fontSize: 6.5,
                        height: 1.25,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
