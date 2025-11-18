// main.dart
import 'package:flutter/material.dart';
import 'dart:math';

void main() {
  runApp(const TriangleMultiTouchApp());
}

class TriangleMultiTouchApp extends StatelessWidget {
  const TriangleMultiTouchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Multi-touch Triangle',
      theme: ThemeData(
        primarySwatch: Colors.teal,
      ),
      home: const Scaffold(
        body: SafeArea(
          child: TriangleEditor(),
        ),
      ),
    );
  }
}

class TriangleEditor extends StatefulWidget {
  const TriangleEditor({super.key});

  @override
  State<TriangleEditor> createState() => _TriangleEditorState();
}

class _TriangleEditorState extends State<TriangleEditor> {
  late List<Offset> vertices;
  final double handleRadius = 22.0;
  final Map<int, int> pointerToVertex = {};
  final double margin = 50.0;
  bool initialized = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      if (!initialized) {
        _initVertices(constraints.maxWidth, constraints.maxHeight);
        initialized = true;
      }

      return Stack(
        children: [
          Positioned.fill(
            child: Container(
              color: Colors.white,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  const Text(
                    'Chạm và kéo từng đỉnh để thay đổi tam giác. Hỗ trợ đa chạm (nhiều ngón tay).',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          Listener(
            onPointerDown: _onPointerDown,
            onPointerMove: _onPointerMove,
            onPointerUp: _onPointerUpOrCancel,
            onPointerCancel: _onPointerUpOrCancel,
            behavior: HitTestBehavior.opaque,
            child: CustomPaint(
              size: Size.infinite,
              painter: TrianglePainter(
                vertices: vertices,
                handleRadius: handleRadius,
              ),
            ),
          ),
        ],
      );
    });
  }

  void _initVertices(double w, double h) {
    vertices = [
      Offset(margin, h - margin), // bottom-left
      Offset(w - margin, h - margin - 10), // bottom-right
      Offset(w / 2, margin + 20), // top
    ];
  }

  void _onPointerDown(PointerDownEvent event) {
    final pos = event.localPosition;
    final int? found = _hitTestVertex(pos);
    if (found != null) {
      pointerToVertex[event.pointer] = found;
      setState(() {
        vertices[found] = pos;
      });
    }
  }

  void _onPointerMove(PointerMoveEvent event) {
    final int pid = event.pointer;
    if (pointerToVertex.containsKey(pid)) {
      final int vertexIndex = pointerToVertex[pid]!;
      setState(() {
        vertices[vertexIndex] = event.localPosition;
      });
    }
  }

  void _onPointerUpOrCancel(PointerEvent event) {
    pointerToVertex.remove(event.pointer);
  }

  int? _hitTestVertex(Offset pos) {
    final double threshold = handleRadius + 12.0;
    for (int i = 0; i < vertices.length; i++) {
      final double dx = vertices[i].dx - pos.dx;
      final double dy = vertices[i].dy - pos.dy;
      final double dist = sqrt(dx * dx + dy * dy);
      if (dist <= threshold) return i;
    }
    return null;
  }
}

class TrianglePainter extends CustomPainter {
  final List<Offset> vertices;
  final double handleRadius;

  TrianglePainter({
    required this.vertices,
    required this.handleRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint linePaint = Paint()
      ..color = const Color(0xFF0F6276)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final Path trianglePath = Path()
      ..moveTo(vertices[0].dx, vertices[0].dy)
      ..lineTo(vertices[1].dx, vertices[1].dy)
      ..lineTo(vertices[2].dx, vertices[2].dy)
      ..close();

    final Paint fillPaint = Paint()
      ..color = const Color(0x220F6276)
      ..style = PaintingStyle.fill;

    canvas.drawPath(trianglePath, fillPaint);
    canvas.drawPath(trianglePath, linePaint);

    for (int i = 0; i < vertices.length; i++) {
      _drawHandle(canvas, vertices[i], i);
    }
  }

  void _drawHandle(Canvas canvas, Offset center, int index) {
    final Paint shadow = Paint()
      ..color = Colors.black.withOpacity(0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(center.translate(2, 3), handleRadius, shadow);

    final Paint fill = Paint()
      ..color = const Color(0xFF9EE9FF)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, handleRadius, fill);

    final Path wedge = Path();
    wedge.moveTo(center.dx - 8, center.dy + 4);
    wedge.lineTo(center.dx - 2, center.dy - 8);
    wedge.lineTo(center.dx + 12, center.dy + 4);
    wedge.close();
    final Paint wedgePaint = Paint()
      ..color = const Color(0x660F6276)
      ..style = PaintingStyle.fill;
    canvas.drawPath(wedge, wedgePaint);

    final Paint stroke = Paint()
      ..color = const Color(0xFF08313C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(center, handleRadius, stroke);

    final TextPainter tp = TextPainter(
      text: TextSpan(
        text: '${index + 1}',
        style: const TextStyle(
          color: Color(0xFF08313C),
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    // <-- SỬA: truyền cả canvas & offset
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant TrianglePainter oldDelegate) {
    if (oldDelegate.vertices.length != vertices.length) return true;
    for (int i = 0; i < vertices.length; i++) {
      if (oldDelegate.vertices[i] != vertices[i]) return true;
    }
    return false;
  }
}
