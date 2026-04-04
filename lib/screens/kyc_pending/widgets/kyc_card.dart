import 'package:arianth/app_color/app_color.dart';
import 'package:flutter/material.dart';
import '../../../../services/widget/full_screen_image_viewer.dart';

class KycCard extends StatelessWidget {
  final dynamic item; // Can be KycBuyer or KycCraftsman
  final bool isBuyer;
  final VoidCallback onTap;

  const KycCard({
    super.key,
    required this.item,
    required this.isBuyer,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Get image from aadharDetails or panDetails if available
    String? imageUrl;
    if (item.aadharDetails.isNotEmpty && item.aadharDetails.first.aadharImageUrl != null) {
      imageUrl = item.aadharDetails.first.aadharImageUrl;
    } else if (item.panDetails.isNotEmpty && item.panDetails.first.panImageUrl != null) {
      imageUrl = item.panDetails.first.panImageUrl;
    }

    return GestureDetector(
      onTap: onTap,
      child: Card(
        color: AppColor.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColor.divider, width: 1),
        ),
        elevation: 2,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Side: Image (Placeholder or KYC Doc)
            SizedBox(
              width: 110,
              height: 180,
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColor.background,
                  borderRadius: BorderRadius.horizontal(left: Radius.circular(12)),
                ),
                child: imageUrl != null && imageUrl.isNotEmpty
                    ? GestureDetector(
                        onTap: () => FullScreenImageViewer.show(context, imageUrl!),
                        child: ClipRRect(
                          borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
                          child: Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(AppColor.primary),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) => const Center(
                              child: Icon(
                                Icons.assignment_ind,
                                color: AppColor.textHint,
                                size: 40,
                              ),
                            ),
                          ),
                        ),
                      )
                    : const Center(child: Icon(Icons.assignment_ind, color: AppColor.textHint, size: 40)),
              ),
            ),

            // Right Side: Details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(width: 4),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.name ?? '-',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColor.textPrimary, fontSize: 13),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 5),
                              Text(
                                isBuyer ? 'BP Code: ${item.bpCode ?? '-'}' : 'Craftsman: ${item.craftmanCode ?? '-'}',
                                style: const TextStyle(color: AppColor.textSecondary, fontSize: 12),
                              ),
                              Text(
                                'Business: ${item.businessName ?? '-'}',
                                style: const TextStyle(color: AppColor.textSecondary, fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        _statusBadge(item.kycStatus),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Specs Block
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColor.background,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Mobile: ${item.mobile ?? '-'}',
                            style: const TextStyle(color: AppColor.textSecondary, fontSize: 11),
                          ),
                          Text(
                            'Aadhar: ${item.aadharNo ?? '-'}',
                            style: const TextStyle(color: AppColor.textSecondary, fontSize: 11),
                          ),
                          Text(
                            'Location: ${item.city ?? '-'}${item.state != null ? ", ${item.state}" : ""}',
                            style: const TextStyle(color: AppColor.primary, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
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

  Widget _statusBadge(String? status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColor.primary.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColor.primary.withOpacity(0.3), width: 0.5),
      ),
      child: Text(
        (status ?? "PENDING").toUpperCase(),
        style: const TextStyle(
          color: AppColor.primary, 
          fontSize: 9, 
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5
        ),
      ),
    );
  }
}
