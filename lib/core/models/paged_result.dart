/// Shared pagination wrapper. Feature DTOs stay in their own `models/` folders.
class PagedResult<T> {
  const PagedResult({
    required this.items,
    required this.page,
    required this.total,
  });

  final List<T> items;
  final int page;
  final int total;

  bool get hasMore => items.length < total;
}
