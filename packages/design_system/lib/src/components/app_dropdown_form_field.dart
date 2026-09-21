import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_dropdown_option.dart';
import '../tokens/app_spacing.dart';

final class AppDropdownFormField<T> extends FormField<T> {
  AppDropdownFormField({
    required this.items,
    required this.onChanged,
    this.decoration = const InputDecoration(),
    super.initialValue,
    super.validator,
    super.onSaved,
    super.autovalidateMode,
    super.key,
  }) : super(
         enabled: onChanged != null && items.any((item) => item.enabled),
         builder: (state) =>
             (state as _AppDropdownFormFieldState<T>)._buildField(),
       );

  final List<AppDropdownOption<T>> items;
  final ValueChanged<T?>? onChanged;
  final InputDecoration decoration;

  @override
  FormFieldState<T> createState() => _AppDropdownFormFieldState<T>();
}

class _AppDropdownFormFieldState<T> extends FormFieldState<T> {
  final _controller = TextEditingController();
  MenuController? _menuController;
  AppDropdownFormField<T> get _field => widget as AppDropdownFormField<T>;

  @override
  void initState() {
    super.initState();
    _syncLabel();
  }

  void _syncLabel() {
    final label =
        _field.items.where((item) => item.value == value).firstOrNull?.label ??
        '';
    if (_controller.text != label) _controller.text = label;
  }

  @override
  void didUpdateWidget(covariant AppDropdownFormField<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue) {
      setValue(widget.initialValue);
    }
    _syncLabel();
  }

  @override
  void reset() {
    super.reset();
    _syncLabel();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildField() {
    final theme = Theme.of(context);
    final decoration = _field.decoration;
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onKeyEvent: (_, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.escape &&
            _menuController?.isOpen == true) {
          _menuController!.close();
          _syncLabel();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: TapRegion(
        onTapOutside: (_) => _syncLabel(),
        child: LayoutBuilder(
          builder: (context, constraints) => DropdownMenu<T?>(
            controller: _controller,
            trailingIcon: Builder(
              builder: (context) {
                _menuController = MenuController.maybeOf(context);
                return const Icon(Icons.arrow_drop_down);
              },
            ),
            enabled: widget.enabled,
            initialSelection: value,
            expandedInsets: EdgeInsets.zero,
            menuStyle: MenuStyle(
              maximumSize: WidgetStatePropertyAll(
                Size(constraints.maxWidth, AppSpacing.menuMaxHeight),
              ),
            ),
            requestFocusOnTap: false,
            enableSearch: false,
            textStyle: theme.textTheme.bodyLarge,
            inputDecorationTheme: theme.inputDecorationTheme,
            label:
                decoration.label ??
                (decoration.labelText == null
                    ? null
                    : Text(decoration.labelText!)),
            leadingIcon: decoration.prefixIcon,
            helperText: decoration.helperText,
            hintText: decoration.hintText,
            errorText: errorText ?? decoration.errorText,
            dropdownMenuEntries: [
              for (final item in _field.items)
                DropdownMenuEntry<T?>(
                  value: item.value,
                  label: item.label,
                  labelWidget: Text(item.label),
                  enabled: item.enabled,
                  trailingIcon: item.value == value
                      ? const Icon(Icons.check, size: 20)
                      : null,
                ),
            ],
            onSelected: (selected) {
              didChange(selected);
              _syncLabel();
              _field.onChanged?.call(selected);
            },
          ),
        ),
      ),
    );
  }
}
