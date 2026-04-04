import 'package:arianth/screens/catelogue/model/catalogue_model.dart';
import 'package:arianth/services/widget/pdf_thumbnail.dart';
import 'package:arianth/services/local_storage/shared_preference.dart';
import 'package:arianth/services/widget/full_screen_image_viewer.dart';
import 'package:flutter/material.dart';
import '../../../app_color/app_color.dart';

class CatalogueGridCard extends StatelessWidget {
  final Catalogue item;
  final VoidCallback onTap;

  const CatalogueGridCard({
    super.key,
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Use images array first, fallback to productImage
    final String? role = SharedPreferencesHelper().getString("role");
    final String? imageUrl = (item.images != null && item.images!.isNotEmpty)
        ? item.images!.first.imageUrl
        : item.productImage;
    final bool isPdf = imageUrl?.toLowerCase().contains('.pdf') ?? false;

    return Container(
      decoration: BoxDecoration(
        color: AppColor.white, // Pure white for cards
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColor.border, width: 1), // Standardized border
        boxShadow: [
          BoxShadow(
            // Use Primary (Midnight Navy) for a very subtle, professional shadow
            color: AppColor.primary.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Media Section
              Expanded(
                child: Container(
                  width: double.infinity,
                  color: AppColor.surface, 
                  child: _buildMediaContent(context,isPdf, imageUrl),
                ),
              ),

              // Content Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.productName?.toUpperCase() ?? '-',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: AppColor.textPrimary,
                        letterSpacing: 0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      role?.toLowerCase() == 'super_admin'
                          ? (item.category?.name ?? '')
                          : ((item.size != null && item.size!.isNotEmpty)
                              ? item.size!
                              : (item.category?.name ?? '-')),
                      style: const TextStyle(
                        color: AppColor.textSecondary,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding:  EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColor.secondary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            item.designCode ?? '-',
                            style:  TextStyle(
                              fontSize: 10,
                              color: AppColor.secondary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        _buildStatusIcon(),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIcon() {
    bool isAccepted = item.designStatus == "Accept" || item.designStatus == "Accepted";
    return Icon(
      isAccepted ? Icons.check_circle_rounded : Icons.pending_rounded,
      size: 18,
      color: isAccepted ? AppColor.success : AppColor.warning,
    );
  }

  Widget _buildMediaContent(BuildContext context,bool isPdf, String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image_not_supported_outlined, color: AppColor.textSecondary, size: 30),
          const SizedBox(height: 4),
          Text(
            "Empty",
            style: TextStyle(fontSize: 12, color: AppColor.textSecondary, fontWeight: FontWeight.bold),
          ),
        ],
      );
    }

    if (isPdf) {
      return PdfThumbnail(url: imageUrl, fit: BoxFit.contain);
    }

    return GestureDetector(
      onTap: () => FullScreenImageViewer.show(context, imageUrl),
      child: Image.network(
        imageUrl,
        fit: BoxFit.contain,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppColor.accent.withOpacity(0.5)),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) =>
        const Icon(Icons.broken_image_outlined, color: AppColor.textSecondary, size: 30),
      ),
    );
  }
}