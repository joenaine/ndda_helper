import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import 'package:universal_html/html.dart' as html;
import 'package:cross_file/cross_file.dart';
import 'package:path_provider/path_provider.dart';
import '../models/drug_model.dart';
import '../services/haptic_service.dart';
import '../services/knf_service.dart';
import '../services/alo_service.dart';
import '../services/ed_service.dart';
import '../services/mnn_price_service.dart';
import '../services/orphan_service.dart';
import '../models/knf_result.dart';

final paddingData = EdgeInsets.symmetric(horizontal: 4, vertical: 1);

class DrugCard extends StatefulWidget {
  final Drug drug;
  final bool isSelected;
  final VoidCallback onTap;

  const DrugCard({
    super.key,
    required this.drug,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<DrugCard> createState() => _DrugCardState();
}

class _DrugCardState extends State<DrugCard> {
  bool _isExpanded = false;
  final HapticService _hapticService = HapticService();
  final KnfService _knfService = KnfService();
  final AloService _aloService = AloService();
  final EdService _edService = EdService();
  final MnnPriceService _mnnPriceService = MnnPriceService();
  final OrphanService _orphanService = OrphanService();
  KnfCheckResult? _knfResult;
  bool _isCheckingKnf = false;
  bool? _isInAlo;
  bool _isCheckingAlo = false;
  bool? _isInEd;
  bool _isCheckingEd = false;
  String? _mnnPrice;
  bool _isCheckingPrice = false;
  bool? _isOrphan;
  bool _isCheckingOrphan = false;

  @override
  void initState() {
    super.initState();
    _checkKnfStatus();
    _checkAloStatus();
    _checkEdStatus();
    _checkMnnPrice();
    _checkOrphanStatus();
  }

  @override
  void didUpdateWidget(DrugCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If drug changed, re-check all statuses
    if (oldWidget.drug.id != widget.drug.id) {
      if (kDebugMode) {
        print(
          'DrugCard: Drug changed from ${oldWidget.drug.id} to ${widget.drug.id}, rechecking',
        );
      }
      _checkKnfStatus();
      _checkAloStatus();
      _checkEdStatus();
      _checkMnnPrice();
      _checkOrphanStatus();
    }
  }

  void _checkKnfStatus() {
    if (_isCheckingKnf) return;

    setState(() {
      _isCheckingKnf = true;
    });

    try {
      _knfService.loadKnfData(); // Now instant, no async needed!
      final result = _knfService.checkDrug(widget.drug);
      if (mounted) {
        setState(() {
          _knfResult = result;
          _isCheckingKnf = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _knfResult = null;
          _isCheckingKnf = false;
        });
      }
    }
  }

  void _checkAloStatus() {
    if (_isCheckingAlo) return;

    setState(() {
      _isCheckingAlo = true;
    });

    try {
      _aloService.loadAloData(); // Now instant, no async needed!
      final isInAlo = _aloService.isDrugInAlo(widget.drug);
      if (kDebugMode) {
        print(
          'DrugCard: ALO check for "${widget.drug.name}" (ID: ${widget.drug.id}): $isInAlo',
        );
      }
      if (mounted) {
        setState(() {
          _isInAlo = isInAlo;
          _isCheckingAlo = false;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('DrugCard: ALO check error for "${widget.drug.name}": $e');
      }
      if (mounted) {
        setState(() {
          _isInAlo = false;
          _isCheckingAlo = false;
        });
      }
    }
  }

  void _checkEdStatus() {
    if (_isCheckingEd) return;

    setState(() {
      _isCheckingEd = true;
    });

    try {
      _edService.loadEdData(); // Now instant, no async needed!
      final isInEd = _edService.isDrugInEd(widget.drug);
      if (mounted) {
        setState(() {
          _isInEd = isInEd;
          _isCheckingEd = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isInEd = false;
          _isCheckingEd = false;
        });
      }
    }
  }

  void _checkMnnPrice() {
    if (_isCheckingPrice) return;

    setState(() {
      _isCheckingPrice = true;
    });

    try {
      _mnnPriceService.loadMnnPriceData(); // Now instant, no async needed!
      final priceString = _mnnPriceService.getPriceStringForDrug(widget.drug);
      if (mounted) {
        setState(() {
          _mnnPrice = priceString;
          _isCheckingPrice = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _mnnPrice = null;
          _isCheckingPrice = false;
        });
      }
    }
  }

  void _checkOrphanStatus() {
    if (_isCheckingOrphan) return;

    setState(() {
      _isCheckingOrphan = true;
    });

    try {
      _orphanService.loadOrphanData(); // Now instant, no async needed!
      final isOrphan = _orphanService.isDrugOrphan(widget.drug);
      if (kDebugMode) {
        print(
          'DrugCard: ORPHAN check for "${widget.drug.name}" (ID: ${widget.drug.id}): $isOrphan',
        );
      }
      if (mounted) {
        setState(() {
          _isOrphan = isOrphan;
          _isCheckingOrphan = false;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('DrugCard: ORPHAN check error for "${widget.drug.name}": $e');
      }
      if (mounted) {
        setState(() {
          _isOrphan = false;
          _isCheckingOrphan = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: widget.isSelected ? Colors.black : Colors.white,
        border: Border.all(
          color: widget.isSelected ? Colors.black : const Color(0xFFE5E7EB),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(8),
                topRight: const Radius.circular(8),
                bottomLeft: _isExpanded
                    ? Radius.zero
                    : const Radius.circular(8),
                bottomRight: _isExpanded
                    ? Radius.zero
                    : const Radius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Checkbox
                    Container(
                      width: 20,
                      height: 20,
                      margin: const EdgeInsets.only(right: 16, top: 2),
                      decoration: BoxDecoration(
                        color: widget.isSelected
                            ? Colors.white
                            : Colors.transparent,
                        border: Border.all(
                          color: widget.isSelected
                              ? Colors.white
                              : const Color(0xFFE5E7EB),
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: widget.isSelected
                          ? const Icon(
                              Icons.check,
                              size: 14,
                              color: Colors.black,
                            )
                          : null,
                    ),

                    // Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Drug name with КНФ and АЛО indicators
                          Row(
                            children: [
                              Flexible(
                                child: GestureDetector(
                                  onTap: () =>
                                      _copyToClipboard(widget.drug.name),
                                  child: Text(
                                    widget.drug.name,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: widget.isSelected
                                          ? Colors.white
                                          : Colors.black,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ),
                              // КНФ indicators (strict + MNN)
                              if (_isCheckingKnf)
                                Padding(
                                  padding: const EdgeInsets.only(left: 8),
                                  child: SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        widget.isSelected
                                            ? Colors.white.withOpacity(0.7)
                                            : const Color(0xFF6B7280),
                                      ),
                                    ),
                                  ),
                                )
                              else if (_knfResult != null) ...[
                                // Strict КНФ badge
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () => _showInfoBottomSheet(
                                    'Казахстанский национальный формуляр (КНФ)',
                                    'Перечень лекарственных средств, рекомендованных для применения в Республике Казахстан на основе принципов доказательной медицины.',
                                    'Приказ Министра здравоохранения Республики Казахстан от 18 мая 2021 года № ҚР ДСМ-41 «Об утверждении Казахстанского национального формуляра лекарственных средств»',
                                    'https://adilet.zan.kz/rus/docs/V2100022782',
                                  ),
                                  child: Container(
                                    padding: paddingData,
                                    decoration: BoxDecoration(
                                      color: _knfResult!.strict.inKnf
                                          ? (widget.isSelected
                                                ? Colors.green.shade300
                                                : Colors.green)
                                          : (widget.isSelected
                                                ? Colors.red.shade300
                                                : Colors.red),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'КНФ',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: widget.isSelected
                                            ? Colors.black
                                            : Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                                // КНФ МНН badge (only if strict failed but MNN found)
                                if (!_knfResult!.strict.inKnf &&
                                    _knfResult!.mnn != null &&
                                    _knfResult!.mnn!.inKnfByMnn) ...[
                                  const SizedBox(width: 6),
                                  GestureDetector(
                                    onTap: () => _showInfoBottomSheet(
                                      'Казахстанский национальный формуляр (КНФ)',
                                      'Перечень лекарственных средств, рекомендованных для применения в Республике Казахстан. Данный препарат найден по МНН (дженерик присутствует в формуляре).',
                                      'Приказ Министра здравоохранения Республики Казахстан от 18 мая 2021 года № ҚР ДСМ-41 «Об утверждении Казахстанского национального формуляра лекарственных средств»',
                                      'https://adilet.zan.kz/rus/docs/V2100022782',
                                    ),
                                    child: Container(
                                      padding: paddingData,
                                      decoration: BoxDecoration(
                                        color: widget.isSelected
                                            ? Colors.green.shade300
                                            : Colors.green,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'КНФ МНН',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: widget.isSelected
                                              ? Colors.black
                                              : Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                              // АЛО indicator
                              if (_isCheckingAlo)
                                Padding(
                                  padding: const EdgeInsets.only(left: 8),
                                  child: SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        widget.isSelected
                                            ? Colors.white.withOpacity(0.7)
                                            : const Color(0xFF6B7280),
                                      ),
                                    ),
                                  ),
                                )
                              else if (_isInAlo != null) ...[
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () => _showInfoBottomSheet(
                                    'Перечень Амбулаторного лекарственного обеспечения (АЛО)',
                                    'Перечень лекарственных средств и медицинских изделий, отпускаемых отдельным категориям граждан с определенными заболеваниями (состояниями) в рамках амбулаторного лекарственного обеспечения.',
                                    'Приказ Министра здравоохранения Республики Казахстан от 5 августа 2021 года № ҚР ДСМ-75 «Об утверждении перечня лекарственных средств и медицинских изделий, отпускаемых отдельным категориям граждан с определенными заболеваниями (состояниями) в рамках амбулаторного лекарственного обеспечения»',
                                    'https://adilet.zan.kz/rus/docs/V2100023885',
                                  ),
                                  child: Container(
                                    padding: paddingData,
                                    decoration: BoxDecoration(
                                      color: _isInAlo == true
                                          ? (widget.isSelected
                                                ? Colors.green.shade300
                                                : Colors.green)
                                          : (widget.isSelected
                                                ? Colors.red.shade300
                                                : Colors.red),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'АЛО',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: widget.isSelected
                                            ? Colors.black
                                            : Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                              // ЕД indicator
                              if (_isCheckingEd)
                                Padding(
                                  padding: const EdgeInsets.only(left: 8),
                                  child: SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        widget.isSelected
                                            ? Colors.white.withOpacity(0.7)
                                            : const Color(0xFF6B7280),
                                      ),
                                    ),
                                  ),
                                )
                              else if (_isInEd != null) ...[
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () => _showInfoBottomSheet(
                                    'Перечень ЛС закупаемые единым дистрибьютором',
                                    'Перечень лекарственных средств и медицинских изделий, закупаемых у единого дистрибьютора для обеспечения системы здравоохранения.',
                                    'Приказ Министра здравоохранения Республики Казахстан от 20 августа 2021 года № ҚР ДСМ-88 «Об определении перечня лекарственных средств и медицинских изделий, закупаемых у единого дистрибьютора»',
                                    'https://adilet.zan.kz/rus/docs/V2100024078',
                                  ),
                                  child: Container(
                                    padding: paddingData,
                                    decoration: BoxDecoration(
                                      color: _isInEd == true
                                          ? (widget.isSelected
                                                ? Colors.green.shade300
                                                : Colors.green)
                                          : (widget.isSelected
                                                ? Colors.red.shade300
                                                : Colors.red),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'ЕД',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: widget.isSelected
                                            ? Colors.black
                                            : Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                              // ОРФАН indicator (only green, shown only if found)
                              if (_isCheckingOrphan)
                                Padding(
                                  padding: const EdgeInsets.only(left: 8),
                                  child: SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        widget.isSelected
                                            ? Colors.white.withOpacity(0.7)
                                            : const Color(0xFF6B7280),
                                      ),
                                    ),
                                  ),
                                )
                              else if (_isOrphan == true) ...[
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () => _showInfoBottomSheet(
                                    'Орфанные заболевания и перечень лекарственных средств',
                                    'Перечень орфанных заболеваний и лекарственных средств для их лечения. Орфанные (редкие) заболевания требуют специализированной терапии.',
                                    'Приказ Министра здравоохранения Республики Казахстан от 20 октября 2020 года № ҚР ДСМ-142/2020 «Об утверждении перечня орфанных заболеваний и лекарственных средств для их лечения (орфанных)»',
                                    'https://adilet.zan.kz/rus/docs/V2000021479',
                                  ),
                                  child: Container(
                                    padding: paddingData,
                                    decoration: BoxDecoration(
                                      color: widget.isSelected
                                          ? Colors.green.shade300
                                          : Colors.green,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'ОРФАН',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: widget.isSelected
                                            ? Colors.black
                                            : Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 8),

                          // ATC Info
                          if (widget.drug.atcName != null ||
                              widget.drug.code != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                children: [
                                  if (widget.drug.code != null) ...[
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: widget.isSelected
                                            ? Colors.white.withOpacity(0.2)
                                            : const Color(0xFFF9FAFB),
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(
                                          color: widget.isSelected
                                              ? Colors.white.withOpacity(0.3)
                                              : const Color(0xFFE5E7EB),
                                        ),
                                      ),
                                      child: GestureDetector(
                                        onTap: () =>
                                            _copyToClipboard(widget.drug.code!),
                                        child: Text(
                                          widget.drug.code!,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: widget.isSelected
                                                ? Colors.white
                                                : Colors.black,
                                            fontFamily: 'monospace',
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                  if (widget.drug.atcName != null)
                                    Flexible(
                                      child: GestureDetector(
                                        onTap: () => _copyToClipboard(
                                          widget.drug.atcName!,
                                        ),
                                        child: Text(
                                          widget.drug.atcName!,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: widget.isSelected
                                                ? Colors.white.withOpacity(0.9)
                                                : const Color(0xFF6B7280),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),

                          // Reg number and dosage form
                          Text(
                            '${widget.drug.regNumber}${widget.drug.dosageFormName != null ? ' • ${widget.drug.dosageFormName}' : ''}',
                            style: TextStyle(
                              fontSize: 13,
                              color: widget.isSelected
                                  ? Colors.white.withOpacity(0.8)
                                  : const Color(0xFF6B7280),
                            ),
                          ),
                          const SizedBox(height: 4),

                          // Producer and country
                          Align(
                            alignment: Alignment.centerLeft,
                            child: GestureDetector(
                              onTap: () => _copyToClipboard(
                                '${widget.drug.producerNameRu} • ${widget.drug.countryNameRu}',
                              ),
                              child: Text(
                                '${widget.drug.producerNameRu} • ${widget.drug.countryNameRu}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: widget.isSelected
                                      ? Colors.white.withOpacity(0.8)
                                      : const Color(0xFF6B7280),
                                ),
                              ),
                            ),
                          ),
                          // МНН Price (if available)
                          if (_mnnPrice != null && _mnnPrice!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            GestureDetector(
                              onTap: () => _showInfoBottomSheet(
                                'Предельные цены на МНН',
                                'Предельные цены на международное непатентованное наименование лекарственного средства в рамках гарантированного объема бесплатной медицинской помощи и (или) в системе обязательного социального медицинского страхования.',
                                'Приказ Министра здравоохранения Республики Казахстан от 4 сентября 2021 года № ҚР ДСМ-96 «Об утверждении предельных цен на международное непатентованное наименование лекарственного средства или техническую характеристику медицинского изделия в рамках гарантированного объема бесплатной медицинской помощи и (или) в системе обязательного социального медицинского страхования»',
                                'https://adilet.zan.kz/rus/docs/V2100024253',
                              ),
                              child: Container(
                                padding: paddingData,
                                decoration: BoxDecoration(
                                  color: widget.isSelected
                                      ? Colors.white.withOpacity(0.15)
                                      : const Color(0xFFF0F9FF),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: widget.isSelected
                                        ? Colors.white.withOpacity(0.3)
                                        : const Color(0xFF3B82F6),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Предельная цена: ',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: widget.isSelected
                                            ? Colors.white.withOpacity(0.9)
                                            : const Color(0xFF1E40AF),
                                      ),
                                    ),
                                    Text(
                                      '$_mnnPrice ₸',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: widget.isSelected
                                            ? Colors.white
                                            : const Color(0xFF1E40AF),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Expand button and Download button
                    const SizedBox(width: 8),
                    Column(
                      children: [
                        InkWell(
                          onTap: () {
                            _hapticService.selectionClick();
                            setState(() {
                              _isExpanded = !_isExpanded;
                            });
                          },
                          borderRadius: BorderRadius.circular(4),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              _isExpanded
                                  ? Icons.keyboard_arrow_up
                                  : Icons.keyboard_arrow_down,
                              size: 20,
                              color: widget.isSelected
                                  ? Colors.white.withOpacity(0.8)
                                  : const Color(0xFF6B7280),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        InkWell(
                          onTap: () {
                            _hapticService.mediumImpact();
                            _openOhlpLink();
                          },
                          borderRadius: BorderRadius.circular(4),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              Icons.download,
                              size: 18,
                              color: widget.isSelected
                                  ? Colors.white.withOpacity(0.8)
                                  : const Color(0xFF6B7280),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Expanded details section
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Container(
              padding: const EdgeInsets.fromLTRB(52, 0, 16, 16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: widget.isSelected
                        ? Colors.white.withOpacity(0.2)
                        : const Color(0xFFE5E7EB),
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    'Registration Action',
                    widget.drug.regActions,
                  ),
                  _buildDetailRow('Drug Type', widget.drug.drugTypesName),
                  if (widget.drug.regDate.isNotEmpty)
                    _buildDetailRow(
                      'Registration Date',
                      widget.drug.regDate.split('T').first,
                    ),
                  if (widget.drug.expirationDate.isNotEmpty)
                    _buildDetailRow(
                      'Expiration Date',
                      widget.drug.expirationDate.split('T').first,
                    ),
                  _buildDetailRow('Term', '${widget.drug.regTerm} years'),
                  if (widget.drug.ndNumber != null)
                    _buildDetailRow('ND Number', widget.drug.ndNumber!),
                  if (widget.drug.storageTerm != null)
                    _buildDetailRow(
                      'Storage Term',
                      '${widget.drug.storageTerm} ${widget.drug.storageMeasureName ?? ''}',
                    ),
                  _buildDetailRow(
                    'Producer (ENG)',
                    widget.drug.producerNameEng,
                  ),
                  const SizedBox(height: 8),
                  // Flags
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      if (widget.drug.genericSign) _buildBadge('Generic'),
                      if (widget.drug.gmpSign) _buildBadge('GMP'),
                      if (widget.drug.recipeSign)
                        _buildBadge('Recipe Required'),
                      if (widget.drug.patentSign) _buildBadge('Patent'),
                      if (widget.drug.trademarkSign) _buildBadge('Trademark'),
                    ],
                  ),
                ],
              ),
            ),
            crossFadeState: _isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }

  Future<void> _copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    _hapticService.lightImpact();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Copied to clipboard'),
          backgroundColor: Colors.black,
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  void _showInfoBottomSheet(
    String title,
    String description,
    String orderInfo,
    String url,
  ) {
    _hapticService.selectionClick();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Text(
                        orderInfo,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black87,
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () async {
                        await Clipboard.setData(ClipboardData(text: url));
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Ссылка скопирована'),
                              backgroundColor: Colors.black,
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.link,
                              color: Colors.blue.shade700,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                url,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue.shade700,
                                  decoration: TextDecoration.underline,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.copy,
                              color: Colors.blue.shade700,
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Закрыть'),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openOhlpLink() async {
    final urlString =
        'https://register.ndda.kz/register-backend/RegisterService/GetRegisterOhlpFile?registerId=${widget.drug.id}&lang=ru';

    if (kIsWeb) {
      // Web platform - open in new tab
      html.window.open(urlString, '_blank');
    } else {
      // Mobile platform - download and share the file
      try {
        if (mounted) {
          // Show loading indicator
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SizedBox(width: 12),
                  Text('Downloading file...'),
                ],
              ),
              backgroundColor: Colors.black,
              duration: Duration(seconds: 2),
            ),
          );
        }

        // Download the file
        final response = await http.get(Uri.parse(urlString));

        if (response.statusCode == 200) {
          // Get the filename from URL or use a default
          final uri = Uri.parse(urlString);
          final fileName = uri.pathSegments.isNotEmpty
              ? uri.pathSegments.last
              : 'ohlp_${widget.drug.id}.zip';
          final finalFileName = fileName.contains('.')
              ? fileName
              : '$fileName.zip';

          // Write to temporary directory first for iOS compatibility
          try {
            final tempDir = await getTemporaryDirectory();
            final file = File('${tempDir.path}/$finalFileName');

            // Write bytes to file
            await file.writeAsBytes(response.bodyBytes);

            // Verify file exists before sharing
            if (await file.exists()) {
              final xFile = XFile(
                file.path,
                mimeType: 'application/zip',
                name: finalFileName,
              );

              // Get share position origin for iOS (required for iPad)
              Rect? sharePositionOrigin;
              if (mounted && !kIsWeb) {
                try {
                  final size = MediaQuery.of(context).size;
                  // Use center position
                  // Ensure the rect is within screen bounds and non-zero
                  const width = 100.0;
                  const height = 100.0;
                  final x = (size.width / 2 - width / 2).clamp(
                    0.0,
                    size.width - width,
                  );
                  final y = (size.height / 2 - height / 2).clamp(
                    0.0,
                    size.height - height,
                  );
                  if (x >= 0 &&
                      y >= 0 &&
                      width > 0 &&
                      height > 0 &&
                      x + width <= size.width &&
                      y + height <= size.height) {
                    sharePositionOrigin = Rect.fromLTWH(x, y, width, height);
                  }
                } catch (_) {
                  // If MediaQuery fails, use null (will use default)
                }
              }

              // Share the file so user can save/view it
              await Share.shareXFiles(
                [xFile],
                subject: 'OHLP File - ${widget.drug.name}',
                text: 'OHLP document for ${widget.drug.name}',
                sharePositionOrigin: sharePositionOrigin,
              );
            } else {
              throw Exception('File was not created successfully');
            }
          } catch (fileError) {
            // Fallback: try Documents directory
            try {
              final directory = await getApplicationDocumentsDirectory();
              final file = File('${directory.path}/$finalFileName');
              await file.writeAsBytes(response.bodyBytes);

              if (await file.exists()) {
                final xFile = XFile(
                  file.path,
                  mimeType: 'application/zip',
                  name: finalFileName,
                );

                // Get share position origin for iOS (required for iPad)
                Rect? sharePositionOrigin;
                if (mounted && !kIsWeb) {
                  final box = context.findRenderObject() as RenderBox?;
                  if (box != null && box.hasSize) {
                    final size = MediaQuery.of(context).size;
                    // Use center position
                    sharePositionOrigin = Rect.fromLTWH(
                      size.width / 2 - 50,
                      size.height / 2 - 50,
                      100,
                      100,
                    );
                  }
                }

                await Share.shareXFiles(
                  [xFile],
                  subject: 'OHLP File - ${widget.drug.name}',
                  text: 'OHLP document for ${widget.drug.name}',
                  sharePositionOrigin: sharePositionOrigin,
                );
              } else {
                throw Exception('File was not created successfully');
              }
            } catch (e2) {
              // Re-throw to be caught by outer catch block
              throw fileError;
            }
          }

          if (mounted) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('File ready to save'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Failed to download file: ${response.statusCode}',
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        // Show error to user
        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error downloading file: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: GestureDetector(
              onTap: () => _copyToClipboard(label),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: widget.isSelected
                      ? Colors.white.withOpacity(0.7)
                      : const Color(0xFF6B7280),
                ),
              ),
            ),
          ),
          Flexible(
            child: GestureDetector(
              onTap: () => _copyToClipboard(value),
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 12,
                  color: widget.isSelected
                      ? Colors.white.withOpacity(0.9)
                      : Colors.black,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: widget.isSelected
            ? Colors.white.withOpacity(0.2)
            : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: widget.isSelected
              ? Colors.white.withOpacity(0.3)
              : const Color(0xFFE5E7EB),
        ),
      ),
      child: GestureDetector(
        onTap: () => _copyToClipboard(label),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: widget.isSelected ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }
}
