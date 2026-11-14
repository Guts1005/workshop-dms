import 'package:flutter/material.dart';
import '../../core/theme/tokens.dart';

enum ConditionView {
  side,
  front,
  rear,
  top,
}

enum DefectType {
  dent('DENT'),
  deepScratch('DEEP SCRATCH'),
  surfaceScuff('SURFACE SCUFF'),
  paintChip('PAINT CHIP'),
  glassCrack('GLASS CRACK'),
  rust('RUST');

  final String label;
  const DefectType(this.label);
}

enum DefectSeverity {
  minor('LEVEL 1 - MINOR'),
  moderate('LEVEL 2 - MODERATE'),
  severe('LEVEL 3 - SEVERE');

  final String label;
  const DefectSeverity(this.label);
}

class DamagePin {
  final int id;
  final ConditionView view;
  final Offset relativePosition; // Normalized 0.0 - 1.0 coordinates
  final DefectType type;
  final DefectSeverity severity;
  final String? note;

  const DamagePin({
    required this.id,
    required this.view,
    required this.relativePosition,
    required this.type,
    required this.severity,
    this.note,
  });
}

class ConditionMapWidget extends StatefulWidget {
  final List<DamagePin> pins;
  final Function(DamagePin pin)? onPinAdded;
  final Function(DamagePin pin)? onPinSelected;

  const ConditionMapWidget({
    super.key,
    required this.pins,
    this.onPinAdded,
    this.onPinSelected,
  });

  @override
  State<ConditionMapWidget> createState() => _ConditionMapWidgetState();
}

class _ConditionMapWidgetState extends State<ConditionMapWidget> {
  ConditionView _activeView = ConditionView.side;

  @override
  Widget build(BuildContext context) {
    final activePins = widget.pins.where((p) => p.view == _activeView).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // View Selector Bar (Side, Front, Rear, Top)
        Row(
          children: [
            _buildViewTab(ConditionView.side, 'SIDE PROFILE'),
            _buildViewTab(ConditionView.front, 'FRONT NOSE'),
            _buildViewTab(ConditionView.rear, 'REAR TAIL'),
            _buildViewTab(ConditionView.top, 'ROOF / TOP'),
          ],
        ),
        const SizedBox(height: 12.0),

        // Interactive Canvas Container
        Container(
          height: 380.0,
          decoration: BoxDecoration(
            color: AppTokens.raised,
            borderRadius: BorderRadius.zero,
            border: Border.all(color: AppTokens.borderSolid, width: 1.0),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapUp: (details) {
                  final renderBox = context.findRenderObject() as RenderBox?;
                  if (renderBox == null) return;
                  final localOffset = details.localPosition;
                  final normalizedOffset = Offset(
                    (localOffset.dx / constraints.maxWidth).clamp(0.0, 1.0),
                    (localOffset.dy / constraints.maxHeight).clamp(0.0, 1.0),
                  );
                  _showAddPinDialog(context, normalizedOffset);
                },
                child: Stack(
                  children: [
                    // Base Line-art diagram
                    Positioned.fill(
                      child: CustomPaint(
                        painter: ConditionSchematicPainter(view: _activeView),
                      ),
                    ),

                    // Damage Pin Overlays (#DB4A2B filled dot with sequential number, 24px min)
                    ...activePins.map((pin) {
                      final dx = pin.relativePosition.dx * constraints.maxWidth;
                      final dy = pin.relativePosition.dy * constraints.maxHeight;

                      return Positioned(
                        left: dx - 14.0,
                        top: dy - 14.0,
                        child: GestureDetector(
                          onTap: () => widget.onPinSelected?.call(pin),
                          child: Container(
                            width: 28.0,
                            height: 28.0,
                            decoration: BoxDecoration(
                              color: AppTokens.redOrange,
                              borderRadius: BorderRadius.zero,
                              border: Border.all(color: AppTokens.inverse, width: 1.5),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${pin.id}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13.0,
                                fontWeight: FontWeight.w900,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                        ),
                      );
                    }),

                    // Instruction indicator in corner
                    Positioned(
                      bottom: 8.0,
                      left: 8.0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                        color: AppTokens.surface,
                        child: Text(
                          'TAP SCHEMATIC TO DROP DAMAGE PIN [${_activeView.name.toUpperCase()}]',
                          style: const TextStyle(
                            color: AppTokens.textSecondary,
                            fontSize: 10.0,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildViewTab(ConditionView view, String label) {
    final isActive = _activeView == view;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeView = view),
        child: Container(
          height: 48.0,
          decoration: BoxDecoration(
            color: isActive ? AppTokens.inverse : AppTokens.surface,
            borderRadius: BorderRadius.zero,
            border: Border.all(color: AppTokens.borderSolid, width: 1.0),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isActive ? AppTokens.textOnDark : AppTokens.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 12.0,
              letterSpacing: 0.8,
            ),
          ),
        ),
      ),
    );
  }

  void _showAddPinDialog(BuildContext context, Offset relativePosition) {
    DefectType selectedType = DefectType.dent;
    DefectSeverity selectedSeverity = DefectSeverity.minor;
    final noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return AlertDialog(
              backgroundColor: AppTokens.raised,
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
              title: Container(
                padding: const EdgeInsets.all(12.0),
                color: AppTokens.inverse,
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: AppTokens.redOrange, size: 20.0),
                    const SizedBox(width: 8.0),
                    Text(
                      'RECORD DEFECT PIN #${widget.pins.length + 1}',
                      style: const TextStyle(
                        color: AppTokens.textOnDark,
                        fontSize: 14.0,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
              titlePadding: EdgeInsets.zero,
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('CLASSIFICATION:', style: TextStyle(fontSize: 12.0, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6.0),
                    Wrap(
                      spacing: 6.0,
                      runSpacing: 6.0,
                      children: DefectType.values.map((type) {
                        final isSel = selectedType == type;
                        return ChoiceChip(
                          label: Text(type.label),
                          selected: isSel,
                          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                          selectedColor: AppTokens.inverse,
                          backgroundColor: AppTokens.surface,
                          labelStyle: TextStyle(
                            color: isSel ? AppTokens.textOnDark : AppTokens.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 11.0,
                          ),
                          onSelected: (val) {
                            if (val) setDialogState(() => selectedType = type);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16.0),
                    const Text('SEVERITY:', style: TextStyle(fontSize: 12.0, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6.0),
                    ...DefectSeverity.values.map((sev) {
                      return RadioListTile<DefectSeverity>(
                        dense: true,
                        title: Text(sev.label, style: const TextStyle(fontSize: 12.0, fontWeight: FontWeight.w700)),
                        value: sev,
                        groupValue: selectedSeverity,
                        activeColor: AppTokens.redOrange,
                        onChanged: (val) {
                          if (val != null) setDialogState(() => selectedSeverity = val);
                        },
                      );
                    }),
                    const SizedBox(height: 12.0),
                    TextField(
                      controller: noteController,
                      decoration: const InputDecoration(
                        labelText: 'INSPECTOR NOTES (OPTIONAL)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.zero),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('CANCEL', style: TextStyle(color: AppTokens.textSecondary)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTokens.inverse,
                    foregroundColor: AppTokens.textOnDark,
                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                  ),
                  onPressed: () {
                    final newPin = DamagePin(
                      id: widget.pins.length + 1,
                      view: _activeView,
                      relativePosition: relativePosition,
                      type: selectedType,
                      severity: selectedSeverity,
                      note: noteController.text.trim().isEmpty ? null : noteController.text.trim(),
                    );
                    widget.onPinAdded?.call(newPin);
                    Navigator.of(ctx).pop();
                  },
                  child: const Text('PIN DAMAGE'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class ConditionSchematicPainter extends CustomPainter {
  final ConditionView view;

  const ConditionSchematicPainter({required this.view});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTokens.borderSolid
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final w = size.width;
    final h = size.height;

    switch (view) {
      case ConditionView.side:
        // Ground line
        canvas.drawLine(Offset(w * 0.05, h * 0.85), Offset(w * 0.95, h * 0.85), paint);
        // Wheels
        canvas.drawCircle(Offset(w * 0.25, h * 0.75), h * 0.10, paint);
        canvas.drawCircle(Offset(w * 0.75, h * 0.75), h * 0.10, paint);
        // Body outline
        final bodyPath = Path()
          ..moveTo(w * 0.08, h * 0.72)
          ..lineTo(w * 0.08, h * 0.52)
          ..lineTo(w * 0.22, h * 0.50) // Boot
          ..lineTo(w * 0.35, h * 0.25) // Rear glass
          ..lineTo(w * 0.65, h * 0.25) // Roof
          ..lineTo(w * 0.78, h * 0.50) // Windshield
          ..lineTo(w * 0.92, h * 0.54) // Bonnet
          ..lineTo(w * 0.92, h * 0.72);
        canvas.drawPath(bodyPath, paint);
        // Door seams
        canvas.drawLine(Offset(w * 0.35, h * 0.50), Offset(w * 0.35, h * 0.72), paint);
        canvas.drawLine(Offset(w * 0.50, h * 0.25), Offset(w * 0.50, h * 0.72), paint);
        canvas.drawLine(Offset(w * 0.65, h * 0.50), Offset(w * 0.65, h * 0.72), paint);
        break;

      case ConditionView.front:
        // Front bumper, grille, headlights, windshield
        final frontPath = Path()
          ..addRect(Rect.fromLTWH(w * 0.20, h * 0.40, w * 0.60, h * 0.35));
        canvas.drawPath(frontPath, paint);
        // Windshield trapezoid
        final windPath = Path()
          ..moveTo(w * 0.25, h * 0.40)
          ..lineTo(w * 0.32, h * 0.18)
          ..lineTo(w * 0.68, h * 0.18)
          ..lineTo(w * 0.75, h * 0.40)
          ..close();
        canvas.drawPath(windPath, paint);
        // Headlights
        canvas.drawRect(Rect.fromLTWH(w * 0.22, h * 0.45, w * 0.12, h * 0.08), paint);
        canvas.drawRect(Rect.fromLTWH(w * 0.66, h * 0.45, w * 0.12, h * 0.08), paint);
        // Grille
        canvas.drawRect(Rect.fromLTWH(w * 0.38, h * 0.48, w * 0.24, h * 0.15), paint);
        break;

      case ConditionView.rear:
        // Rear boot, taillights, rear glass
        final rearPath = Path()
          ..addRect(Rect.fromLTWH(w * 0.20, h * 0.40, w * 0.60, h * 0.35));
        canvas.drawPath(rearPath, paint);
        final rearGlass = Path()
          ..moveTo(w * 0.25, h * 0.40)
          ..lineTo(w * 0.32, h * 0.18)
          ..lineTo(w * 0.68, h * 0.18)
          ..lineTo(w * 0.75, h * 0.40)
          ..close();
        canvas.drawPath(rearGlass, paint);
        // Taillights
        canvas.drawRect(Rect.fromLTWH(w * 0.22, h * 0.45, w * 0.10, h * 0.12), paint);
        canvas.drawRect(Rect.fromLTWH(w * 0.68, h * 0.45, w * 0.10, h * 0.12), paint);
        // License plate zone
        canvas.drawRect(Rect.fromLTWH(w * 0.40, h * 0.58, w * 0.20, h * 0.08), paint);
        break;

      case ConditionView.top:
        // Full top projection: Bonnet, Roof, Boot, Pillars
        final topContour = Path()
          ..moveTo(w * 0.35, h * 0.08)
          ..lineTo(w * 0.65, h * 0.08) // Front bumper
          ..lineTo(w * 0.72, h * 0.30) // Front fenders
          ..lineTo(w * 0.72, h * 0.75) // Doors
          ..lineTo(w * 0.68, h * 0.92) // Rear bumper
          ..lineTo(w * 0.32, h * 0.92)
          ..lineTo(w * 0.28, h * 0.75)
          ..lineTo(w * 0.28, h * 0.30)
          ..close();
        canvas.drawPath(topContour, paint);
        // Windshield
        canvas.drawLine(Offset(w * 0.32, h * 0.32), Offset(w * 0.68, h * 0.32), paint);
        // Roof
        canvas.drawRect(Rect.fromLTWH(w * 0.32, h * 0.35, w * 0.36, h * 0.35), paint);
        // Rear glass
        canvas.drawLine(Offset(w * 0.32, h * 0.72), Offset(w * 0.68, h * 0.72), paint);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant ConditionSchematicPainter oldDelegate) {
    return oldDelegate.view != view;
  }
}
