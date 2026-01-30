import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class PopularJobCard extends StatelessWidget {
  final String title;
  final String subtitile;
  final String description;
  final String salary;
  final String time;
  final String immageAsset;
  final String companyLogo; // NEW: company logo URL
  final String costToCompany; // NEW: for LPA formatting
  final VoidCallback? onTap;
  final VoidCallback? onApply;
  final bool isEligible;

  const PopularJobCard({
    super.key,
    required this.title,
    required this.subtitile,
    required this.description,
    required this.salary,
    required this.time,
    required this.immageAsset,
    this.companyLogo = '',
    this.costToCompany = '',
    this.onTap,
    this.onApply,
    this.isEligible = true,
  });

  // Helper to format CTC as LPA
  String _formatCtcAsLpa(String costToCompany) {
    if (costToCompany.isEmpty) return salary;
    try {
      final value = double.parse(costToCompany);
      return '₹${value.toStringAsFixed(1)} LPA';
    } catch (_) {
      return salary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Card(
        margin: EdgeInsets.only(right: 14.w, bottom: 14.h,),
        elevation: 2,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
          side: BorderSide(
            color: Colors.grey.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Container(
          width: 300.w, // INCREASED from 270.8.w
          padding: EdgeInsets.symmetric(horizontal: 16.4.w, vertical: 10.h), // Reduced to fix overflow
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo + Company Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8.r),
                    child: Container(
                      width: 44.w,
                      height: 44.h,
                      color: Colors.grey[200],
                      child: companyLogo.isNotEmpty
                          ? Image.network(
                              companyLogo,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: Colors.grey[300],
                                child: Icon(Icons.business,
                                    size: 22.sp, color: Colors.grey[600]),
                              ),
                            )
                          : Icon(Icons.business,
                              size: 22.sp, color: Colors.grey[600]),
                    ),
                  ),
                  SizedBox(width: 12.w), // Increased from 10.w (+20%)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: const Color(0xFF1A73E8),
                            fontWeight: FontWeight.w700,
                            fontSize: 16.2.sp, // Increased from 13.5.sp (+20%)
                          ),
                        ),
                        SizedBox(height: 2.4.h), // Increased from 2.h (+20%)
                        Text(
                          subtitile,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 13.8.sp, // Increased from 11.5.sp (+20%)
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 6.h), // Balanced spacing
              // Description
              Text(
                description,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13.2.sp, // Increased from 11.sp (+20%)
                  color: Colors.grey[700],
                  height: 1.2,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 4.h), // Reduced from 4.8.h
              // Divider
              Divider(thickness: 0.6, color: Colors.grey.withOpacity(0.3)),
              SizedBox(height: 4.8.h), // Reduced from 6.h
              // Salary + Deadline Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      costToCompany.isNotEmpty 
                          ? _formatCtcAsLpa(costToCompany)
                          : salary,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: const Color(0xFF34A853),
                        fontWeight: FontWeight.w700,
                        fontSize: 15.sp, // Increased from 12.5.sp (+20%)
                      ),
                    ),
                  ),
                  SizedBox(width: 6.w), // Increased from 5.w (+20%)
                  Flexible(
                    child: Text(
                      time,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 13.sp, // Increased from 9.sp (+20%)
                        color: Colors.grey[800],
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 6.h), // Reduced from 7.2.h
              // Apply Button
              SizedBox(
                width: double.infinity,
                height: 36.h, // Reduced from 39.6.h
                child: ElevatedButton(
                  onPressed: isEligible ? onApply : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isEligible
                        ? const Color(0xFF0D9488)
                        : Colors.grey[400],
                    disabledBackgroundColor: Colors.grey[400],
                    padding: EdgeInsets.symmetric(vertical: 3.6.h), // Reduced from 4.8.h
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                  child: Text(
                    isEligible ? 'Apply' : 'Not Eligible',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13.2.sp, // Increased from 11.sp (+20%)
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
