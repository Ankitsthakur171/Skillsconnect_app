import 'dart:async';
import 'package:flutter/material.dart';

class SearchableDropdownField extends StatefulWidget {
  final String? value;
  final List<String> items;
  final Function(String?) onChanged;
  final String label;
  final String? decoration;

  const SearchableDropdownField({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.label = 'Select an option',
    this.decoration,
  });

  @override
  State<SearchableDropdownField> createState() =>
      _SearchableDropdownFieldState();
}

class _SearchableDropdownFieldState extends State<SearchableDropdownField> {
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
    _filteredItems = widget.items.toList();
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
    if (!_focusNode.hasFocus && _overlayEntry != null) {
      _removeOverlay();
    }
  }

  void _toggleDropdown() {
    if (_overlayEntry == null) {
      _filteredItems = widget.items.toList();
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
    _focusNode.unfocus();
  }

  void _selectItem(String item) {
    widget.onChanged(item);
    _removeOverlay();
  }

  OverlayEntry _createOverlayEntry() {
    RenderBox? renderBox =
        _key.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) {
      return OverlayEntry(builder: (_) => const SizedBox.shrink());
    }

    Size size = renderBox.size;
    Offset position = renderBox.localToGlobal(Offset.zero);

    final screenHeight = MediaQuery.of(context).size.height;
    final padding = MediaQuery.of(context).padding;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final availableSpaceBelow = screenHeight -
        position.dy -
        size.height -
        padding.bottom -
        keyboardHeight;
    final availableSpaceAbove = position.dy - padding.top;
    const maxDropdownHeight = 250.0;

    bool openAbove = availableSpaceBelow < maxDropdownHeight &&
        availableSpaceAbove > availableSpaceBelow;
    double dropdownHeight =
        (_filteredItems.length * 48.0 + 56.0).clamp(50.0, maxDropdownHeight);

    if (openAbove && dropdownHeight > availableSpaceAbove) {
      dropdownHeight = availableSpaceAbove - 10;
    } else if (!openAbove && dropdownHeight > availableSpaceBelow) {
      dropdownHeight = availableSpaceBelow - 10;
    }

    return OverlayEntry(
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Positioned(
          width: size.width,
          child: CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            offset:
                Offset(0, openAbove ? -(dropdownHeight + 4) : size.height + 4),
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: size.width,
                height: dropdownHeight,
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
                      TextField(
                      controller: _searchController,
                      focusNode: _focusNode,
                      decoration: const InputDecoration(
                        hintText: 'Search...',
                        isDense: true,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                      ),
                      onChanged: (query) {
                        if (_debounce?.isActive ?? false) _debounce?.cancel();
                        _debounce =
                            Timer(const Duration(milliseconds: 300), () {
                          setState(() {
                            _filteredItems = widget.items
                                .where((item) => item
                                    .toLowerCase()
                                    .contains(query.toLowerCase()))
                                .toList();
                          });
                        });
                      },
                    ),

                    const SizedBox(height: 4),
                    Expanded(
                      child: _filteredItems.isEmpty
                          ? const Center(child: Text('No items found'))
                          : Scrollbar(
                              child: ListView.builder(
                                padding: EdgeInsets.zero,
                                itemCount: _filteredItems.length,
                                itemBuilder: (context, index) {
                                  final item = _filteredItems[index];
                                  return ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 8),
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
            ),
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
            widget.value ?? widget.label,
            style: TextStyle(
              color: widget.value == null ? Colors.grey : Colors.black,
            ),
          ),
        ),
      ),
    );
  }
}

class NonSearchableDropdownField extends StatefulWidget {
  final String? value;
  final List<String> items;
  final Function(String?) onChanged;
  final String label;
  final String? decoration;

  const NonSearchableDropdownField({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.label = 'Select an option',
    this.decoration,
  });

  @override
  State<NonSearchableDropdownField> createState() =>
      _NonSearchableDropdownFieldState();
}

class _NonSearchableDropdownFieldState extends State<NonSearchableDropdownField> {
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
    _filteredItems = widget.items.toList();
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
    if (!_focusNode.hasFocus && _overlayEntry != null) {
      _removeOverlay();
    }
  }

  void _toggleDropdown() {
    if (_overlayEntry == null) {
      _filteredItems = widget.items.toList();
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
    _focusNode.unfocus();
  }

  void _selectItem(String item) {
    widget.onChanged(item);
    _removeOverlay();
  }

  OverlayEntry _createOverlayEntry() {
    RenderBox? renderBox =
    _key.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) {
      return OverlayEntry(builder: (_) => const SizedBox.shrink());
    }

    Size size = renderBox.size;
    Offset position = renderBox.localToGlobal(Offset.zero);

    final screenHeight = MediaQuery.of(context).size.height;
    final padding = MediaQuery.of(context).padding;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final availableSpaceBelow = screenHeight -
        position.dy -
        size.height -
        padding.bottom -
        keyboardHeight;
    final availableSpaceAbove = position.dy - padding.top;
    const maxDropdownHeight = 250.0;

    bool openAbove = availableSpaceBelow < maxDropdownHeight &&
        availableSpaceAbove > availableSpaceBelow;
    double dropdownHeight =
    (_filteredItems.length * 48.0 + 56.0).clamp(50.0, maxDropdownHeight);

    if (openAbove && dropdownHeight > availableSpaceAbove) {
      dropdownHeight = availableSpaceAbove - 10;
    } else if (!openAbove && dropdownHeight > availableSpaceBelow) {
      dropdownHeight = availableSpaceBelow - 10;
    }

    return OverlayEntry(
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Positioned(
          width: size.width,
          child: CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            offset:
            Offset(0, openAbove ? -(dropdownHeight + 4) : size.height + 4),
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: size.width,
                height: dropdownHeight,
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
                    //     contentPadding:
                    //     EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                    //   ),
                    //   onChanged: (query) {
                    //     if (_debounce?.isActive ?? false) _debounce?.cancel();
                    //     _debounce =
                    //         Timer(const Duration(milliseconds: 300), () {
                    //           setState(() {
                    //             _filteredItems = widget.items
                    //                 .where((item) => item
                    //                 .toLowerCase()
                    //                 .contains(query.toLowerCase()))
                    //                 .toList();
                    //           });
                    //         });
                    //   },
                    // ),
                    const SizedBox(height: 4),
                    Expanded(
                      child: _filteredItems.isEmpty
                          ? const Center(child: Text('No items found'))
                          : Scrollbar(
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          itemCount: _filteredItems.length,
                          itemBuilder: (contextF, index) {
                            final item = _filteredItems[index];
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 8),
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
            ),
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
            widget.value ?? widget.label,
            style: TextStyle(
              color: widget.value == null ? Colors.grey : Colors.black,
            ),
          ),
        ),
      ),
    );
  }
}
