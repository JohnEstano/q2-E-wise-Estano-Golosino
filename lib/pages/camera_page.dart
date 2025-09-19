// lib/pages/camera_page.dart
// Camera + AI analysis page (UI updated per request).
// - Gray full-screen shimmer skeleton while analyzing with top large rounded rectangle and three stacked row cards at the bottom
// - Output UI: white components, no shadows, high-contrast black text
// IMPORTANT: Put your API key in .env as OPENAI_API_KEY (use flutter_dotenv).

import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shimmer/shimmer.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});
  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  int _selectedCameraIndex = 0;
  bool _isCameraReady = false;
  bool _isTakingPicture = false;

  // zoom
  double _zoom = 1.0;
  double _minZoom = 1.0;
  double _maxZoom = 4.0;
  double _baseZoom = 1.0;

  // flash
  bool _supportsFlash = false;
  FlashMode _flashMode = FlashMode.off;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setupCameras();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _disposeController();
    super.dispose();
  }

  void _disposeController() {
    try {
      _controller?.dispose();
    } catch (_) {}
    _controller = null;
    _isCameraReady = false;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // delegate to async handler
    _handleLifecycle(state);
  }

  Future<void> _handleLifecycle(AppLifecycleState state) async {
    if (!mounted) return;
    try {
      if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
        if (_controller != null && _controller!.value.isInitialized) {
          try {
            await _controller!.pausePreview();
            debugPrint('Camera preview paused (lifecycle).');
            if (mounted) setState(() => _isCameraReady = false);
          } catch (e) {
            debugPrint('pausePreview failed, disposing controller: $e');
            _disposeController();
          }
        }
      } else if (state == AppLifecycleState.resumed) {
        // On resume, try to resume preview; if that fails, re-init the controller.
        if (_controller != null) {
          try {
            await Future.delayed(const Duration(milliseconds: 120));
            await _controller!.resumePreview();
            debugPrint('Camera preview resumed (lifecycle).');
            if (mounted) setState(() => _isCameraReady = true);
          } catch (e) {
            debugPrint('resumePreview failed, reinitializing camera: $e');
            if (_cameras != null && _cameras!.isNotEmpty) {
              final index = (_selectedCameraIndex >= 0 && _selectedCameraIndex < _cameras!.length) ? _selectedCameraIndex : 0;
              await _initController(_cameras![index]);
            } else {
              await _setupCameras();
            }
          }
        } else {
          if (_cameras != null && _cameras!.isNotEmpty) {
            final index = (_selectedCameraIndex >= 0 && _selectedCameraIndex < _cameras!.length) ? _selectedCameraIndex : 0;
            await _initController(_cameras![index]);
          } else {
            await _setupCameras();
          }
        }
      }
    } catch (e, st) {
      debugPrint('Lifecycle handler error: $e\n$st');
      try {
        if ((_controller == null || !_controller!.value.isInitialized) && mounted) await _setupCameras();
      } catch (_) {}
    }
  }

  Future<void> _ensurePermissions() async {
    final status = await Permission.camera.status;
    if (!status.isGranted) {
      final result = await Permission.camera.request();
      if (!result.isGranted) throw Exception('Camera permission denied');
    }
    if (Platform.isAndroid) {
      final s = await Permission.storage.status;
      if (!s.isGranted) await Permission.storage.request();
    } else if (Platform.isIOS) {
      final p = await Permission.photos.status;
      if (!p.isGranted) await Permission.photos.request();
    }
  }

  Future<void> _setupCameras() async {
    try {
      await _ensurePermissions();
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        setState(() => _isCameraReady = false);
        return;
      }

      final backIndex = _cameras!.indexWhere((c) => c.lensDirection == CameraLensDirection.back);
      _selectedCameraIndex = backIndex >= 0 ? backIndex : 0;
      await _initController(_cameras![_selectedCameraIndex]);
    } catch (e, st) {
      debugPrint('Error initializing cameras: $e\n$st');
      setState(() => _isCameraReady = false);
    }
  }

  Future<void> _initController(CameraDescription cameraDescription) async {
    try {
      // dispose existing (safer) before creating new
      if (_controller != null) {
        try {
          await _controller!.dispose();
        } catch (_) {}
        _controller = null;
        _isCameraReady = false;
      }

      final controller = CameraController(
        cameraDescription,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      _controller = controller;
      await controller.initialize();

      try {
        _minZoom = await controller.getMinZoomLevel();
        _maxZoom = await controller.getMaxZoomLevel();
      } catch (_) {
        _minZoom = 1.0;
        _maxZoom = 4.0;
      }
      _zoom = 1.0;
      try {
        await controller.setZoomLevel(_zoom);
      } catch (_) {}

      try {
        await controller.setFlashMode(_flashMode);
        _supportsFlash = true;
      } catch (_) {
        _supportsFlash = false;
      }

      if (mounted) setState(() => _isCameraReady = true);
    } catch (e, st) {
      debugPrint('Camera init error: $e\n$st');
      if (mounted) setState(() => _isCameraReady = false);
    }
  }

  Future<void> _toggleFlash() async {
    if (_controller == null || !_supportsFlash) return;
    final next = _flashMode == FlashMode.off
        ? FlashMode.auto
        : _flashMode == FlashMode.auto
        ? FlashMode.always
        : FlashMode.off;
    try {
      await _controller!.setFlashMode(next);
      setState(() => _flashMode = next);
    } catch (e) {
      debugPrint('Flash toggle error: $e');
    }
  }

  Future<void> _takePicture() async {
    if (!_isCameraReady || _controller == null || _isTakingPicture) return;
    setState(() => _isTakingPicture = true);

    try {
      // immediate short feedback
      await Future.delayed(const Duration(milliseconds: 80));
      final XFile raw = await _controller!.takePicture();
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String fileName = 'capture_${timestamp}.jpg';
      final String destPath = '${appDir.path}/$fileName';
      final saved = await File(raw.path).copy(destPath);

      // slight delay to reduce race conditions on some devices
      await Future.delayed(const Duration(milliseconds: 120));

      if (!mounted) return;

      final resultPath = await Navigator.of(context).push<String?>(
        MaterialPageRoute(
          builder: (c) => AnalysisPage(imagePath: saved.path),
        ),
      );

      if (resultPath != null && resultPath.isNotEmpty && mounted) {
        Navigator.of(context).pop(resultPath);
      } else {
        // ensure preview resumed when returning
        try {
          await _controller?.resumePreview();
          if (mounted) setState(() => _isCameraReady = true);
        } catch (_) {
          if (mounted) await _setupCameras();
        }
      }
    } catch (e, st) {
      debugPrint('Take picture error: $e\n$st');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to capture photo')));
    } finally {
      if (mounted) setState(() => _isTakingPicture = false);
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      // pause preview before launching native picker to reduce camera conflicts
      if (_controller != null && _controller!.value.isInitialized) {
        try {
          await _controller!.pausePreview();
          if (mounted) setState(() => _isCameraReady = false);
        } catch (e) {
          debugPrint('pausePreview before gallery failed: $e');
          _disposeController();
        }
      }

      // double-check gallery permission
      if (Platform.isAndroid) {
        final s = await Permission.storage.status;
        if (!s.isGranted) {
          final r = await Permission.storage.request();
          if (!r.isGranted) {
            try {
              await _controller?.resumePreview();
              if (mounted) setState(() => _isCameraReady = true);
            } catch (_) {
              if (mounted) await _setupCameras();
            }
            return;
          }
        }
      } else if (Platform.isIOS) {
        final p = await Permission.photos.status;
        if (!p.isGranted) {
          final r = await Permission.photos.request();
          if (!r.isGranted) {
            try {
              await _controller?.resumePreview();
              if (mounted) setState(() => _isCameraReady = true);
            } catch (_) {
              if (mounted) await _setupCameras();
            }
            return;
          }
        }
      }

      final XFile? picked = await _picker.pickImage(source: ImageSource.gallery);
      if (picked == null) {
        // canceled -> resume preview
        try {
          await _controller?.resumePreview();
          if (mounted) setState(() => _isCameraReady = true);
        } catch (e) {
          debugPrint('resumePreview after gallery cancel failed: $e');
          if (mounted) await _setupCameras();
        }
        return;
      }

      final Directory appDir = await getApplicationDocumentsDirectory();
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String fileName = 'gallery_${timestamp}.jpg';
      final String destPath = '${appDir.path}/$fileName';
      final saved = await File(picked.path).copy(destPath);

      if (!mounted) return;

      final resultPath = await Navigator.of(context).push<String?>(
        MaterialPageRoute(
          builder: (c) => AnalysisPage(imagePath: saved.path),
        ),
      );

      if (resultPath != null && resultPath.isNotEmpty && mounted) {
        Navigator.of(context).pop(resultPath);
      } else {
        try {
          await _controller?.resumePreview();
          if (mounted) setState(() => _isCameraReady = true);
        } catch (e) {
          debugPrint('resumePreview after gallery flow failed: $e');
          if (mounted) await _setupCameras();
        }
      }
    } catch (e, st) {
      debugPrint('Gallery pick error: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to pick image')));
        try {
          await _controller?.resumePreview();
          if (mounted) setState(() => _isCameraReady = true);
        } catch (_) {
          if (mounted) await _setupCameras();
        }
      }
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras == null || _cameras!.isEmpty) return;
    try {
      _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras!.length;
      await _initController(_cameras![_selectedCameraIndex]);
    } catch (e) {
      debugPrint('Switch camera error: $e');
    }
  }

  void _onScaleStart(ScaleStartDetails details) {
    _baseZoom = _zoom;
  }

  Future<void> _onScaleUpdate(ScaleUpdateDetails details) async {
    if (_controller == null) return;
    final newZoom = (_baseZoom * details.scale).clamp(_minZoom, _maxZoom);
    if ((newZoom - _zoom).abs() > 0.01) {
      _zoom = newZoom;
      try {
        await _controller!.setZoomLevel(_zoom);
      } catch (e) {
        debugPrint('setZoomLevel error: $e');
      }
      if (mounted) setState(() {});
    }
  }

  Widget _buildTopOverlay() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          InkWell(
            onTap: () => Navigator.of(context).maybePop(),
            child: const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 28),
          ),
          const Expanded(
            child: Center(
              child: Text(
                'Ewise.',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          IconButton(
            onPressed: _switchCamera,
            icon: const Icon(Icons.cameraswitch, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // flash left
          GestureDetector(
            onTap: _supportsFlash ? _toggleFlash : null,
            child: Container(
              padding: const EdgeInsets.all(6),
              child: Icon(
                _supportsFlash ? (_flashMode == FlashMode.off ? Icons.flash_off : Icons.flash_on) : Icons.flash_off,
                color: _supportsFlash ? Colors.white : Colors.white54,
                size: 28,
              ),
            ),
          ),

          // shutter center
          GestureDetector(
            onTap: _takePicture,
            child: Container(
              width: 78,
              height: 78,
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 4)),
              child: Center(
                // keep outer container stable; animate inner with scale + borderRadius to avoid layout jitter
                child: ClipRect(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      // always a rectangle so layout doesn't change shape type; large borderRadius to simulate circle
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(_isTakingPicture ? 8 : 999),
                    ),
                    child: AnimatedScale(
                      scale: _isTakingPicture ? 0.42 : 1.0,
                      duration: const Duration(milliseconds: 160),
                      curve: Curves.easeOut,
                      child: SizedBox.expand(),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // gallery/select photos on the right
          GestureDetector(
            onTap: _pickFromGallery,
            child: Container(
              padding: const EdgeInsets.all(6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.photo_library, color: Colors.white, size: 26),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildZoomIndicator() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        margin: const EdgeInsets.only(bottom: 22),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(color: const Color.fromRGBO(0, 0, 0, 140), borderRadius: BorderRadius.circular(24)),
        child: Text('${_zoom.toStringAsFixed(1)}x',
            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
      ),
    );
  }

  /// Show helpful scanning tips dialog (bottom-right info button triggers this)
  void _showScanTips() {
    showDialog(
      context: context,
      builder: (c) {
        final primary = Theme.of(c).colorScheme.primary;
        // Explicitly set dialog background/text styles for good contrast
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text('Tips for scanning e-waste', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w800)),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Quick practical tips', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.black87)),
                const SizedBox(height: 8),
                _tipRow('Scan only items you intend to analyze or dispose — devices, batteries, components.'),
                _tipRow('Place the item on a plain, uncluttered background (solid color works best).'),
                _tipRow('Make sure labels, ports, serial numbers, and maker logos are visible when possible.'),
                _tipRow('Capture clear photos of intricate areas (ports, battery compartment, circuit boards) if safe.'),
                _tipRow('Fill most of the frame with the device — avoid tiny distant shots.'),
                _tipRow('Use natural, diffuse light. Avoid harsh backlight or strong reflections/glare.'),
                _tipRow('Hold camera steady or brace against a surface; try multiple angles for better identification.'),
                _tipRow('If the device is dirty, gently wipe visible dust — not liquids or solvents.'),
                _tipRow('Do NOT open sealed batteries or damaged cells. Keep a safe distance from swollen batteries.'),
                _tipRow('Avoid scanning wet/damaged items or anything emitting smoke or heat — follow safety procedures.'),
                const SizedBox(height: 8),
                Text('Why these help', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.black87)),
                const SizedBox(height: 6),
                Text(
                  'Cleaner, well-lit, close-up photos help the AI detect brand/model/components and estimate hazards more accurately.',
                  style: TextStyle(color: Colors.black87, height: 1.28),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(c).pop(),
              style: TextButton.styleFrom(foregroundColor: primary),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _tipRow(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle_outline, size: 18, color: Colors.green[700]),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(color: Colors.black87, height: 1.28))),
        ],
      ),
    );
  }

  Widget _buildCameraPreview() {
    if (!_isCameraReady || _controller == null || !_controller!.value.isInitialized) {
      return Container(
        color: Colors.black,
        child: const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white))),
      );
    }
    final controller = _controller!;
    return Column(children: [
      Expanded(
        flex: 6,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(children: [
              Positioned.fill(child: CameraPreview(controller)),
              // gesture layer for zoom
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onScaleStart: _onScaleStart,
                  onScaleUpdate: _onScaleUpdate,
                  child: Container(color: Colors.transparent),
                ),
              ),
              Positioned(top: 0, left: 0, right: 0, child: _buildTopOverlay()),
              // small info button at bottom-right of preview overlay
              Positioned(
                bottom: 22,
                right: 12,
                child: Semantics(
                  label: 'Scan tips',
                  hint: 'Open helpful tips for scanning e-waste',
                  button: true,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: _showScanTips,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color.fromRGBO(0, 0, 0, 120),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.info_outline, color: Colors.white, size: 22),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned.fill(child: Column(children: const [Spacer(), SizedBox()])),
              Positioned(bottom: 14, left: 0, right: 0, child: _buildZoomIndicator()),
            ]),
          ),
        ),
      ),
      Expanded(
        flex: 3,
        child: Container(
          color: Colors.black,
          child: Column(children: [
            const SizedBox(height: 6),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 6.0),
              child: Text('Scan your Ewaste',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
            ),
            const Spacer(),
            _buildBottomControls(),
          ]),
        ),
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
    return Scaffold(backgroundColor: Colors.black, body: SafeArea(child: _buildCameraPreview()));
  }
}

/// ---------------------------
/// Single OpenAI vision request returning strict JSON (RESPONSES API)
/// ---------------------------
class OpenAIImageAnalyzer {
  static const String visionModel = 'gpt-4o-mini';

  static Future<Map<String, dynamic>> analyzeImageOnePrompt(String imagePath) async {
    final apiKey = dotenv.env['OPENAI_API_KEY'] ?? '';
    if (apiKey.isEmpty) {
      return {'unknown': true, 'message': 'OPENAI_API_KEY not set in .env — analysis skipped.'};
    }

    final file = File(imagePath);
    if (!await file.exists()) return {'unknown': true, 'message': 'Image file not found'};

    final bytes = await file.readAsBytes();
    final b64 = base64Encode(bytes);
    final dataUri = 'data:image/jpeg;base64,$b64';

    final systemPrompt = '''
You are a precise assistant. The user scanned an image of an item (expected e-waste).
Produce EXACTLY one JSON object (no extra text, no markdown). Keys ideally include:

"title", "description", "brand", "model", "year", "color", "category",
"status", "recommendedActions", "components" (array), "hazards" (array),
"weightKg": number, "materialStreams": object (e.g. {"plastics":30,"ferrous":40,"nonFerrous":20,"pcb":5,"hazardous":5}),
"disposalPath", "metrics" and "notes".

Rules:
- If not e-waste return {"unknown":true,"message":"unknown ewaste - please scan an ewaste"}
- Be concise. Prefer short arrays/strings and conservative numeric estimates.
''';

    final userPrompt = 'Identify brand, model, year, condition, components, hazards, weight (kg), material streams and disposal path. Return only a single JSON object.';

    final uri = Uri.parse('https://api.openai.com/v1/responses');

    final payload = {
      'model': visionModel,
      'input': [
        {
          'role': 'user',
          'content': [
            {'type': 'input_text', 'text': systemPrompt},
            {'type': 'input_image', 'image_url': dataUri},
            {'type': 'input_text', 'text': userPrompt},
          ]
        }
      ],
      'temperature': 0.0,
      'max_output_tokens': 700,
    };

    try {
      final resp = await http
          .post(uri,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $apiKey',
          },
          body: jsonEncode(payload))
          .timeout(const Duration(seconds: 40));

      if (resp.statusCode == 404) {
        debugPrint('OpenAI Responses API 404: ${resp.body}');
        return {
          'unknown': true,
          'message':
          'OpenAI 404: model not found or endpoint not available. Ensure your account has access to "$visionModel" and that you are using the Responses API.'
        };
      }

      if (resp.statusCode != 200) {
        debugPrint('OpenAI vision returned ${resp.statusCode}: ${resp.body}');
        return {'unknown': true, 'message': 'OpenAI vision error ${resp.statusCode}', 'raw': resp.body};
      }

      final Map<String, dynamic> body = jsonDecode(resp.body);

      String raw = '';

      try {
        final List<dynamic>? output = (body['output'] is List) ? List<dynamic>.from(body['output']) : null;
        if (output != null) {
          for (final outItem in output) {
            final List<dynamic>? content = (outItem is Map && outItem['content'] is List) ? List<dynamic>.from(outItem['content']) : null;
            if (content != null) {
              for (final c in content) {
                if (c is Map) {
                  final t = (c['text'] ?? c['content'] ?? '').toString();
                  if (t.isNotEmpty) {
                    raw += (raw.isEmpty ? '' : '\n') + t;
                  }
                }
              }
            }
          }
        }

        if (raw.isEmpty) {
          if (body['output_text'] != null) raw = body['output_text'].toString();
          if (raw.isEmpty && body['answer'] != null) raw = body['answer'].toString();
        }
      } catch (e) {
        debugPrint('Failed to extract text from Responses body: $e\nbody: ${resp.body}');
      }

      if (raw.isEmpty) raw = jsonEncode(body);

      try {
        final start = raw.indexOf('{');
        final end = raw.lastIndexOf('}');
        if (start >= 0 && end > start) {
          final jsonPart = raw.substring(start, end + 1);
          final parsed = jsonDecode(jsonPart);
          if (parsed is Map<String, dynamic>) return parsed;
        }
        final direct = jsonDecode(raw);
        if (direct is Map<String, dynamic>) return direct;
      } catch (e) {
        debugPrint('Failed to parse JSON from AI output: $e\nraw: $raw');
        return {'unknown': true, 'message': 'Could not parse AI output', 'raw': raw};
      }

      return {'unknown': true, 'message': 'Unexpected AI output', 'raw': raw};
    } catch (e) {
      debugPrint('OpenAI request failed: $e');
      return {'unknown': true, 'message': 'OpenAI request failed: $e'};
    }
  }
}

/// ---------------------------
/// AnalysisPage (UI rebuilt per request, readability & contrast fixes)
/// ---------------------------
class AnalysisPage extends StatefulWidget {
  final String imagePath;
  const AnalysisPage({super.key, required this.imagePath});
  @override
  State<AnalysisPage> createState() => _AnalysisPageState();
}

class _AnalysisPageState extends State<AnalysisPage> {
  bool _isAnalyzing = true;
  String? _error;
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;

  // extracted fields (with safe defaults)
  String _brand = '';
  String _model = '';
  String _year = '';
  String _color = '';
  String _category = 'Other';
  String _status = 'unknown';
  double? _weightKg;
  List<String> _components = [];
  List<String> _hazards = [];
  Map<String, int> _materialStreams = {}; // percentages
  String _disposalPath = '';
  Map<String, dynamic> _rawMetrics = {};

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _analyze();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // Normalize freeform category labels into controlled set
  String _normalizeCategory(String raw) {
    final s = raw.toLowerCase();
    if (s.contains('batt') || s.contains('cell') || s.contains('battery')) return 'Batteries';
    if (s.contains('board') || s.contains('pcb') || s.contains('component') || s.contains('module')) return 'Components';
    if (s.contains('phone') || s.contains('laptop') || s.contains('computer') || s.contains('device') || s.contains('tv') || s.contains('appliance')) return 'Devices';
    if (s.contains('accessory') || s.contains('charger') || s.contains('cable') || s.contains('earbud') || s.contains('headphone')) return 'Accessories';
    if (s.contains('electronic') || s.contains('electronics')) return 'Electronics';
    // fallback: if user or AI labelled 'e-waste' or similar, prefer Electronics
    if (s.contains('e-waste') || s == 'ewaste' || s == 'e waste' || s == 'e waste') return 'Electronics';
    // default
    return s.isNotEmpty ? (s[0].toUpperCase() + s.substring(1)) : 'Other';
  }

  // Return 3 short disposal/handling suggestions tailored to category
  List<Map<String, String>> _disposalSuggestions(String category) {
    switch (category) {
      case 'Batteries':
        return [
          {
            'title': 'Safe handling',
            'body': 'Do not puncture or crush. If terminals exposed, tape them. Store separately in non-conductive container.'
          },
          {
            'title': 'Where to take',
            'body': 'Take to certified battery recycler or retailer take-back program (local e-waste drop-off).'
          },
          {
            'title': 'Prep steps',
            'body': 'Place in individual plastic bags, label if damaged, avoid mixing with household trash.'
          },
        ];
      case 'Components':
        return [
          {
            'title': 'Hazard note',
            'body': 'PCBs and capacitors may contain hazardous materials. Avoid burning or shredding at home.'
          },
          {
            'title': 'Where to take',
            'body': 'Take to professional e-waste recycler that handles PCBs and electronic components.'
          },
          {
            'title': 'Prep steps',
            'body': 'Keep small components in a sealed container; do not mix with general waste.'
          },
        ];
      case 'Devices':
        return [
          {
            'title': 'Data & battery',
            'body': 'If functional, back up & wipe personal data. Remove battery if removable and recycle separately.'
          },
          {
            'title': 'Where to take',
            'body': 'Donate working units or drop off at certified electronics recycler or manufacturer take-back.'
          },
          {
            'title': 'Prep steps',
            'body': 'Remove SIM/memory cards, wrap fragile screens, and package to avoid leakage.'
          },
        ];
      case 'Accessories':
        return [
          {
            'title': 'Sort & separate',
            'body': 'Separate cables, chargers, and plastics from devices; many stores accept accessory recycling.'
          },
          {
            'title': 'Where to take',
            'body': 'Retail take-back programs or municipal e-waste collection points.'
          },
          {
            'title': 'Prep steps',
            'body': 'Bundle cables neatly; avoid mixing with hazardous components.'
          },
        ];
      case 'Electronics':
      default:
        return [
          {
            'title': 'General caution',
            'body': 'Electronics can contain hazardous parts; do not incinerate or dump in regular trash.'
          },
          {
            'title': 'Where to take',
            'body': 'Use certified e-waste recyclers or manufacturer/retailer take-back services.'
          },
          {
            'title': 'Prep steps',
            'body': 'Remove batteries & data storage if possible; package to avoid leakage or short circuits.'
          },
        ];
    }
  }

  Future<void> _analyze() async {
    // making _analyze robust: explicit try/catch/finally so shimmer always clears
    if (!mounted) return;
    setState(() {
      _isAnalyzing = true;
      _error = null;
    });

    try {
      final f = File(widget.imagePath);
      if (!await f.exists()) {
        setState(() {
          _error = 'Image file not found at path.';
          _titleController.text = 'Unknown / Not recognized';
          _descriptionController.text = _error!;
        });
        return;
      }

      debugPrint('Starting image analysis for ${widget.imagePath}');

      // add a safety timeout around the entire analysis (in case underlying call hangs)
      final Map<String, dynamic> result = await OpenAIImageAnalyzer
          .analyzeImageOnePrompt(widget.imagePath)
          .timeout(const Duration(seconds: 50), onTimeout: () => {'unknown': true, 'message': 'Analysis timed out'});

      debugPrint('Analysis result: $result');

      if (result.containsKey('unknown') && result['unknown'] == true) {
        setState(() {
          _titleController.text = 'Unknown / Not recognized';
          _descriptionController.text = (result['message'] ?? 'unknown ewaste - please scan an ewaste').toString();
          _error = (result['message'] ?? null)?.toString();
        });
        return;
      }

      // populate fields defensively and normalize category
      try {
        _titleController.text = (result['title'] ?? '').toString();
        // keep description reasonably short for UI readability
        final rawDesc = (result['description'] ?? '').toString();
        _descriptionController.text = rawDesc.length > 400 ? '${rawDesc.substring(0, 380)}…' : rawDesc;

        _brand = (result['brand'] ?? result['manufacturer'] ?? '').toString();
        _model = (result['model'] ?? '').toString();
        _year = (result['year'] ?? '').toString();
        _color = (result['color'] ?? '').toString();

        // normalize category into chosen buckets
        final rawCategory = (result['category'] ?? '').toString();
        _category = _normalizeCategory(rawCategory);

        _status = (result['status'] ?? 'unknown').toString();

        // components/hazards may be arrays or comma-separated strings
        final comp = result['components'];
        if (comp is List) _components = comp.map((e) => e.toString()).toList();
        else if (comp is String && comp.isNotEmpty) _components = comp.split(',').map((e) => e.trim()).toList();

        final hz = result['hazards'];
        if (hz is List) _hazards = hz.map((e) => e.toString()).toList();
        else if (hz is String && hz.isNotEmpty) _hazards = hz.split(',').map((e) => e.trim()).toList();

        // weight
        final w = result['weightKg'] ?? result['weight_kg'] ?? result['weight'];
        if (w != null) {
          _weightKg = double.tryParse(w.toString());
        }

        // materialStreams: object of percentages
        final ms = result['materialStreams'] ?? result['materials'];
        if (ms is Map) {
          _materialStreams = {};
          ms.forEach((k, v) {
            final val = int.tryParse(v.toString()) ?? (v is num ? v.toInt() : 0);
            _materialStreams[k.toString()] = val;
          });
        } else {
          _materialStreams = {};
        }

        // disposal path: limit length but keep useful parts
        final rawDisposal = (result['disposalPath'] ?? result['disposal_path'] ?? result['disposal'] ?? '').toString();
        _disposalPath = rawDisposal.length > 600 ? '${rawDisposal.substring(0, 580)}…' : rawDisposal;

        _rawMetrics = (result['metrics'] is Map) ? Map<String, dynamic>.from(result['metrics']) : {};
      } catch (e, st) {
        debugPrint('Populate fields error: $e\n$st');
        _error = 'Failed to parse analysis output.';
      }
    } on TimeoutException catch (e) {
      debugPrint('Analysis timeout: $e');
      if (mounted) setState(() => _error = 'Analysis timed out. Try again.');
    } catch (e, st) {
      debugPrint('Full analysis error: $e\n$st');
      if (mounted) setState(() => _error = 'Analysis failed: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  // small helpers for UI
  Widget _chipList(List<String> items) {
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: items.isEmpty
          ? [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration:
          BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200)),
          child: const Text('None', style: TextStyle(color: Colors.black87)),
        )
      ]
          : items
          .map((t) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration:
        BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200)),
        child: Text(t, style: const TextStyle(color: Colors.black87)),
      ))
          .toList(),
    );
  }

  Widget _materialRow(String label, int percent) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          SizedBox(width: 100, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87))),
          const SizedBox(width: 8),
          Expanded(
            child: LayoutBuilder(builder: (context, constraints) {
              final w = constraints.maxWidth;
              final fill = (percent.clamp(0, 100) / 100) * w;
              return Stack(children: [
                Container(height: 18, decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8))),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  width: fill,
                  height: 18,
                  decoration:
                  BoxDecoration(color: Theme.of(context).colorScheme.primary, borderRadius: BorderRadius.circular(8)),
                ),
              ]);
            }),
          ),
          const SizedBox(width: 10),
          SizedBox(width: 46, child: Text('$percent%', style: const TextStyle(color: Colors.black87))),
        ],
      ),
    );
  }

  void _saveLog() {
    // demo: create payload and show snackbar
    final payload = {
      'title': _titleController.text,
      'brand': _brand,
      'model': _model,
      'year': _year,
      'category': _category,
      'status': _status,
      'components': _components,
      'hazards': _hazards,
      'weightKg': _weightKg,
      'materialStreams': _materialStreams,
      'disposalPath': _disposalPath,
      'metrics': _rawMetrics,
    };
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Logged (demo): ${jsonEncode(payload).substring(0, 120)}...'))); // TODO: actually send to backend
  }

  void _requestPickup() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pickup requested (demo).'))); // TODO: real pickup flow
  }

  // New shimmer skeleton per your request:
  // - Gray (not black)
  // - No text
  // - Big rounded square at top and three stacked row cards at the bottom
  Widget _skeletonScreen(BuildContext context) {
    final base = Colors.grey.shade300;
    final highlight = Colors.grey.shade100;
    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      child: SizedBox.expand(
        child: Column(
          children: [
            // top large rounded square (takes majority of screen)
            Expanded(
              flex: 6,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
                child: Container(
                  decoration: BoxDecoration(color: base, borderRadius: BorderRadius.circular(20)),
                ),
              ),
            ),
            // bottom three stacked row-cards (vertical)
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
                child: Column(
                  children: [
                    Expanded(
                      child: Container(decoration: BoxDecoration(color: base, borderRadius: BorderRadius.circular(14))),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: Container(decoration: BoxDecoration(color: base, borderRadius: BorderRadius.circular(14))),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: Container(decoration: BoxDecoration(color: base, borderRadius: BorderRadius.circular(14))),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAIMsgDialog() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text('AI analysis — quick note', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: Text(
            'The analysis shown is generated by an AI model and may be imprecise or incomplete. Use the results as guidance only — verify critical details (hazards, battery condition, serial numbers) before handling or disposing of items.',
            textAlign: TextAlign.left,
            style: TextStyle(color: Colors.black87),
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Future<void> _openMapsSearch(String query) async {
    final encoded = Uri.encodeComponent(query);
    final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$encoded');
    try {
      final launched = await launchUrl(url, mode: LaunchMode.externalApplication);
      if (!launched) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open maps.')));
      }
    } catch (e) {
      debugPrint('Maps launch failed: $e');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open maps.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Analysis', style: TextStyle(color: Colors.black87)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              if (_isAnalyzing) return;
              _saveLog();
            },
            icon: Icon(Icons.save, color: _isAnalyzing ? Colors.grey[400] : primary),
            tooltip: 'Save log',
          )
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _isAnalyzing
            ? _skeletonScreen(context)
            : SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // image (no shadow, no elevation) with AI alert overlay + category chip
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(File(widget.imagePath), fit: BoxFit.cover, height: 240, width: double.infinity),
                  ),
                  // AI alert top-left
                  Positioned(
                    top: 8,
                    left: 8,
                    child: GestureDetector(
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
                          builder: (_) => Padding(padding: const EdgeInsets.all(12), child: _buildAIMsgDialog()),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), shape: BoxShape.circle),
                        child: const Icon(Icons.info_outline, color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                  // category chip top-right inside image
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), borderRadius: BorderRadius.circular(20)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.category, size: 16, color: Colors.white),
                          const SizedBox(width: 6),
                          Text(_category, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // title (display-only)
            TextField(
              controller: _titleController,
              readOnly: true,
              decoration: InputDecoration(
                labelText: 'Title',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade200)),
              ),
              style: const TextStyle(color: Colors.black87),
            ),
            const SizedBox(height: 8),

            // description (display-only)
            TextField(
              controller: _descriptionController,
              readOnly: true,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Short description',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade200)),
              ),
              style: const TextStyle(color: Colors.black87),
            ),
            const SizedBox(height: 12),

            // quick metric tiles (white, no shadows)
            Row(children: [
              Expanded(
                child: _infoCard(icon: Icons.branding_watermark, label: 'Brand', value: _brand.isEmpty ? 'Unknown' : _brand, color: primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _infoCard(icon: Icons.developer_board, label: 'Model', value: _model.isEmpty ? 'Unknown' : _model, color: primary),
              ),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: _infoCard(icon: Icons.calendar_today, label: 'Year', value: _year.isEmpty ? '—' : _year, color: Colors.orange)),
              const SizedBox(width: 10),
              Expanded(child: _infoCard(icon: Icons.info_outline, label: 'Condition', value: _status, color: Colors.blue)),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                child: _infoCard(
                  icon: Icons.scale,
                  label: 'Weight (kg)',
                  value: _weightKg != null ? _weightKg!.toStringAsFixed(2) : 'Unknown',
                  color: Colors.purple,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(child: _infoCard(icon: Icons.category, label: 'Category', value: _category, color: Colors.teal)),
            ]),

            const SizedBox(height: 14),

            // components
            const Text('Key components', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 8),
            _chipList(_components),
            const SizedBox(height: 12),

            // hazards
            const Text('Hazards (inspect carefully)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 8),
            _chipList(_hazards),
            const SizedBox(height: 12),

            // material streams
            const Text('Material streams (estimated)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 8),
            _materialStreams.isEmpty
                ? Column(children: [
              const Text('No material breakdown provided.', style: TextStyle(color: Colors.black87)),
              const SizedBox(height: 8),
              _materialRow('Plastics', 40),
              _materialRow('Ferrous', 30),
              _materialRow('Non-ferrous', 20),
              _materialRow('PCB', 5),
              _materialRow('Hazardous', 5),
            ])
                : Column(
              children: _materialStreams.entries.map((e) => _materialRow(e.key, e.value)).toList(),
            ),

            const SizedBox(height: 12),

            // disposal path (display-only)
            const Text('Recommended disposal / recycling path', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade200)),
              child: Text(_disposalPath.isEmpty ? 'No specific path provided. Consider certified e-waste recycler or battery-specialist.' : _disposalPath,
                  style: const TextStyle(color: Colors.black87)),
            ),

            const SizedBox(height: 12),

            // Disposal suggestion cards (horizontal row - scrollable)
            const Text('Handling & disposal suggestions', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _disposalSuggestions(_category).map((s) {
                  return Container(
                    width: 260,
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade200)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.black87)),
                        const SizedBox(height: 8),
                        Text(s['body'] ?? '', style: const TextStyle(color: Colors.black87, fontSize: 13)),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 12),

            // Actionable maps cards row: brand service (if brand detected) + recycling centers
            const Text('Find nearby', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  if (_brand.isNotEmpty)
                    GestureDetector(
                      onTap: () => _openMapsSearch('$_brand service center near me'),
                      child: Container(
                        width: 260,
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade200)),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            CircleAvatar(backgroundColor: Colors.blue.withOpacity(0.08), child: const Icon(Icons.handyman, color: Colors.blue)),
                            const SizedBox(width: 10),
                            const Expanded(child: Text('Brand service centers', style: TextStyle(fontWeight: FontWeight.w700))),
                          ]),
                          const SizedBox(height: 10),
                          Text('Search for service & repair centers for $_brand near you.', style: const TextStyle(color: Colors.black87)),
                          const SizedBox(height: 10),
                          Align(
                            alignment: Alignment.bottomRight,
                            child: TextButton(onPressed: () => _openMapsSearch('$_brand service center near me'), child: const Text('Open in Maps')),
                          ),
                        ]),
                      ),
                    ),
                  // recycling card (always shown)
                  GestureDetector(
                    onTap: () => _openMapsSearch('e-waste recycling center near me'),
                    child: Container(
                      width: 260,
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade200)),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          CircleAvatar(backgroundColor: Colors.green.withOpacity(0.08), child: const Icon(Icons.recycling, color: Colors.green)),
                          const SizedBox(width: 10),
                          const Expanded(child: Text('Recycling centers', style: TextStyle(fontWeight: FontWeight.w700))),
                        ]),
                        const SizedBox(height: 10),
                        const Text('Find certified e-waste drop-off points and recycler services near you.', style: TextStyle(color: Colors.black87)),
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.bottomRight,
                          child: TextButton(onPressed: () => _openMapsSearch('e-waste recycling center near me'), child: const Text('Open in Maps')),
                        ),
                      ]),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _saveLog,
                    icon: const Icon(Icons.save),
                    label: const Text('Save & Log'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _requestPickup,
                    icon: const Icon(Icons.local_shipping),
                    label: const Text('Request Pickup'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      foregroundColor: primary,
                      side: BorderSide(color: primary),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),
          ]),
        ),
      ),
      // error overlay (when analysis failed) is kept but unobtrusive
      bottomSheet: (!_isAnalyzing && _error != null)
          ? Container(
        color: Colors.white.withOpacity(0.98),
        height: 160,
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 56),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                _error ?? '',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black87),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _analyze, child: const Text('Retry')),
          ]),
        ),
      )
          : null,
    );
  }

  // Small reusable info card widget (white background, no shadow)
  Widget _infoCard({required IconData icon, required String label, required String value, required Color color}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      child: Row(children: [
        CircleAvatar(backgroundColor: color.withOpacity(0.06), child: Icon(icon, color: color)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
            const SizedBox(height: 6),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.black87)),
          ]),
        ),
      ]),
    );
  }
}
