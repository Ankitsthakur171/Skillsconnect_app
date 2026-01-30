import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../Model/LanguageMaster_Model.dart';
import '../../../Model/Languages_Model.dart';
import '../../../Utilities/Language_Api.dart';
import '../../../Utilities/MyAccount_Get_Post/LanguagesGet_Api.dart';
import 'CustomDropDowns/CustomDropDownLanguage.dart';

class LanguageBottomSheet extends StatefulWidget {
  final LanguagesModel? initialData;
  final Function(LanguagesModel data) onSave;
  final List<LanguagesModel> existingLanguages;

  const LanguageBottomSheet({
    super.key,
    this.initialData,
    required this.onSave,
    this.existingLanguages = const [],
  });

  @override
  State<LanguageBottomSheet> createState() => _LanguageBottomSheetState();
}

class _LanguageBottomSheetState extends State<LanguageBottomSheet>
    with SingleTickerProviderStateMixin {
  bool isLoading = true;
  bool isSaving = false;
  bool _loadingMore = false;
  int _currentPage = 1;
  bool _hasMoreData = true;

  List<LanguageMasterModel> masterLanguages = [];
  LanguageMasterModel? selectedLanguage;
  late String selectedProficiency;
  late ScrollController _languageScrollController;

  final List<String> _proficiencyLevels = [
    'Basic',
    'Native/Bilingual',
    'Conversational',
  ];

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  bool _snackBarShown = false;
  OverlayEntry? _overlayEntry;

  void _showSnackBarOnce(String message,
      {Color bg = Colors.red, int seconds = 2}) {
    if (_snackBarShown) return;
    _snackBarShown = true;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 50,
        left: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(8.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              message,
              style: TextStyle(color: Colors.white, fontSize: 11.sp),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);

    Future.delayed(Duration(seconds: seconds), () {
      _overlayEntry?.remove();
      _overlayEntry = null;
      _snackBarShown = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _languageScrollController = ScrollController();
    _languageScrollController.addListener(_onLanguageScrollListener);
    selectedProficiency =
        widget.initialData?.proficiency ?? _proficiencyLevels[0];

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation =
        CurvedAnimation(parent: _animationController, curve: Curves.easeIn);

    _loadLanguages();
  }

  void _onLanguageScrollListener() {
    final position = _languageScrollController.position;
    final maxScrollExtent = position.maxScrollExtent;
    
    print('📜 [EditLanguageBottomSheet] Scroll: ${position.pixels.toStringAsFixed(0)}/${maxScrollExtent.toStringAsFixed(0)}');
    
    // Load more when scrolled to 90% or reached end
    if (position.pixels >= maxScrollExtent * 0.9 && !_loadingMore && _hasMoreData) {
      print('📜 [EditLanguageBottomSheet] Triggering load more at 90% scroll');
      _loadMoreLanguages();
    }
  }

  Future<void> _loadLanguages() async {
    print('📋 [EditLanguageBottomSheet] Loading languages page: $_currentPage');
    try {
      setState(() => isLoading = true);
      
      // Fetch first page from API
      final languagesFromApi = await LanguageListApi.fetchLanguages(page: _currentPage);
      print('📋 [EditLanguageBottomSheet] Received ${languagesFromApi.length} languages from API');

      if (!mounted) return;

      LanguageMasterModel defaultLang = languagesFromApi.isNotEmpty
          ? languagesFromApi.first
          : LanguageMasterModel(languageId: 0, languageName: "No languages");

      LanguageMasterModel selectedFromApi;
      if (widget.initialData != null &&
          widget.initialData!.languageName.isNotEmpty) {
        selectedFromApi = languagesFromApi.firstWhere(
          (l) =>
              l.languageName.toLowerCase() ==
              widget.initialData!.languageName.toLowerCase(),
          orElse: () => defaultLang,
        );
      } else {
        selectedFromApi = defaultLang;
      }

      setState(() {
        masterLanguages = languagesFromApi;
        _hasMoreData = languagesFromApi.length >= 10; // Assume more data if we got 10 items
        selectedLanguage = selectedFromApi;
        isLoading = false;
      });
      
      print('📋 [EditLanguageBottomSheet] Total languages loaded: ${masterLanguages.length}, hasMore: $_hasMoreData');

      _animationController.forward();
    } catch (e) {
      print('❌ [EditLanguageBottomSheet] Error loading languages: $e');
      if (!mounted) return;
      setState(() => isLoading = false);
      _showSnackBarOnce("Failed to load languages");
    }
  }

  Future<void> _loadMoreLanguages() async {
    if (_loadingMore || !_hasMoreData) {
      print('📋 [EditLanguageBottomSheet] Skip load more - loading: $_loadingMore, hasMore: $_hasMoreData');
      return;
    }

    print('📋 [EditLanguageBottomSheet] Loading more languages...');
    setState(() {
      _loadingMore = true;
      _currentPage++;
    });

    try {
      // Fetch next page from API
      final languagesFromApi = await LanguageListApi.fetchLanguages(page: _currentPage);
      print('📋 [EditLanguageBottomSheet] Received ${languagesFromApi.length} languages from API for page $_currentPage');
      
      if (!mounted) return;

      setState(() {
        masterLanguages.addAll(languagesFromApi);
        _hasMoreData = languagesFromApi.length >= 10; // More data available if we got 10 items
        _loadingMore = false;
      });
      
      print('📋 [EditLanguageBottomSheet] Total languages now: ${masterLanguages.length}, hasMore: $_hasMoreData');
    } catch (e) {
      print('❌ [EditLanguageBottomSheet] Error loading more languages: $e');
      if (!mounted) return;
      setState(() => _loadingMore = false);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _languageScrollController.removeListener(_onLanguageScrollListener);
    _languageScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      minChildSize: 0.7,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(18.1.r)),
          ),
          padding: EdgeInsets.only(
            left: 18.1.w,
            right: 18.1.w,
            top: 12.h,
            bottom: 18.1.h,
          ),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: isLoading
                ? _buildLoader()
                : Column(
                    children: [
                      _buildHeader(),
                      SizedBox(height: 8.h),
                      Expanded(
                        child: ListView(
                          controller: scrollController,
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            _buildLabel("Select language", required: true),
                            _buildLanguageDropdown(),
                            SizedBox(height: 16.h),
                            _buildLabel("Select proficiency", required: true),
                            _buildProficiencyDropdown(),
                          ],
                        ),
                      ),
                      SizedBox(height: 16.h),
                      _buildSubmitButton(),
                                            SizedBox(height: 16.h),

                    ],
                  ),
          ),
        );
      },
    );
  }

  Widget _buildLoader() {
    return Center(
      child: CircularProgressIndicator(
        color: const Color(0xFF005E6A),
        strokeWidth: 3.w,
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          "Add Language",
          style: TextStyle(
            fontSize: 16.2.sp,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF003840),
          ),
        ),
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child:
              Icon(Icons.close, size: 17.7.w, color: const Color(0xFF005E6A)),
        ),
      ],
    );
  }

  Widget _buildLabel(String text, {bool required = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6.h),
      child: Row(
        children: [
          Text(
            text,
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF003840),
            ),
          ),
          if (required)
            Text(" *", style: TextStyle(color: Colors.red, fontSize: 11.sp)),
        ],
      ),
    );
  }

  Widget _buildLanguageDropdown() {
    return CustomFieldLanguageDropdown<LanguageMasterModel>(
      masterLanguages.isNotEmpty
          ? masterLanguages
          : [
              LanguageMasterModel(
                  languageId: 0, languageName: "No languages available")
            ],
      selectedLanguage,
      (val) {
        if (val == null) return;
        if (val.languageId == 0) {
          _showSnackBarOnce("Invalid language selected");
          return;
        }
        setState(() => selectedLanguage = val);
      },
      hintText: "Select language",
      scrollController: _languageScrollController,
      onLoadMore: _loadMoreLanguages,
    );
  }

  Widget _buildProficiencyDropdown() {
    return CustomFieldLanguageDropdown<String>(
      _proficiencyLevels,
      selectedProficiency,
      (val) => setState(() => selectedProficiency = val ?? ""),
      hintText: "Select proficiency",
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      height: 45.1.h,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isSaving ? null : _handleSubmit,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF005E6A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(27.1.r),
          ),
        ),
        child: isSaving
            ? SizedBox(
                width: 18.w,
                height: 18.h,
                child: const CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                "Save",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 13.7.sp,
                    fontWeight: FontWeight.bold
                ),
              ),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (selectedLanguage == null || selectedProficiency.isEmpty) {
      _showSnackBarOnce("Please fill all required fields");
      return;
    }

    // Check for duplicate language
    final isDuplicate = widget.existingLanguages.any((lang) =>
        lang.languageId == selectedLanguage!.languageId &&
        (widget.initialData == null || lang.id != widget.initialData!.id));
    
    if (isDuplicate) {
      _showSnackBarOnce("This language is already added");
      return;
    }

    setState(() => isSaving = true);

    final prefs = await SharedPreferences.getInstance();
    final authToken = prefs.getString("authToken") ?? "";
    final connectSid = prefs.getString("connectSid") ?? "";

    final model = LanguagesModel(
      id: widget.initialData?.id,
      languageId: selectedLanguage!.languageId,
      languageName: selectedLanguage!.languageName,
      proficiency: selectedProficiency,
    );

    final res = await LanguageDetailApi.updateLanguages(
      authToken: authToken,
      connectSid: connectSid,
      language: model,
    );

    if (!mounted) return;

    setState(() => isSaving = false);

    if (res["success"] == true) {
      widget.onSave(model);
      _showSnackBarOnce("Language updated", bg: Colors.green);
      Navigator.pop(context);
    } else {
      _showSnackBarOnce("Failed to update language");
    }
  }
}
