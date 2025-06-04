import 'dart:async';
import 'dart:developer';

import 'package:food_manager/data/database/schema/product_schema.dart';
import 'package:food_manager/data/database/schema/tag_schema.dart';
import 'package:food_manager/data/database/schema/unit_schema.dart';
import 'package:food_manager/domain/models/tag.dart';

import '../../core/result/repo_result.dart';
import '../../data/services/database/database_service.dart';

sealed class TagEvent {}

class TagAdded extends TagEvent {
  final Tag tag;
  TagAdded(this.tag);
}

class TagModified extends TagEvent {
  final Tag tag;
  TagModified(this.tag);
}

class TagDeleted extends TagEvent {
  final int tagId;
  TagDeleted(this.tagId);
}

class TagRepository{
  final  DatabaseService _db;
  final _tagUpdates = StreamController<TagEvent>.broadcast();

  Stream<TagEvent> get tagUpdates => _tagUpdates.stream;

  TagRepository(this._db);

  void dispose() {
    _tagUpdates.close();
  }

  Map<String, dynamic> _tagToMap(Tag tag) {
    return {
      TagSchema.id: tag.id,
      TagSchema.name: tag.name,
    };
  }

  Tag _tagFromMap(Map<String, dynamic> tagMap) {
    return Tag(
      id: tagMap[TagSchema.id] as int,
      name: tagMap[TagSchema.name] as String,
    );
  }


  Future<RepoResult<List<Tag>>> listTags() async {
    try {
      final rows = await _db.query(TagSchema.table);
      final results = rows.map((row) => _tagFromMap(row)).toList();

      return RepoSuccess(results);
    } catch (e, s) {
      log(
        'Unexpected error when fetching all tags.',
        name: 'TagRepository',
        error: e,
        stackTrace: s,
        level: 1200,
      );
      return RepoError('Unexpected error when fetching all tag: $e');
    }
  }

  Future<RepoResult<Map<Tag, List<String>>>> getTagUnitsMap() async {
    const String unitNameColumn = 'unit_name_column';
    const String unitTable = 'unit_table';
    const String productTable = 'product_table';
    const String tagTable = 'tag_table';

    try {
      final rows = await _db.rawQuery('''
        SELECT 
          $tagTable.*,
          $unitTable.${UnitSchema.name} AS $unitNameColumn
        FROM ${TagSchema.table} $tagTable
        LEFT OUTER JOIN ${ProductSchema.table} $productTable
          ON $tagTable.${TagSchema.id} = $productTable.${ProductSchema.tagId}
        LEFT OUTER JOIN ${UnitSchema.table} $unitTable
          ON $productTable.${ProductSchema.id} = $unitTable.${UnitSchema.productId}
      ''');

      final tagUnitsMap = <Tag, List<String>>{};

      for (final row in rows) {
        final tag = _tagFromMap(row);

        tagUnitsMap.putIfAbsent(tag, () => []);
        tagUnitsMap[tag]!.add(row[unitNameColumn] as String);
      }

      return RepoSuccess(tagUnitsMap);
    } catch (e, s) {
      log(
        'Unexpected error when fetching tag-units map.',
        name: 'TagRepository',
        error: e,
        stackTrace: s,
        level: 1200,
      );
      return RepoError('Unexpected error when fetching all tag: $e');
    }
  }
}
