enum SupportCategory {
  account('Tài khoản'),
  listing('Đăng vật phẩm'),
  receiving('Nhận vật phẩm'),
  group('Hội nhóm'),
  report('Báo cáo vi phạm'),
  other('Khác');

  final String label;

  const SupportCategory(this.label);
}
