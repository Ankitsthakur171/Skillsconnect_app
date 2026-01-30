import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../Model/LanguageMaster_Model.dart';

class CustomFieldLanguageDropdown<T> extends StatefulWidget {
  final List<T> items;
  final T? value;
  final ValueChanged<T?> onChanged;
  final String hintText;
  final ScrollController? scrollController;
  final VoidCallback? onLoadMore;

  const CustomFieldLanguageDropdown(
      this.items,
      this.value,
      this.onChanged, {
        super.key,
        this.hintText = 'Please select',
        this.scrollController,
        this.onLoadMore,
      });

  @override
  State<CustomFieldLanguageDropdown<T>> createState() =>
      _CustomFieldLanguageDropdownState<T>();
}

class _CustomFieldLanguageDropdownState<T>
    extends State<CustomFieldLanguageDropdown<T>> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  late TextEditingController _searchController;
  late List<T> _filteredItems;
  final GlobalKey _key = GlobalKey();
  final FocusNode _focusNode = FocusNode();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    // remove nulls and duplicate items
    _filteredItems = widget.items.whereType<T>().toSet().toList();
    _focusNode.addListener(_handleFocusChange);
    print(
        'Init: FocusNode created, hasFocus: ${_focusNode.hasFocus}, Items: ${widget.items.length}, Filtered: ${_filteredItems.length}');
  }

  @override
  void didUpdateWidget(CustomFieldLanguageDropdown<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update filtered items when widget items change (pagination)
    if (oldWidget.items.length != widget.items.length) {
      _filteredItems = widget.items.whereType<T>().toSet().toList();
      print('didUpdateWidget: Items updated from ${oldWidget.items.length} to ${widget.items.length}, Filtered: ${_filteredItems.length}');
    }
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
    if (_focusNode.hasFocus &&
        _overlayEntry == null &&
        _filteredItems.isNotEmpty) {
      _toggleDropdown();
    } else if (!_focusNode.hasFocus && _overlayEntry != null) {
      _removeOverlay();
    }
  }

  void _toggleDropdown() {
    if (_overlayEntry == null && _filteredItems.isNotEmpty) {
      _filteredItems = widget.items.whereType<T>().toSet().toList();
      _searchController.clear();
      _overlayEntry = _createOverlayEntry();
      Overlay.of(context)?.insert(_overlayEntry!);
      _focusNode.requestFocus();
      print(
          'ToggleDropdown: Overlay created, Focus requested: ${_focusNode.hasFocus}, Items: ${_filteredItems.length}');
    } else if (_filteredItems.isEmpty) {
      print('⚠️ Cannot toggle dropdown: No items available');
    } else {
      _removeOverlay();
    }
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    print('RemoveOverlay: Overlay removed');
  }

  void _selectItem(T? item) {
    if (item != null) {
      widget.onChanged(item);
      _removeOverlay();
      print('SelectItem: Selected $item, Focus: ${_focusNode.hasFocus}');
    } else {
      // Should not happen, but be defensive
      print('SelectItem: attempted select null item, ignored');
    }
  }

  OverlayEntry _createOverlayEntry() {
    RenderBox? renderBox =
    _key.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) {
      print('⚠️ RenderBox is null, cannot create overlay');
      return OverlayEntry(builder: (_) => const SizedBox.shrink());
    }

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
    const fixedDropdownHeight = 300.0;

    bool openAbove = position.dy > screenHeight / 2 ||
        availableSpaceBelow < fixedDropdownHeight;

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
                  offset: Offset(
                      0, openAbove ? -(fixedDropdownHeight + 4) : size.height + 4),
                  child: StatefulBuilder(
                    builder: (context, setState) {
                      return Material(
                        elevation: 4,
                        borderRadius: BorderRadius.circular(4),
                        child: Container(
                          width: size.width,
                          height: fixedDropdownHeight,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Uncomment to enable search inside dropdown
                              TextField(
                                controller: _searchController,
                                decoration: InputDecoration(
                                  hintText: 'Search...',
                                  isDense: true,
                                  border: const OutlineInputBorder(),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                                ),
                                onChanged: (query) {
                                  if (_debounce?.isActive ?? false) _debounce?.cancel();
                                  _debounce = Timer(const Duration(milliseconds: 300), () {
                                    setState(() {
                                      _filteredItems = widget.items
                                          .whereType<T>()
                                          .where((item) => _getDisplayText(item).toLowerCase().contains(query.toLowerCase()))
                                          .toSet()
                                          .toList();
                                    });
                                  });
                                },
                              ),
                              const SizedBox(height: 4),
                              Expanded(
                                child: _filteredItems.isEmpty
                                    ? const Center(child: Text('No items available'))
                                    : widget.scrollController != null
                                        ? Scrollbar(
                                            controller: widget.scrollController,
                                            thumbVisibility: true,
                                            child: ListView.builder(
                                              controller: widget.scrollController,
                                              padding: EdgeInsets.zero,
                                              itemCount: _filteredItems.length,
                                              itemBuilder: (context, index) {
                                                final item = _filteredItems[index];
                                                String displayText = _getDisplayText(item);
                                                return ListTile(
                                                  contentPadding:
                                                  const EdgeInsets.symmetric(horizontal: 8),
                                                  dense: true,
                                                  title: Text(displayText, overflow: TextOverflow.ellipsis),
                                                  onTap: () => _selectItem(item),
                                                  selected: widget.value == item,
                                                  selectedTileColor: Colors.blue.shade50,
                                                );
                                              },
                                            ),
                                          )
                                        : ListView.builder(
                                            padding: EdgeInsets.zero,
                                            itemCount: _filteredItems.length,
                                            itemBuilder: (context, index) {
                                              final item = _filteredItems[index];
                                              String displayText = _getDisplayText(item);
                                              return ListTile(
                                                contentPadding:
                                                const EdgeInsets.symmetric(horizontal: 8),
                                                dense: true,
                                                title: Text(displayText, overflow: TextOverflow.ellipsis),
                                                onTap: () => _selectItem(item),
                                                selected: widget.value == item,
                                                selectedTileColor: Colors.blue.shade50,
                                              );
                                            },
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

  String _getDisplayText(dynamic item) {
    if (item == null) return '';
    try {
      if (item is LanguageMasterModel) return item.languageName ?? '';
    } catch (_) {}
    if (item is String) return item;
    return item.toString();
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
            hintText: widget.value == null ? widget.hintText : null,
            border: const OutlineInputBorder(),
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            suffixIcon: Icon(
              _overlayEntry == null ? Icons.arrow_drop_down : Icons.arrow_drop_up,
              color: Colors.grey[700],
              size: 24,
            ),
            errorText: _filteredItems.isEmpty ? 'No items available' : null,
          ),
          child: Text(
            // SAFE: only display when value is non-null; otherwise display hint
            widget.value != null ? _getDisplayText(widget.value as T) : widget.hintText,
            style: TextStyle(
              color: widget.value == null ? Colors.grey : Colors.black,
            ),
          ),
        ),
      ),
    );
  }

}
