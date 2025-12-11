import 'package:flutter/material.dart';
import '../models/drug_model.dart';

class DrugCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isSelected ? Colors.black : Colors.white,
        border: Border.all(
          color: isSelected ? Colors.black : const Color(0xFFE5E7EB),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
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
                    color: isSelected ? Colors.white : Colors.transparent,
                    border: Border.all(
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFFE5E7EB),
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, size: 14, color: Colors.black)
                      : null,
                ),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Drug name
                      Text(
                        drug.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : Colors.black,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // ATC Info
                      if (drug.atcName != null || drug.code != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            children: [
                              if (drug.code != null) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Colors.white.withOpacity(0.2)
                                        : const Color(0xFFF9FAFB),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: isSelected
                                          ? Colors.white.withOpacity(0.3)
                                          : const Color(0xFFE5E7EB),
                                    ),
                                  ),
                                  child: Text(
                                    drug.code!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.black,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                              if (drug.atcName != null)
                                Expanded(
                                  child: Text(
                                    drug.atcName!,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isSelected
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
                        '${drug.regNumber}${drug.dosageFormName != null ? ' • ${drug.dosageFormName}' : ''}',
                        style: TextStyle(
                          fontSize: 13,
                          color: isSelected
                              ? Colors.white.withOpacity(0.8)
                              : const Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Producer and country
                      Text(
                        '${drug.producerNameRu} • ${drug.countryNameRu}',
                        style: TextStyle(
                          fontSize: 13,
                          color: isSelected
                              ? Colors.white.withOpacity(0.8)
                              : const Color(0xFF6B7280),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
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
