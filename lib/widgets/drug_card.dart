import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/drug_model.dart';

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
                          Text(
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
                                    const SizedBox(width: 8),
                                  ],
                                  if (widget.drug.atcName != null)
                                    Expanded(
                                      child: Text(
                                        widget.drug.atcName!,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: widget.isSelected
                                              ? Colors.white.withOpacity(0.9)
                                              : const Color(0xFF6B7280),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
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

                          FittedBox // Producer and country
                          (
                            child: Text(
                              '${widget.drug.producerNameRu} • ${widget.drug.countryNameRu}',
                              style: TextStyle(
                                fontSize: 13,
                                color: widget.isSelected
                                    ? Colors.white.withOpacity(0.8)
                                    : const Color(0xFF6B7280),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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
                          onTap: _openOhlpLink,
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
    final uri = Uri.parse(urlString);

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open download link'),
              backgroundColor: Colors.black,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening link: $e'),
            backgroundColor: Colors.black,
          ),
        );
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
          Expanded(
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
      child: Text(
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
