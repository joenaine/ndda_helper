import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import 'package:universal_html/html.dart' as html;
import '../models/drug_model.dart';
import '../services/haptic_service.dart';

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
                          // Drug name
                          SelectableText(
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
                                      child: SelectableText(
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
                                    const SizedBox(width: 8),
                                  ],
                                  if (widget.drug.atcName != null)
                                    Expanded(
                                      child: SelectableText(
                                        widget.drug.atcName!,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: widget.isSelected
                                              ? Colors.white.withOpacity(0.9)
                                              : const Color(0xFF6B7280),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),

                          // Reg number and dosage form
                          SelectableText(
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
                          SelectableText(
                            '${widget.drug.producerNameRu} • ${widget.drug.countryNameRu}',
                            style: TextStyle(
                              fontSize: 13,
                              color: widget.isSelected
                                  ? Colors.white.withOpacity(0.8)
                                  : const Color(0xFF6B7280),
                            ),
                          ),
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

          // Create XFile from downloaded bytes (it's a ZIP file)
          final xFile = XFile.fromData(
            response.bodyBytes,
            mimeType: 'application/zip',
            name: fileName.contains('.') ? fileName : '$fileName.zip',
          );

          // Share the file so user can save/view it
          await Share.shareXFiles(
            [xFile],
            subject: 'OHLP File - ${widget.drug.name}',
            text: 'OHLP document for ${widget.drug.name}',
          );

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
            child: SelectableText(
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
          Expanded(
            child: SelectableText(
              value,
              style: TextStyle(
                fontSize: 12,
                color: widget.isSelected
                    ? Colors.white.withOpacity(0.9)
                    : Colors.black,
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
      child: SelectableText(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: widget.isSelected ? Colors.white : Colors.black,
        ),
      ),
    );
  }
}
