import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'notification_icon_widget.dart';

/// Improved search bar with notification icon
class ImprovedSearchBar extends StatefulWidget {
  final Function(String)? onSearch;
  final String? hintText;
  final bool showNotificationIcon;

  const ImprovedSearchBar({
    super.key,
    this.onSearch,
    this.hintText,
    this.showNotificationIcon = true,
  });

  @override
  State<ImprovedSearchBar> createState() => _ImprovedSearchBarState();
}

class _ImprovedSearchBarState extends State<ImprovedSearchBar> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Search Bar
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: _isFocused
                    ? [
                        BoxShadow(
                          color: const Color.fromRGBO(24, 95, 45, 1).withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                border: Border.all(
                  color: _isFocused
                      ? const Color.fromRGBO(24, 95, 45, 1)
                      : Colors.grey[300]!,
                  width: _isFocused ? 2 : 1,
                ),
              ),
              child: TextField(
                controller: _searchController,
                focusNode: _focusNode,
                onChanged: (value) {
                  widget.onSearch?.call(value);
                },
                onSubmitted: (value) {
                  widget.onSearch?.call(value);
                },
                decoration: InputDecoration(
                  hintText: widget.hintText ?? 'Search products, categories...',
                  hintStyle: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 14,
                  ),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: FaIcon(
                      FontAwesomeIcons.magnifyingGlass,
                      color: _isFocused
                          ? const Color.fromRGBO(24, 95, 45, 1)
                          : Colors.grey[600],
                      size: 18,
                    ),
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.clear,
                            color: Colors.grey[600],
                            size: 20,
                          ),
                          onPressed: () {
                            _searchController.clear();
                            widget.onSearch?.call('');
                            setState(() {});
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
            ),
          ),
          
          // Notification Icon
          if (widget.showNotificationIcon) ...[
            const SizedBox(width: 12),
            const NotificationIconWidget(),
          ],
        ],
      ),
    );
  }
}
