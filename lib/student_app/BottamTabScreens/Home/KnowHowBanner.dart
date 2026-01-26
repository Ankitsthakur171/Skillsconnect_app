import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../Model/Banner_model.dart';

class KnowHowBanner extends StatefulWidget {
  final List<BannerModel> banners;

  const KnowHowBanner({
    super.key,
    required this.banners,
  });

  @override
  State<KnowHowBanner> createState() => _KnowHowBannerState();
}

class _KnowHowBannerState extends State<KnowHowBanner> {
  int _currentPage = 0;
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Widget _buildImageWithShimmer(String url) {
    if (url.isEmpty || !Uri.parse(url).isAbsolute) {
      return Container(
        color: Colors.grey[200],
        alignment: Alignment.center,
        child: Icon(Icons.error, color: Colors.red, size: 20.w),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(10.r),
      child: Image.network(
        url,
        fit: BoxFit.contain,
        width: double.infinity,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              width: double.infinity,
              height: 126.4.h,
              color: Colors.white,
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[200],
            alignment: Alignment.center,
            child: Icon(Icons.broken_image, size: 20.w, color: Colors.red),
          );
        },
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    if (url.isEmpty || !Uri.parse(url).isAbsolute) return;

    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: 12.h),
        Container(
          height: 145.h,
          margin: EdgeInsets.symmetric(horizontal: 12.w),
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.banners.length,
            onPageChanged: (index) {
              if (!mounted) return;
              setState(() => _currentPage = index);
            },
            itemBuilder: (context, index) {
              final banner = widget.banners[index];
              return Padding(
                padding: EdgeInsets.all(5.w),
                child: GestureDetector(
                  onTap: () => _launchUrl(banner.link),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(
                        color: Colors.grey.withOpacity(0.4),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15), // darker shadow for consistency
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: _buildImageWithShimmer(banner.image),
                  ),
                ),
              );
            },
          ),
        ),
        SizedBox(height: 12.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.banners.length, (index) {
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: 3.w),
              child: Icon(
                Icons.circle,
                size: 7.w,
                color: _currentPage == index ? const Color(0xFF003840) : Colors.grey,
              ),
            );
          }),
        ),
      ],
    );
  }
}
