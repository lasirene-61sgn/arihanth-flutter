import 'package:arianth/app_color/app_color.dart';
import 'package:arianth/screens/live_stock_order/riverpod/live_stock_order_notifier.dart';
import 'package:arianth/screens/live_stock_order/widgets/stock_order_item_row.dart';
import 'package:arianth/services/widget/custom_msg.dart';
import 'package:arianth/services/widget/form_field_common_button.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:arianth/services/image_picker/image_picker_helper.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:arianth/screens/buyer/riverpod/buyer_notifier.dart';
import 'package:arianth/screens/buyer/model/buyer_model.dart';
import 'package:arianth/screens/work_orders/ui/widgets/work_order_dropdown_widget.dart';
import 'package:arianth/services/widget/full_screen_image_viewer.dart';

class LiveStockOrderForm extends ConsumerStatefulWidget {
  final String? stockOrderId;

  const LiveStockOrderForm({super.key, this.stockOrderId});

  @override
  ConsumerState<LiveStockOrderForm> createState() => _LiveStockOrderFormState();
}

class _LiveStockOrderFormState extends ConsumerState<LiveStockOrderForm> {
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _scannerController = TextEditingController();
  // Re-introducing controller with optimized settings for stability
  final MobileScannerController _scannerController2 = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  final AudioPlayer _audioPlayer = AudioPlayer();
  int? _selectedBuyerId;
  bool _hasCameraPermission = false;
  bool _isScanSuccess = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(liveStockOrderNotifierProvider.notifier).clearScannedItems();
      ref.read(buyerListProvider.notifier).fetchBuyers();
      _checkPermission();
    });
    _initAudio();
  }

  void _initAudio() async {
    // Set up audio context for iOS to avoid conflicts with other audio (like Agora)
    await AudioPlayer.global.setAudioContext(AudioContext(
      iOS: AudioContextIOS(
        category: AVAudioSessionCategory.playback, // Works even in silent mode
        options: {
          AVAudioSessionOptions.duckOthers,
        },
      ),
      android: const AudioContextAndroid(
        isSpeakerphoneOn: false,
        stayAwake: false,
        contentType: AndroidContentType.music,
        usageType: AndroidUsageType.media,
        audioFocus: AndroidAudioFocus.gain,
      ),
    ));
    await _audioPlayer.setSource(AssetSource('image/mixkit-shop-scanner-beeps-1073.wav'));
  }

  @override
  void dispose() {
    _noteController.dispose();
    _scannerController.dispose();
    _scannerController2.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _recalcTotalWeight(int itemIndex) {
    final notifier = ref.read(liveStockOrderNotifierProvider.notifier);
    final state = ref.read(liveStockOrderNotifierProvider);
    final items = List<Map<String, dynamic>>.from(state.scannedItems);
    final item = items[itemIndex];
    double grandTotal = 0.0;

    for (final subItem in item['subItems']) {
      final g = double.tryParse(subItem['gramsCtrl']?.toString() ?? '0') ?? 0;
      final q = int.tryParse(subItem['qtyCtrl']?.toString() ?? '0') ?? 0;
      final subTotal = g * q;
      subItem['totalWeightCtrl'] = subTotal.toStringAsFixed(2);
      grandTotal += subTotal;
    }
    item['totalWeightCtrl'] = grandTotal.toStringAsFixed(2);
    notifier.updateScannedItems(items);
  }

  void _handleAddSubItem(int itemIndex) {
    final notifier = ref.read(liveStockOrderNotifierProvider.notifier);
    final state = ref.read(liveStockOrderNotifierProvider);
    final items = List<Map<String, dynamic>>.from(state.scannedItems);
    
    if (itemIndex < 0 || itemIndex >= items.length) return;
    
    final item = items[itemIndex];
    item['subItems'].add({
      'gramsCtrl': '',
      'qtyCtrl': '',
      'totalWeightCtrl': '0.00',
    });
    
    notifier.updateScannedItems(items);
  }

  void _handleRemoveSubItem(int itemIndex, int subIndex) {
    final notifier = ref.read(liveStockOrderNotifierProvider.notifier);
    final state = ref.read(liveStockOrderNotifierProvider);
    final items = List<Map<String, dynamic>>.from(state.scannedItems);
    
    if (itemIndex < 0 || itemIndex >= items.length) return;
    
    final item = items[itemIndex];
    if (subIndex < 0 || subIndex >= item['subItems'].length) return;
    
    item['subItems'].removeAt(subIndex);
    notifier.updateScannedItems(items);
    _recalcTotalWeight(itemIndex);
  }

  void _handleRemoveMainItem(int index) {
    final notifier = ref.read(liveStockOrderNotifierProvider.notifier);
    final state = ref.read(liveStockOrderNotifierProvider);
    final items = List<Map<String, dynamic>>.from(state.scannedItems);
    
    items.removeAt(index);
    notifier.updateScannedItems(items);
  }




  Future<void> _checkPermission() async {
    final status = await Permission.camera.status;
    setState(() {
      _hasCameraPermission = status.isGranted;
    });
  }

  Future<void> _requestPermission() async {
    final status = await Permission.camera.request();
    setState(() {
      _hasCameraPermission = status.isGranted;
    });
    
    // Removed automatic redirect to settings to comply with App Store Guidelines.
    if (status.isPermanentlyDenied) {
      Toaster.showError("Camera permission is required. Please enable it in Settings.");
    }
  }

  Future<void> _onScannerSubmitted(String code) async {
    if (code.trim().isEmpty) return;
    
    final state = ref.read(liveStockOrderNotifierProvider);
    if (state.isLoading) return;

    String extractedCode = code.trim();
    if (extractedCode.startsWith('http://') || extractedCode.startsWith('https://')) {
      try {
        final uri = Uri.parse(extractedCode);
        if (uri.pathSegments.isNotEmpty) {
          extractedCode = uri.pathSegments.last;
          _scannerController.text = extractedCode;
        }
      } catch (_) {}
    }
    
    final success = await ref.read(liveStockOrderNotifierProvider.notifier).fetchItemByCode(extractedCode);
    if (success) {
      _scannerController.clear();
      _playScanSound();
      _triggerSuccessAnimation();
      Toaster.showSuccess("Item added successfully");
    } else {
      final error = ref.read(liveStockOrderNotifierProvider).error;
      Toaster.showError(error ?? "Item not found");
    }
  }

  void _playScanSound() async {
    try {
      HapticFeedback.lightImpact();
      // Play and then stop after a short delay to make it a "quick" beep
      await _audioPlayer.play(AssetSource('image/mixkit-shop-scanner-beeps-1073.wav'), volume: 1.0);
      Future.delayed(const Duration(milliseconds: 200), () {
        _audioPlayer.stop();
      });
    } catch (e) {
      debugPrint("Error playing sound: $e");
    }
  }

  void _triggerSuccessAnimation() {
    setState(() => _isScanSuccess = true);
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() => _isScanSuccess = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    final state = ref.watch(liveStockOrderNotifierProvider);
    final buyerState = ref.watch(buyerListProvider);

    return Scaffold(
      backgroundColor: AppColor.background,
      appBar: AppBar(
        title: Text(
          widget.stockOrderId != null ? 'Edit Stock Order' : 'Create Stock Order',
          style: const TextStyle(color: AppColor.textWhite),
        ),
        backgroundColor: AppColor.appBarBackground,
        foregroundColor: AppColor.textWhite,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColor.textWhite, size: 20),
          onPressed: () => Get.back(),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                _buildTopFields(isMobile, buyerState),
                const SizedBox(height: 16),
                _buildScannerField(),
                const SizedBox(height: 16),
                
                if (state.scannedItems.isEmpty && !state.isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Text(
                      "Scan or enter a code to add items",
                      style: TextStyle(color: AppColor.textHint, fontSize: 16),
                    ),
                  ),

                ...state.scannedItems.asMap().entries.map((e) {
                  final index = e.key;
                  final itemData = e.value;
                  
                  // Convert generic map properties to text controllers for the row component 
                  // Since StockOrderItemRow expects controllers, we'll wrap the string values on the fly
                  // Alternatively, we store controllers in the state map.
                  final displayItemData = _prepareItemDataForView(itemData, index);

                  return StockOrderItemRow(
                    index: index,
                    itemData: displayItemData,
                    isMobile: isMobile,
                    imageWidget: _buildImagePickerWidget(index, displayItemData),
                    onAddSubItem: () => _handleAddSubItem(index),
                    onRemoveSubItem: (subIdx) => _handleRemoveSubItem(index, subIdx),
                    onRemoveMainItem: () => _handleRemoveMainItem(index),
                    onRecalc: () => _recalcTotalWeight(index),
                  );
                }).toList(),
                
                const SizedBox(height: 16),
               if(state.scannedItems.isNotEmpty) SafeArea(bottom: true, child: _buildFooterButtons(state)),
              ],
            ),
          ),
          if (state.isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  // Wraps simple state string values in TextEditingControllers for the UI to use
  Map<String, dynamic> _prepareItemDataForView(Map<String, dynamic> itemData, int index) {
    // We bind the controllers' listeners to update our state map if they change
    final notesCtrl = TextEditingController(text: itemData['notesCtrl']);
    notesCtrl.addListener(() => itemData['notesCtrl'] = notesCtrl.text);

    final sizeCtrl = TextEditingController(text: itemData['sizeCtrl']);
    sizeCtrl.addListener(() => itemData['sizeCtrl'] = sizeCtrl.text);

    final totalWeightCtrl = TextEditingController(text: itemData['totalWeightCtrl']);
    // totalWeightCtrl is read-only usually, so no need for listener

    final List<Map<String, dynamic>> subItems = [];
    for (int i = 0; i < (itemData['subItems'] as List).length; i++) {
      final sub = itemData['subItems'][i];
      
      final gramsCtrl = TextEditingController(text: sub['gramsCtrl']);
      gramsCtrl.addListener(() => sub['gramsCtrl'] = gramsCtrl.text);
      
      final qtyCtrl = TextEditingController(text: sub['qtyCtrl']);
      qtyCtrl.addListener(() => sub['qtyCtrl'] = qtyCtrl.text);
      
      final subTotalWeightCtrl = TextEditingController(text: sub['totalWeightCtrl']);
      
      subItems.add({
        'gramsCtrl': gramsCtrl,
        'qtyCtrl': qtyCtrl,
        'totalWeightCtrl': subTotalWeightCtrl,
      });
    }

    return {
      ...itemData,
      'notesCtrl': notesCtrl,
      'sizeCtrl': sizeCtrl,
      'totalWeightCtrl': totalWeightCtrl,
      'subItems': subItems,
    };
  }

  Widget _buildTopFields(bool isMobile, BuyerState buyerState) {
    final labelStyle = const TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.bold,
      color: AppColor.textPrimary,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColor.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColor.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isMobile) ...[
            _labelWithWidget("", _buildBuyerDropdown(buyerState), labelStyle),
            const SizedBox(height: 12),
            _labelWithWidget("General Notes", _buildGeneralNoteField(), labelStyle),
          ] else ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _labelWithWidget("Buyer", _buildBuyerDropdown(buyerState), labelStyle)),
                const SizedBox(width: 16),
                Expanded(flex: 2, child: _labelWithWidget("General Notes", _buildGeneralNoteField(), labelStyle)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _labelWithWidget(String label, Widget widget, TextStyle style) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: style),
        const SizedBox(height: 6),
        widget,
      ],
    );
  }

  Widget _buildBuyerDropdown(BuyerState buyerState) {
    Buyer? selectedModel;
    if (_selectedBuyerId != null) {
      selectedModel = buyerState.buyers.firstWhere(
        (b) => b.id == _selectedBuyerId,
      );
      if (selectedModel.id == -1) selectedModel = null;
    }

    return WorkOrderDropdownWidget<Buyer>(
      label: 'Buyer',
      fieldKeyName: 'buyer_id',
      items: buyerState.buyers,
      itemLabel: (bp) => "${bp.bpCode ?? ''} - ${bp.businessName ?? bp.name ?? ''}",
      selectedItemLabel: (bp) => "${bp.bpCode ?? ''} - ${bp.businessName ?? bp.name ?? ''}",
      value: selectedModel,
      isSearchable: true,
      hintText: 'Select Buyer',
      isLoading: buyerState.isLoading,
      onChanged: (Buyer? selectedBuyer) {
        if (selectedBuyer == null) return;
        setState(() {
          _selectedBuyerId = selectedBuyer.id;
        });
      },
    );
  }

  Widget _buildGeneralNoteField() {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: AppColor.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColor.divider),
      ),
      child: TextField(
        controller: _noteController,
        style: const TextStyle(fontSize: 13, color: AppColor.textPrimary),
        decoration: const InputDecoration(
          hintText: 'Enter internal notes...',
          hintStyle: TextStyle(color: AppColor.textHint),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildScannerField() {
    return Column(
      children: [
        const SizedBox(height: 8),
        Container(
          height: 300,
          width: double.infinity,
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: AppColor.black,
            borderRadius: BorderRadius.circular(12),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: _hasCameraPermission 
              ? Stack(
                  children: [
                    MobileScanner(
                      controller: _scannerController2,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error) {
                        debugPrint("MOBILE SCANNER ERROR: ${error.errorCode}");
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.error_outline, color: Colors.red, size: 48),
                              const SizedBox(height: 12),
                              Text(
                                "Scanner Error: ${error.errorCode.name}",
                                style: const TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        );
                      },
                      onDetect: (capture) {
                        final List<Barcode> barcodes = capture.barcodes;
                        for (final barcode in barcodes) {
                          if (barcode.rawValue != null) {
                             final code = barcode.rawValue!;
                             if (code.isNotEmpty) {
                               _scannerController.text = code;
                               _onScannerSubmitted(code);
                             }
                          }
                        }
                      },
                    ),
                    ScannerOverlay(color: _isScanSuccess ? Colors.green : Colors.white),
                  ],
                )
              : _buildPermissionDeniedUI(),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: AppColor.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColor.primary),
            boxShadow: [
              BoxShadow(
                color: AppColor.primary.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _scannerController,
                  onSubmitted: _onScannerSubmitted,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColor.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Enter Code...',
                    hintStyle: const TextStyle(color: AppColor.textHint, fontWeight: FontWeight.normal),
                    prefixIcon: const Icon(Icons.qr_code, color: AppColor.primary, size: 24),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.search, color: AppColor.primary, size: 28),
                onPressed: () => _onScannerSubmitted(_scannerController.text),
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPermissionDeniedUI() {
    return Container(
      width: double.infinity,
      color: AppColor.surface,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.camera_alt_outlined, size: 48, color: AppColor.textHint),
          const SizedBox(height: 12),
          const Text(
            "Camera permission is required",
            style: TextStyle(color: AppColor.textSecondary, fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            "to scan item codes",
            style: TextStyle(color: AppColor.textHint, fontSize: 12),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 36,
            child: ElevatedButton(
              onPressed: _requestPermission,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColor.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 24),
              ),
              child: const Text("Continue", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePickerWidget(int index, Map<String, dynamic> itemData) {
    final serverImage = itemData['serverImage'] as String?;

    return GestureDetector(
      onTap: (serverImage != null && serverImage.isNotEmpty)
          ? () => FullScreenImageViewer.show(context, serverImage)
          : null,
      child: Container(
        height: 85,
        width: 85,
        decoration: BoxDecoration(
          border: Border.all(color: AppColor.divider),
          borderRadius: BorderRadius.circular(8),
          color: AppColor.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: serverImage != null && serverImage.isNotEmpty
              ? Stack(
                  alignment: Alignment.center,
                  children: [
                    Image.network(
                      serverImage,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      errorBuilder: (c, e, s) => const Icon(Icons.broken_image, color: Colors.grey, size: 20),
                    ),
                    Positioned(
                      bottom: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.fullscreen, color: Colors.white, size: 14),
                      ),
                    ),
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.image_not_supported_outlined, color: AppColor.textHint, size: 24),
                    SizedBox(height: 4),
                    Text('No Image', style: TextStyle(fontSize: 10, color: AppColor.textSecondary)),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildFooterButtons(LiveStockOrderState state) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        FormFeildCommonButton(
          text: state.isSavingOrder ? 'Saving...' : (widget.stockOrderId == null ? "Create Order" : "Update Order"),
          textColor: AppColor.textWhite,
          backgroundColor: AppColor.primary,
          onPressed: state.isSavingOrder ? null : _handleCreate,
        ),
      ],
    );
  }

  Future<void> _handleCreate() async {
    final state = ref.read(liveStockOrderNotifierProvider);
    if (state.scannedItems.isEmpty) {
      Toaster.showError('Please add at least one item.');
      return;
    }

    if (_selectedBuyerId == null) {
      Toaster.showError('Please select a Buyer.');
      return;
    }

    final List<Map<String, dynamic>> finalItems = [];
    
    for (final item in state.scannedItems) {
      for (final sub in item['subItems']) {
        final g = sub['gramsCtrl']?.toString() ?? '';
        final q = sub['qtyCtrl']?.toString() ?? '';
        if (g.isNotEmpty && q.isNotEmpty) {
          final double gramsVal = double.tryParse(g) ?? 0.0;
          final int qtyVal = int.tryParse(q) ?? 0;
          
          finalItems.add({
            "product_id": item['productId'],
            "design_code": item['designCode'],
            "item_notes": item['notesCtrl'],
            "grams": gramsVal,
            "quantity": qtyVal,
            "total": gramsVal * qtyVal,
            "size": item['sizeCtrl'],
          });
        }
      }
    }

    final Map<String, dynamic> payload = {
      "buyer_id": _selectedBuyerId,
      "notes": _noteController.text,
      "items": finalItems,
    };

    final notifier = ref.read(liveStockOrderNotifierProvider.notifier);
    await notifier.createStockOrder(
      context: context,
      payload: payload,
      id: widget.stockOrderId,
      files: {},
    );
  }
}

class ScannerOverlay extends StatelessWidget {
  final Color color;
  const ScannerOverlay({super.key, this.color = Colors.white});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Dark overlay with transparent hole using CustomPainter
        Positioned.fill(
          child: CustomPaint(
            painter: ScannerHolePainter(),
          ),
        ),
        // Corner Brackets
        Center(
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.transparent),
            ),
            child: CustomPaint(
              painter: CornerBracketPainter(color: color),
            ),
          ),
        ),
      ],
    );
  }
}

class ScannerHolePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    final holeRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: 200,
      height: 200,
    );

    // Draw the background with a hole
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
        Path()
          ..addRRect(RRect.fromRectAndRadius(holeRect, const Radius.circular(16)))
          ..close(),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class CornerBracketPainter extends CustomPainter {
  final Color color;
  CornerBracketPainter({this.color = Colors.white});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    const length = 25.0;
    const radius = 12.0;

    // Top Left
    final path1 = Path()
      ..moveTo(0, length)
      ..lineTo(0, radius)
      ..arcToPoint(const Offset(radius, 0), radius: const Radius.circular(radius))
      ..lineTo(length, 0);
    canvas.drawPath(path1, paint);

    // Top Right
    final path2 = Path()
      ..moveTo(size.width - length, 0)
      ..lineTo(size.width - radius, 0)
      ..arcToPoint(Offset(size.width, radius), radius: const Radius.circular(radius))
      ..lineTo(size.width, length);
    canvas.drawPath(path2, paint);

    // Bottom Left
    final path3 = Path()
      ..moveTo(0, size.height - length)
      ..lineTo(0, size.height - radius)
      ..arcToPoint(Offset(radius, size.height), radius: const Radius.circular(radius))
      ..lineTo(length, size.height);
    canvas.drawPath(path3, paint);

    // Bottom Right
    final path4 = Path()
      ..moveTo(size.width - length, size.height)
      ..lineTo(size.width - radius, size.height)
      ..arcToPoint(Offset(size.width, size.height - radius), radius: const Radius.circular(radius))
      ..lineTo(size.width, size.height - length);
    canvas.drawPath(path4, paint);
  }

  @override
  bool shouldRepaint(covariant CornerBracketPainter oldDelegate) => oldDelegate.color != color;
}
