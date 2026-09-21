final class AppDropdownOption<T> {
  const AppDropdownOption({
    required this.value,
    required this.label,
    this.enabled = true,
  });
  final T? value;
  final String label;
  final bool enabled;
}
