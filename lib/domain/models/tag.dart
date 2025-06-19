class Tag {
  // name is used as a primary identifier outside of contexts
  // when we clearly want to change the name of an existing tag
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
