import 'dart:async';
import 'package:flutter/material.dart';

class CustomFieldWorkExperienceDropdown extends StatefulWidget {
  final List<String> items;
  final String value;
  final ValueChanged<String?> onChanged;
  final String label;

  const CustomFieldWorkExperienceDropdown(
      this.items,
      this.value,
      this.onChanged, {
        super.key,
        this.label = 'Please select',
      });

  @override
  State<CustomFieldWorkExperienceDropdown> createState() => _CustomFieldWorkExperienceDropdownState();
}

class _CustomFieldWorkExperienceDropdownState extends State<CustomFieldWorkExperienceDropdown> {
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
    print('Focus Change: hasFocus: ${_focusNode.hasFocus}, Overlay: $_overlayEntry');
    if (_focusNode.hasFocus && _overlayEntry == null) {
      _toggleDropdown();
    } else if (!_focusNode.hasFocus && _overlayEntry != null) {
      _removeOverlay();
    }
  }

  void _toggleDropdown() {
    if (_overlayEntry == null) {
      _filteredItems = widget.items.toSet().toList();
      _searchController.clear();
      _overlayEntry = _createOverlayEntry();
      Overlay.of(context).insert(_overlayEntry!);
      _focusNode.requestFocus();
      print('ToggleDropdown: Overlay created, Focus requested: ${_focusNode.hasFocus}');
    }
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    print('RemoveOverlay: Overlay removed');
  }

  void _selectItem(String item) {
    widget.onChanged(item);
    _removeOverlay();
    print('SelectItem: Selected $item, Focus: ${_focusNode.hasFocus}');
  }

  OverlayEntry _createOverlayEntry() {
    RenderBox renderBox = _key.currentContext!.findRenderObject() as RenderBox;
    Size size = renderBox.size;
    Offset position = renderBox.localToGlobal(Offset.zero);

    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final keyboardHeight = mediaQuery.viewInsets.bottom;
    final padding = mediaQuery.padding;
    final availableSpaceBelow = screenHeight - position.dy - size.height - padding.bottom - keyboardHeight;
    final availableSpaceAbove = position.dy - padding.top;
    const fixedDropdownHeight = 200.0;

    // Force upward opening for lower elements
    bool openAbove = position.dy > screenHeight / 2 || availableSpaceBelow < fixedDropdownHeight;

    return OverlayEntry(
      builder: (context) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          _removeOverlay();
          FocusScope.of(context).unfocus();
        },
        child: Container(
          color: Colors.transparent,
          child: Stack(
            children: [
              Positioned(
                width: size.width,
                child: CompositedTransformFollower(
                  link: _layerLink,
                  showWhenUnlinked: false,
                  offset: Offset(0, openAbove ? -(fixedDropdownHeight + 4) : size.height + 4),
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
                              TextField(
                                controller: _searchController,
                                focusNode: _focusNode,
                                decoration: const InputDecoration(
                                  hintText: 'Search...',
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                ),
                                onChanged: (query) {
                                  print('OnChanged: Query: $query, Focus: ${_focusNode.hasFocus}');
                                  if (_debounce?.isActive ?? false) _debounce?.cancel();
                                  _debounce = Timer(const Duration(milliseconds: 300), () {
                                    setState(() {
                                      _filteredItems = widget.items
                                          .where((item) => item.toLowerCase().contains(query.toLowerCase()))
                                          .toSet()
                                          .toList();
                                      print('Debounce: Filtered to ${_filteredItems.length} items, Focus: ${_focusNode.hasFocus}');
                                    });
                                  });
                                },
                                onSubmitted: (_) => _focusNode.requestFocus(),
                              ),
                              const SizedBox(height: 4),
                              Expanded(
                                child: Scrollbar(
                                  child: ListView.builder(
                                    padding: EdgeInsets.zero,
                                    itemCount: _filteredItems.length,
                                    itemBuilder: (context, index) {
                                      final item = _filteredItems[index];
                                      return ListTile(
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
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
            ],
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
            hintText: widget.value.isEmpty ? widget.label : null,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            suffixIcon: Icon(
              _overlayEntry == null ? Icons.arrow_drop_down : Icons.arrow_drop_up,
            ),
          ),
          child: Text(
            widget.value.isEmpty ? '' : widget.value,
            style: TextStyle(
              color: widget.value.isEmpty ? Colors.grey : Colors.black,
            ),
          ),
        ),
      ),
    );
  }
}