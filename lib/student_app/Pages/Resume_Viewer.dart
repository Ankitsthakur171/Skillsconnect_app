import 'package:flutter/material.dart';
import 'package:flutter_cached_pdfview/flutter_cached_pdfview.dart';
import 'dart:io';

class ResumeViewer extends StatelessWidget {
  final String resumeUrl;
  final File? pdfFile;

  const ResumeViewer({required this.resumeUrl, this.pdfFile, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text("Resume"), backgroundColor: Colors.white,),
      body: Builder(
        builder: (context) {
          try {
            return const PDF().cachedFromUrl(
              resumeUrl,
              placeholder: (progress) =>
                  Center(child: Text('Loading: $progress%')),
              errorWidget: (error) =>
                  Center(child: Text('Error loading PDF from URL: $error')),
            );
          } catch (e) {
            if (pdfFile != null) {
              final fileUri = 'file://${pdfFile!.path}';
              try {
                return const PDF().cachedFromUrl(
                  fileUri,
                  placeholder: (progress) =>
                      Center(child: Text('Loading local: $progress%')),
                  errorWidget: (error) =>
                      Center(child: Text('Error loading local PDF: $error')),
                );
              } catch (e) {
                return const Center(
                  child: Text('PDF loading failed - local file not supported'),
                );
              }
            } else {
              return const Center(child: Text('PDF not available'));
            }
          }
        },
      ),
    );
  }
}
