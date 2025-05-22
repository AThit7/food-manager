class Tag {
  final int? id;
  final String name;

  const Tag({
    required this.name,
    this.id,
  });

  Tag copyWith({int? id}) {
    return Tag(
      id: id ?? this.id,
      name: name,
    );
  }
}
