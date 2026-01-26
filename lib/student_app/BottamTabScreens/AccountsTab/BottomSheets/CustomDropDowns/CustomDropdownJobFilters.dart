
import 'dart:async';
import 'package:flutter/material.dart';

class CustomFieldJobFilter extends StatefulWidget {
  final List<String> items;
  final String value;
  final ValueChanged<String?> onChanged;
  final String label;
  final bool forceOpenUpward;

  const CustomFieldJobFilter(
    this.items,
    this.value,
    this.onChanged, {
    super.key,
    this.label = 'Select an option',
    this.forceOpenUpward = false,
  });

  @override
  State<CustomFieldJobFilter> createState() => _CustomFieldJobFilterState();
}

class _CustomFieldJobFilterState extends State<CustomFieldJobFilter> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  late TextEditingController _searchController;
  late List<String> _filteredItems;
  final GlobalKey _key = GlobalKey();
  final FocusNode _focusNode = FocusNode();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _filteredItems = widget.items.toSet().toList();
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    _searchController.dispose();
    _removeOverlay();
    super.dispose();
  }

  void _handleFocusChange() {
    if (_focusNode.hasFocus && _overlayEntry == null) {
      _toggleDropdown();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Scrollable.ensureVisible(
          _key.currentContext!,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      });
    }
  }

  void _toggleDropdown() {
    if (_overlayEntry == null) {
      _filteredItems = widget.items.toSet().toList();
      _searchController.clear();
      _overlayEntry = _createOverlayEntry();
      Overlay.of(context).insert(_overlayEntry!);
      _focusNode.requestFocus();
    } else {
      _removeOverlay();
    }
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _selectItem(String item) {
    widget.onChanged(item);
    _removeOverlay();
  }

  OverlayEntry _createOverlayEntry() {
    RenderBox renderBox = _key.currentContext!.findRenderObject() as RenderBox;
    Size size = renderBox.size;
    Offset position = renderBox.localToGlobal(Offset.zero);

    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final keyboardHeight = mediaQuery.viewInsets.bottom;
    final padding = mediaQuery.padding;
    final availableSpaceBelow = screenHeight -
        position.dy -
        size.height -
        padding.bottom -
        keyboardHeight;
    final availableSpaceAbove = position.dy - padding.top;
    const fixedDropdownHeight = 250.0;

    bool openAbove = widget.forceOpenUpward ||
        (availableSpaceBelow < fixedDropdownHeight &&
            availableSpaceAbove > availableSpaceBelow);

    return OverlayEntry(
      builder: (context) => Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(
            0,
            openAbove ? -(fixedDropdownHeight + 8) : size.height + 4,
          ),
          child: StatefulBuilder(
            builder: (context, setStateOverlay) {
              return Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: size.width,
                  height: fixedDropdownHeight,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextField(
                          controller: _searchController,
                          focusNode: _focusNode,
                          decoration: InputDecoration(
                            hintText: 'Search...',
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide:
                                  BorderSide(color: Colors.grey.shade400),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                  color: Color(0xFF005E6A), width: 1.5),
                            ),
                          ),
                          onChanged: (query) {
                            _debounce?.cancel();
                            _debounce =
                                Timer(const Duration(milliseconds: 300), () {
                              setStateOverlay(() {
                                _filteredItems = widget.items
                                    .where((item) => item
                                        .toLowerCase()
                                        .contains(query.toLowerCase()))
                                    .toList();
                              });
                            });
                          },
                        ),
                      ),
                      Expanded(
                        child: Scrollbar(
                          child: ListView.builder(
                            padding: EdgeInsets.zero,
                            itemCount: _filteredItems.length,
                            itemBuilder: (context, index) {
                              final item = _filteredItems[index];
                              return ListTile(
                                dense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 4),
                                title: Text(item,
                                    style: const TextStyle(fontSize: 14)),
                                selected: widget.value == item,
                                selectedTileColor: Colors.blue.shade50,
                                onTap: () => _selectItem(item),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        key: _key,
        onTap: _toggleDropdown,
        child: InputDecorator(
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            suffixIcon: Icon(
              _overlayEntry == null
                  ? (widget.forceOpenUpward
                      ? Icons.arrow_drop_up
                      : Icons.arrow_drop_down)
                  : Icons.arrow_drop_up,
              color: Colors.grey.shade700,
            ),
          ),
          child: Text(
            widget.value.trim().isEmpty ? widget.label : widget.value.trim(),
            style: TextStyle(
              fontSize: 14,
              color:
                  widget.value.isEmpty ? Colors.grey.shade600 : Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class CustomFiledJobFilterNoSearch extends StatefulWidget {
  final List<String> items;
  final String value;
  final ValueChanged<String?> onChanged;
  final String label;

  const CustomFiledJobFilterNoSearch(
    this.items,
    this.value,
    this.onChanged, {
    super.key,
    this.label = 'Select an option',
  });

  @override
  State<CustomFiledJobFilterNoSearch> createState() =>
      _CustomFiledJobFilterNoSearchState();
}

class _CustomFiledJobFilterNoSearchState
    extends State<CustomFiledJobFilterNoSearch> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  late TextEditingController _searchController;
  late List<String> _filteredItems;
  final GlobalKey _key = GlobalKey();
  final FocusNode _focusNode = FocusNode();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _filteredItems = widget.items
        .map((s) => s?.toString().trim() ?? '')
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList();
    _focusNode.addListener(_handleFocusChange);
    print('Init: FocusNode created, hasFocus: ${_focusNode.hasFocus}');
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    _searchController.dispose();
    _removeOverlay();
    print('Dispose: Cleaning up');
    super.dispose();
  }

  void _handleFocusChange() {
    print(
        'Focus Change: hasFocus: ${_focusNode.hasFocus}, Overlay: $_overlayEntry');
    if (_focusNode.hasFocus && _overlayEntry == null) {
      _toggleDropdown();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Scrollable.ensureVisible(
          _key.currentContext!,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        print('PostFrame: Ensured visibility, Focus: ${_focusNode.hasFocus}');
      });
    }
  }

  void _toggleDropdown() {
    if (_overlayEntry == null) {
      _filteredItems = widget.items.toSet().toList();
      _searchController.clear();
      _overlayEntry = _createOverlayEntry();
      Overlay.of(context).insert(_overlayEntry!);
      _focusNode.requestFocus();
      print(
          'ToggleDropdown: Overlay created, Focus requested: ${_focusNode.hasFocus}');
    } else {
      _removeOverlay();
    }
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    print('RemoveOverlay: Overlay removed');
  }

  void _selectItem(String item) {
    final trimmed = item.trim();
    widget.onChanged(trimmed);
    _removeOverlay();
    print('SelectItem: Selected $trimmed');
  }

  OverlayEntry _createOverlayEntry() {
    RenderBox renderBox = _key.currentContext!.findRenderObject() as RenderBox;
    Size size = renderBox.size;
    Offset position = renderBox.localToGlobal(Offset.zero);

    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final keyboardHeight = mediaQuery.viewInsets.bottom;
    final padding = mediaQuery.padding;
    final availableSpaceBelow = screenHeight -
        position.dy -
        size.height -
        padding.bottom -
        keyboardHeight;
    final availableSpaceAbove = position.dy - padding.top;
    const fixedDropdownHeight = 160.0;
    bool openAbove = availableSpaceBelow < fixedDropdownHeight &&
        availableSpaceAbove > availableSpaceBelow;

    return OverlayEntry(
      builder: (context) => Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(
              0, openAbove ? -(fixedDropdownHeight + 4) : size.height + 4),
          child: StatefulBuilder(
            builder: (context, setState) {
              return Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: size.width,
                  height: fixedDropdownHeight,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // TextField(
                      //   controller: _searchController,
                      //   focusNode: _focusNode,
                      //   decoration: const InputDecoration(
                      //     hintText: 'Search...',
                      //     isDense: true,
                      //     contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                      //   ),
                      //   onChanged: (query) {
                      //     print('OnChanged: Query: $query, Focus: ${_focusNode.hasFocus}');
                      //     _debounce?.cancel();
                      //     _debounce = Timer(const Duration(milliseconds: 300), () {
                      //       setState(() {
                      //         _filteredItems = widget.items
                      //             .where((item) => item.toLowerCase().contains(query.toLowerCase()))
                      //             .toSet()
                      //             .toList();
                      //         _overlayEntry?.markNeedsBuild();
                      //         print('Debounce: Filtered to ${_filteredItems.length} items, Focus: ${_focusNode.hasFocus}');
                      //       });
                      //     });
                      //   },
                      // ),
                      // const SizedBox(height: 4),
                      Expanded(
                        child: Scrollbar(
                          child: ListView.builder(
                            padding: EdgeInsets.zero,
                            itemCount: _filteredItems.length,
                            itemBuilder: (context, index) {
                              final item = _filteredItems[index];
                              return ListTile(
                                contentPadding:
                                    const EdgeInsets.symmetric(horizontal: 8),
                                dense: true,
                                title: Text(item),
                                onTap: () => _selectItem(item),
                                selected: widget.value == item,
                                selectedTileColor: Colors.blue.shade50,
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        key: _key,
        onTap: _toggleDropdown,
        child: InputDecorator(
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            suffixIcon: Icon(
              _overlayEntry == null
                  ? Icons.arrow_drop_down
                  : Icons.arrow_drop_up,
            ),
          ),
          child: Text(
            widget.value.isEmpty ? widget.label : widget.value,
            style: TextStyle(
              color: widget.value.isEmpty ? Colors.grey : Colors.black,
            ),
          ),
        ),
      ),
    );
  }
}
