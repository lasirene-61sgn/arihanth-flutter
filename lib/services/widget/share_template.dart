import 'package:flutter/material.dart';

class TemplateWidget extends StatelessWidget {
  final String title;
  final Map<String, String> details;
  final ImageProvider? imageProvider;

  const TemplateWidget({
    Key? key,
    required this.title,
    required this.details,
    this.imageProvider,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 60% Height for Image, 40% for details
    const double imageRatio = 0.55;
    final entries = details.entries.toList();
    final List<Widget> detailRows = [];

    for (int i = 0; i < entries.length; i++) {
      var entry = entries[i];

      if (entry.key.toLowerCase() == 'id') {
        if (i + 1 < entries.length) {
          entry = entries[i + 1];
          i++;
        } else {
          continue;
        }
      }

      final valueLower = entry.value.toLowerCase();
      if (valueLower.endsWith('.jpg') ||
          valueLower.endsWith('.jpeg') ||
          valueLower.endsWith('.png')) {
        continue;
      }

      final displayKey = entry.key
          .replaceAll('_', ' ')
          .splitMapJoin(
        RegExp(r'\b\w'),
        onMatch: (m) => m.group(0)!.toUpperCase(),
        onNonMatch: (n) => n,
      );

      detailRows.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 120,
                child: Text(
                  '$displayKey:',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  entry.value,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      );
    }


    return Container(
      width: 300,
      height: 500,
      color: Colors.white,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Title Header
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey,
                ),
              ),
            ),
          ),

          // 2. 60% Image Area
          Expanded(
            flex: (imageRatio * 100).toInt(), // 60
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blueGrey.shade400, width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: imageProvider != null
                  ? Image(
                image: imageProvider!,
                fit: BoxFit.cover,
              )
                  : const Center(
                child: Text('Image Unavailable'),
              ),
            ),
          ),

          // 3. Spacer
          const SizedBox(height: 16),

          // 4. 40% Details Area
          Expanded(
            flex: ((1 - imageRatio) * 100).toInt(), // 40
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: detailRows,
              ),
            ),
          ),
        ],
      ),
    );
  }
}