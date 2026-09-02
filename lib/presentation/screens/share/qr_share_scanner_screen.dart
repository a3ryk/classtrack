import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/ui/app_toast.dart';
import '../../../core/utils/uuid_generator.dart';
import '../../../data/database/app_database.dart';
import '../../../domain/entities/subject_entity.dart';
import '../../../domain/services/schedule_engine.dart';
import '../../providers/app_state_provider.dart';

class QrShareScannerScreen extends ConsumerStatefulWidget {
  final int initialTabIndex;

  const QrShareScannerScreen({
    super.key,
    this.initialTabIndex = 0,
  });

  @override
  ConsumerState<QrShareScannerScreen> createState() => _QrShareScannerScreenState();
}

class _QrShareScannerScreenState extends ConsumerState<QrShareScannerScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  MobileScannerController? _scannerController;
  final TextEditingController _pasteController = TextEditingController();

  bool _isTorchOn = false;
  bool _hasScanned = false;
  bool _isSharingQrImage = false;
  final GlobalKey _qrRepaintKey = GlobalKey();
  final Set<String> _excludedSubjectIds = {};

  String? _cachedPayload;
  int _lastDataHash = 0;

  Future<void> _shareQrImage(String semName, String payloadCode) async {
    if (_isSharingQrImage) return;
    setState(() => _isSharingQrImage = true);

    try {
      Uint8List? pngBytes;

      // 1. Capture high-res RepaintBoundary snapshot
      final boundary = _qrRepaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary != null) {
        final ui.Image image = await boundary.toImage(pixelRatio: 4.0);
        final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        pngBytes = byteData?.buffer.asUint8List();
      }

      // 2. Direct QrPainter fallback if boundary is not ready
      if (pngBytes == null) {
        final painter = QrPainter(
          data: payloadCode,
          version: QrVersions.auto,
          gapless: true,
          dataModuleStyle: const QrDataModuleStyle(
            dataModuleShape: QrDataModuleShape.square,
            color: Color(0xFF0F172A),
          ),
          eyeStyle: const QrEyeStyle(
            eyeShape: QrEyeShape.square,
            color: Color(0xFF0F172A),
          ),
        );
        final picData = await painter.toImageData(1000, format: ui.ImageByteFormat.png);
        pngBytes = picData?.buffer.asUint8List();
      }

      if (pngBytes != null) {
        final tempDir = await getTemporaryDirectory();
        final sanitizedName = semName.replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_');
        final file = File('${tempDir.path}/ClassTrack_${sanitizedName}_QR.png');
        await file.writeAsBytes(pngBytes);

        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(file.path)],
            text: 'ClassTrack Timetable for $semName',
          ),
        );
      } else {
        await SharePlus.instance.share(
          ShareParams(text: 'ClassTrack Timetable Code ($semName):\n\n$payloadCode'),
        );
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(context, 'Failed to generate QR image: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isSharingQrImage = false);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
    _tabController.addListener(_handleTabChanged);

    // Pre-calculate payload immediately in initState to prevent frame drops during route transition
    final activeSem = ref.read(activeSemesterProvider);
    final subjects = ref.read(subjectsProvider);
    final slots = ref.read(timetableSlotsProvider);
    _cachedPayload = _encodePayload(slots, subjects, activeSem.name);
    _lastDataHash = Object.hash(activeSem.name, subjects.length, slots.length, _excludedSubjectIds.length);

    if (widget.initialTabIndex == 1) {
      _initScanner();
    }
  }

  void _handleTabChanged() {
    if (_tabController.index == 1 && _scannerController == null) {
      _initScanner();
    }
    if (mounted) {
      setState(() {});
    }
  }

  void _initScanner() {
    _scannerController ??= MobileScannerController();
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChanged);
    _tabController.dispose();
    _scannerController?.dispose();
    _pasteController.dispose();
    super.dispose();
  }

  // ==========================================
  // COMPRESSION & PROTOCOL ENCODER / DECODER
  // ==========================================

  String _encodePayload(List<TimetableSlotItem> slots, List<SubjectEntity> subjects, String semName) {
    final activeSubjects = subjects.where((s) => !_excludedSubjectIds.contains(s.id)).toList();
    final activeSubIds = activeSubjects.map((s) => s.id).toSet();
    final activeSlots = slots.where((s) => activeSubIds.contains(s.subjectComponentId)).toList();

    final payloadMap = {
      'v': 2,
      'sem': semName,
      'subs': activeSubjects.map((s) => {
        'id': s.id,
        'name': s.name,
        'code': s.code,
        'cat': s.category,
        'col': s.colorHex,
      }).toList(),
      'slots': activeSlots.map((s) => {
        'subId': s.subjectComponentId,
        'day': s.dayOfWeek,
        'start': s.startTime,
        'end': s.endTime,
        'type': s.componentType,
        'room': s.room,
        'teacher': s.teacherName,
      }).toList(),
    };

    final jsonStr = jsonEncode(payloadMap);
    final bytes = utf8.encode(jsonStr);
    final compressed = gzip.encode(bytes);
    return 'CT2:${base64Url.encode(compressed)}';
  }

  Map<String, dynamic>? _decodePayload(String raw) {
    try {
      String code = raw.trim();
      if (code.startsWith('CT2:')) {
        code = code.substring(4);
        final compressed = base64Url.decode(code);
        final decompressed = gzip.decode(compressed);
        final jsonStr = utf8.decode(decompressed);
        return jsonDecode(jsonStr) as Map<String, dynamic>;
      }
      if (code.startsWith('CT1:')) {
        code = code.substring(4);
        final compressed = base64Url.decode(code);
        final decompressed = gzip.decode(compressed);
        final jsonStr = utf8.decode(decompressed);
        return jsonDecode(jsonStr) as Map<String, dynamic>;
      }
      return jsonDecode(code) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  void _onQrDetected(BarcodeCapture capture) {
    if (_hasScanned) return;
    for (final barcode in capture.barcodes) {
      if (barcode.rawValue != null) {
        _processScannedCode(barcode.rawValue!);
        break;
      }
    }
  }

  void _processScannedCode(String rawCode) {
    final data = _decodePayload(rawCode);
    if (data == null) {
      AppToast.error(context, 'Invalid ClassTrack timetable code');
      return;
    }

    _hasScanned = true;
    _showImportPreviewSheet(data);
  }

  Future<void> _pickImageAndScan() async {
    final result = await FilePicker.pickFiles(type: FileType.image);
    if (result != null && result.files.single.path != null) {
      final path = result.files.single.path!;
      _initScanner();
      final barcodeCapture = await _scannerController!.analyzeImage(path);
      if (barcodeCapture != null && barcodeCapture.barcodes.isNotEmpty) {
        final code = barcodeCapture.barcodes.first.rawValue;
        if (code != null) {
          _processScannedCode(code);
          return;
        }
      }
      if (mounted) {
        AppToast.error(context, 'No timetable QR code found in selected image');
      }
    }
  }

  void _showImportPreviewSheet(Map<String, dynamic> data) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final semName = data['sem'] as String? ?? 'Shared Semester';
    final rawSubs = (data['subs'] as List?) ?? [];
    final rawSlots = (data['slots'] as List?) ?? [];

    final Set<int> selectedSubIndices = List.generate(rawSubs.length, (i) => i).toSet();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.cardDark : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Import Timetable',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '$semName • ${rawSubs.length} Subjects • ${rawSlots.length} Slots',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 20),
                          onPressed: () {
                            Navigator.pop(ctx);
                            setState(() => _hasScanned = false);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    Text(
                      'SELECT SUBJECTS TO IMPORT:',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.6,
                        color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                      ),
                    ),
                    const SizedBox(height: 8),

                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 220),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: rawSubs.length,
                        separatorBuilder: (context, index) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final sub = rawSubs[index] as Map<String, dynamic>;
                          final name = sub['name'] as String? ?? 'Subject';
                          final code = sub['code'] as String?;
                          final cat = sub['cat'] as String? ?? 'MAJOR';
                          final isSelected = selectedSubIndices.contains(index);

                          return CheckboxListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            value: isSelected,
                            title: Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            subtitle: Text([if (code != null) code, cat].join(' • '), style: const TextStyle(fontSize: 11)),
                            activeColor: AppColors.presentGreen,
                            onChanged: (val) {
                              setSheetState(() {
                                if (val == true) {
                                  selectedSubIndices.add(index);
                                } else {
                                  selectedSubIndices.remove(index);
                                }
                              });
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                              foregroundColor: isDark ? AppColors.bgDark : Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () async {
                              Navigator.pop(ctx);
                              await _applyImport(data, selectedSubIndices);
                              setState(() => _hasScanned = false);
                            },
                            child: Text(
                              'Import (${selectedSubIndices.length} Subjects)',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).then((_) {
      if (mounted) setState(() => _hasScanned = false);
    });
  }

  Future<void> _applyImport(Map<String, dynamic> data, Set<int> selectedSubIndices) async {
    final activeSem = ref.read(activeSemesterProvider);
    if (activeSem.isUnset) {
      AppToast.error(context, 'Please create an active semester first');
      return;
    }

    final rawSubs = (data['subs'] as List?) ?? [];
    final rawSlots = (data['slots'] as List?) ?? [];

    final Map<String, String> subIdMapping = {}; // oldSubId -> newSubId
    final nowIso = DateTime.now().toIso8601String();

    for (int i = 0; i < rawSubs.length; i++) {
      if (!selectedSubIndices.contains(i)) continue;
      final s = rawSubs[i] as Map<String, dynamic>;
      final oldId = s['id'] as String? ?? 'sub_$i';
      final newId = UuidGenerator.generate();
      subIdMapping[oldId] = newId;

      final newSubject = SubjectEntity(
        id: newId,
        semesterId: activeSem.id,
        name: s['name'] as String? ?? 'Imported Subject',
        code: s['code'] as String?,
        category: s['cat'] as String? ?? 'MAJOR',
        credits: 3,
        targetAttendancePct: 75.0,
        baselineHeld: 0,
        baselineAttended: 0,
        isArchived: false,
        colorHex: s['col'] as String? ?? '#4F46E5',
        components: [],
      );

      await ref.read(subjectsProvider.notifier).addSubject(newSubject);
    }

    final List<TimetableSlotData> newSlots = [];
    for (final slot in rawSlots) {
      final sMap = slot as Map<String, dynamic>;
      final oldSubId = sMap['subId'] as String?;
      if (oldSubId == null || !subIdMapping.containsKey(oldSubId)) continue;

      newSlots.add(
        TimetableSlotData(
          id: UuidGenerator.generate(),
          semesterId: activeSem.id,
          subjectComponentId: subIdMapping[oldSubId]!,
          dayOfWeek: sMap['day'] as int? ?? 1,
          startTime: sMap['start'] as String? ?? '09:00',
          endTime: sMap['end'] as String? ?? '10:00',
          room: sMap['room'] as String?,
          teacherName: sMap['teacher'] as String?,
          notes: sMap['type'] as String? ?? 'LECTURE',
          createdAt: nowIso,
          updatedAt: nowIso,
        ),
      );
    }

    if (newSlots.isNotEmpty) {
      await ref.read(timetableSlotsProvider.notifier).addBatchSlots(newSlots);
    }

    // Dispatch phone notification
    await NotificationService.instance.showGeneralNotification(
      title: 'Timetable Imported',
      body: 'Imported ${subIdMapping.length} subjects and ${newSlots.length} weekly slots into your schedule.',
    );

    if (mounted) {
      AppToast.success(context, 'Successfully imported ${subIdMapping.length} subjects & ${newSlots.length} timetable slots!');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeSem = ref.watch(activeSemesterProvider);
    final subjects = ref.watch(subjectsProvider);
    final slots = ref.watch(timetableSlotsProvider);

    final currentHash = Object.hash(
      activeSem.name,
      subjects.length,
      slots.length,
      _excludedSubjectIds.length,
    );

    if (_cachedPayload == null || _lastDataHash != currentHash) {
      _lastDataHash = currentHash;
      _cachedPayload = _encodePayload(slots, subjects, activeSem.name);
    }
    final payloadCode = _cachedPayload!;

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.bgDark : const Color(0xFFF8FAFC),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, size: 22),
          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Share & Scan Timetable',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            letterSpacing: -0.3,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: isDark ? AppColors.accentIndigoDark : AppColors.accentIndigoLight,
          labelColor: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          unselectedLabelColor: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(icon: Icon(Icons.qr_code_2_rounded, size: 18), text: 'Share My Schedule'),
            Tab(icon: Icon(Icons.qr_code_scanner_rounded, size: 18), text: 'Scan Classmate'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        physics: const BouncingScrollPhysics(),
        children: [
          // TAB 1: SHARE SCHEDULE
          RepaintBoundary(
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                children: [
                  // Term Context Badges
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildPill('${subjects.length} Subjects', isDark),
                      const SizedBox(width: 8),
                      _buildPill('${slots.length} Weekly Slots', isDark),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // QR Card Container (Capturable Image Container)
                  RepaintBoundary(
                    key: _qrRepaintKey,
                    child: Container(
                      width: 240,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Semester Header Pill
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 3.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEEF2FF),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFFC7D2FE),
                                width: 0.8,
                              ),
                            ),
                            child: Text(
                              activeSem.name,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.accentIndigoLight,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // High-Density QR Image
                          SizedBox(
                            width: 180,
                            height: 180,
                            child: QrImageView(
                              data: payloadCode,
                              version: QrVersions.auto,
                              size: 180.0,
                              padding: EdgeInsets.zero,
                              gapless: true,
                              eyeStyle: const QrEyeStyle(
                                eyeShape: QrEyeShape.square,
                                color: Color(0xFF0F172A),
                              ),
                              dataModuleStyle: const QrDataModuleStyle(
                                dataModuleShape: QrDataModuleShape.square,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ),
                        const SizedBox(height: 14),

                        // ClassTrack App Name & Branding Below QR
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                color: AppColors.accentIndigoLight,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Center(
                                child: Icon(Icons.school_rounded, size: 11, color: Colors.white),
                              ),
                            ),
                            const SizedBox(width: 5),
                            const Text(
                              'ClassTrack',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                                letterSpacing: -0.3,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        const Text(
                          '100% Offline Timetable & Attendance',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Scan with any ClassTrack camera or photo scanner',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 14),

                // Quick Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.copy_rounded, size: 15),
                        label: const Text('Copy Code', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: payloadCode));
                          AppToast.success(context, 'Timetable share code copied to clipboard!');
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                          foregroundColor: isDark ? AppColors.bgDark : Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: _isSharingQrImage
                            ? const SizedBox(
                                width: 15,
                                height: 15,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.share_rounded, size: 15),
                        label: Text(
                          _isSharingQrImage ? 'Generating...' : 'Share QR Image',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        onPressed: _isSharingQrImage
                            ? null
                            : () => _shareQrImage(activeSem.name, payloadCode),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Privacy Guarantee Badge
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF064E3B).withValues(alpha: 0.2) : const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark ? const Color(0xFF059669).withValues(alpha: 0.3) : const Color(0xFF86EFAC),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.shield_rounded, size: 18, color: AppColors.presentGreen),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '100% Private: Only subjects and schedule times are shared. Your personal attendance and profile never leave your device.',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? const Color(0xFFA7F3D0) : const Color(0xFF166534),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // TAB 2: SCANNER & IMPORT CUSTOMIZER
          _scannerController != null
              ? Stack(
                  children: [
                    MobileScanner(
                      controller: _scannerController!,
                      onDetect: _onQrDetected,
                    ),

                    // Scanner Viewfinder Overlay
                    Center(
                      child: Container(
                        width: 250,
                        height: 250,
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.accentIndigoLight, width: 2.5),
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),

                    // Bottom Controls Bar
                    Positioned(
                      bottom: 24,
                      left: 20,
                      right: 20,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          FloatingActionButton.small(
                            heroTag: 'torch',
                            backgroundColor: Colors.black87,
                            foregroundColor: Colors.white,
                            onPressed: () {
                              setState(() => _isTorchOn = !_isTorchOn);
                              _scannerController?.toggleTorch();
                            },
                            child: Icon(_isTorchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded, size: 20),
                          ),
                          FloatingActionButton.extended(
                            heroTag: 'gallery',
                            backgroundColor: Colors.black87,
                            foregroundColor: Colors.white,
                            icon: const Icon(Icons.photo_library_rounded, size: 18),
                            label: const Text('Scan Image', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            onPressed: _pickImageAndScan,
                          ),
                          FloatingActionButton.small(
                            heroTag: 'paste',
                            backgroundColor: Colors.black87,
                            foregroundColor: Colors.white,
                            onPressed: () async {
                              final data = await Clipboard.getData('text/plain');
                              if (!context.mounted) return;
                              if (data != null && data.text != null) {
                                _processScannedCode(data.text!);
                              } else {
                                AppToast.info(context, 'Clipboard is empty');
                              }
                            },
                            child: const Icon(Icons.paste_rounded, size: 20),
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              : const Center(
                  child: CircularProgressIndicator(),
                ),
        ],
      ),
    );
  }

  Widget _buildPill(String text, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.pillDark : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
        ),
      ),
    );
  }
}
