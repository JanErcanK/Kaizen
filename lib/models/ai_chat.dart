import 'dart:math';

import 'food_nutrients.dart';

String newChatId() =>
    '${DateTime.now().microsecondsSinceEpoch}_${Random.secure().nextInt(1 << 32)}';

enum AiProvider {
  openai('OpenAI', 'gpt-5.4-mini'),
  claude('Claude', 'claude-haiku-4-5');

  const AiProvider(this.label, this.defaultModel);
  final String label;
  final String defaultModel;

  static AiProvider parse(String? value) =>
      values.where((p) => p.name == value).firstOrNull ?? openai;
}

/// Nutrients are totals for the stated portion, never values per 100 g.
class MealFood {
  const MealFood({
    required this.name,
    required this.grams,
    required this.proteinG,
    required this.carbsG,
    required this.fatsG,
  });

  final String name;
  final double grams, proteinG, carbsG, fatsG;
  FoodNutrients get nutrients =>
      FoodNutrients(proteinG: proteinG, carbsG: carbsG, fatsG: fatsG);

  bool get isValid =>
      name.trim().isNotEmpty &&
      name.length <= 160 &&
      grams.isFinite &&
      grams > 0 &&
      grams <= 10000 &&
      [proteinG, carbsG, fatsG].every((v) => v.isFinite && v >= 0) &&
      proteinG + carbsG + fatsG <= grams * 1.05;

  MealFood scaledTo(double amount) => MealFood(
    name: name,
    grams: amount,
    proteinG: proteinG * amount / grams,
    carbsG: carbsG * amount / grams,
    fatsG: fatsG * amount / grams,
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'grams': grams,
    'proteinG': proteinG,
    'carbsG': carbsG,
    'fatsG': fatsG,
  };

  factory MealFood.fromJson(Map<String, dynamic> json) {
    double number(String key) {
      final v = json[key];
      if (v is! num) throw const FormatException('Invalid meal number');
      return v.toDouble();
    }

    final food = MealFood(
      name: json['name'] as String,
      grams: number('grams'),
      proteinG: number('proteinG'),
      carbsG: number('carbsG'),
      fatsG: number('fatsG'),
    );
    if (!food.isValid) throw const FormatException('Invalid meal portion');
    return food;
  }
}

class MealDraft {
  const MealDraft({
    required this.name,
    required this.foods,
    required this.assumptions,
    this.recipe = '',
  });
  final String name, assumptions, recipe;
  final List<MealFood> foods;
  FoodNutrients get totals =>
      foods.fold(const FoodNutrients(), (sum, food) => sum + food.nutrients);
  Map<String, dynamic> toJson() => {
    'name': name,
    'assumptions': assumptions,
    'recipe': recipe,
    'foods': foods.map((f) => f.toJson()).toList(),
  };
  factory MealDraft.fromJson(Map<String, dynamic> json) {
    final foods = (json['foods'] as List)
        .map((f) => MealFood.fromJson(Map<String, dynamic>.from(f as Map)))
        .toList();
    if (foods.isEmpty || foods.length > 30) {
      throw const FormatException('Invalid meal size');
    }
    return MealDraft(
      name: json['name'] as String,
      foods: foods,
      assumptions: json['assumptions'] as String,
      recipe: json['recipe']?.toString() ?? '',
    );
  }
}

enum AiChatActionType {
  saveDish,
  logMeal,
  deleteFoodEntries,
  replaceFoodEntries,
  saveWorkout,
  logWorkout,
  saveShoppingList,
  remember,
  readFitnessData,
}

class AiWorkoutExercise {
  const AiWorkoutExercise({
    required this.name,
    required this.sets,
    required this.reps,
    required this.mainGroup,
    required this.secondaryMuscles,
    this.evidence = '',
    this.restSeconds = 60,
    this.sourceVideoId = '',
    this.startSeconds = 0,
    this.endSeconds = 0,
  });

  final String name;
  final int sets, reps;
  final String mainGroup;
  final List<String> secondaryMuscles;
  final String evidence;
  final int restSeconds;
  final String sourceVideoId;
  final double startSeconds, endSeconds;

  Map<String, dynamic> toJson() => {
    'name': name,
    'sets': sets,
    'reps': reps,
    'mainGroup': mainGroup,
    'secondaryMuscles': secondaryMuscles,
    'evidence': evidence,
    'restSeconds': restSeconds,
    'sourceVideoId': sourceVideoId,
    'startSeconds': startSeconds,
    'endSeconds': endSeconds,
  };

  Map<String, dynamic> toWorkoutMap() => {
    'name': name,
    'sets': sets,
    'reps': reps,
    'setReps': List<int>.filled(sets, reps),
    'mainGroup': mainGroup,
    'tags': secondaryMuscles,
    'description': evidence,
    'restSeconds': restSeconds,
  };

  factory AiWorkoutExercise.fromJson(Map<String, dynamic> json) {
    const groups = {
      'Brust',
      'Rücken',
      'Schultern',
      'Bizeps',
      'Trizeps',
      'Bauch',
      'Beine',
      'Unterarme',
      'Nacken',
    };
    final name = (json['name'] as String).trim();
    final sets = (json['sets'] as num).toInt();
    final reps = (json['reps'] as num).toInt();
    final mainGroup = json['mainGroup'] as String;
    final secondary = (json['secondaryMuscles'] as List)
        .whereType<String>()
        .toSet()
        .toList();
    if (name.isEmpty ||
        name.length > 160 ||
        sets < 1 ||
        sets > 100 ||
        reps < 1 ||
        reps > 999 ||
        !groups.contains(mainGroup) ||
        secondary.any((group) => !groups.contains(group))) {
      throw const FormatException('Invalid workout exercise');
    }
    return AiWorkoutExercise(
      name: name,
      sets: sets,
      reps: reps,
      mainGroup: mainGroup,
      secondaryMuscles: secondary,
      restSeconds: ((json['restSeconds'] as num?)?.toInt() ?? 60).clamp(0, 600),
      sourceVideoId: json['sourceVideoId'] as String? ?? '',
      startSeconds: (json['startSeconds'] as num?)?.toDouble() ?? 0,
      endSeconds: (json['endSeconds'] as num?)?.toDouble() ?? 0,
      evidence: (json['evidence'] as String? ?? '').substring(
        0,
        (json['evidence'] as String? ?? '').length.clamp(0, 1200),
      ),
    );
  }
}

class AiChatAction {
  const AiChatAction({
    required this.type,
    this.meal,
    this.workoutName = '',
    this.workoutCategory = 'calisthenics',
    this.durationMinutes = 0,
    this.exercises = const [],
    this.targetId = '',
    this.entryIds = const [],
    this.shoppingName = '',
    this.shoppingItems = const [],
    this.memory = '',
    this.dataSection = '',
    this.dataOffset = 0,
    this.dataSearch = '',
  });

  final AiChatActionType type;
  final MealDraft? meal;
  final String workoutName, workoutCategory;
  final int durationMinutes;
  final List<AiWorkoutExercise> exercises;
  final String targetId, shoppingName, memory, dataSection;
  final List<String> entryIds;
  final List<String> shoppingItems;
  final int dataOffset;
  final String dataSearch;
  bool get needsReview =>
      entryIds.isNotEmpty ||
      type == AiChatActionType.saveShoppingList ||
      type == AiChatActionType.remember ||
      targetId.isNotEmpty;
  Map<String, dynamic> toJson() => {
    'type': switch (type) {
      AiChatActionType.saveDish => 'save_dish',
      AiChatActionType.logMeal => 'log_meal',
      AiChatActionType.deleteFoodEntries => 'delete_food_entries',
      AiChatActionType.replaceFoodEntries => 'replace_food_entries',
      AiChatActionType.saveWorkout => 'save_workout',
      AiChatActionType.logWorkout => 'log_workout',
      AiChatActionType.saveShoppingList => 'save_shopping_list',
      AiChatActionType.remember => 'remember',
      AiChatActionType.readFitnessData => 'read_fitness_data',
    },
    'mealName': meal?.name ?? '',
    'recipe': meal?.recipe ?? '',
    'assumptions': meal?.assumptions ?? '',
    'foods': meal?.foods.map((f) => f.toJson()).toList() ?? [],
    'workoutName': workoutName,
    'workoutCategory': workoutCategory,
    'durationMinutes': durationMinutes,
    'exercises': exercises.map((e) => e.toJson()).toList(),
    'targetId': targetId,
    'entryIds': entryIds,
    'shoppingName': shoppingName,
    'shoppingItems': shoppingItems,
    'memory': memory,
    'dataSection': dataSection,
    'dataOffset': dataOffset,
    'dataSearch': dataSearch,
  };

  factory AiChatAction.fromJson(Map<String, dynamic> json) {
    final targetId = json['targetId'] as String? ?? '';
    if (targetId.length > 160) throw const FormatException('Invalid target');
    switch (json['type']) {
      case 'delete_food_entries':
      case 'replace_food_entries':
        final ids = (json['entryIds'] as List).cast<String>();
        if (ids.isEmpty ||
            ids.length > 60 ||
            ids.toSet().length != ids.length ||
            ids.any((id) => id.trim().isEmpty || id.length > 160)) {
          throw const FormatException('Invalid food entry IDs');
        }
        return AiChatAction(
          type: json['type'] == 'delete_food_entries'
              ? AiChatActionType.deleteFoodEntries
              : AiChatActionType.replaceFoodEntries,
          entryIds: ids,
          meal: json['type'] == 'replace_food_entries'
              ? MealDraft.fromJson({
                  'name': json['mealName'],
                  'assumptions': json['assumptions'],
                  'recipe': json['recipe'],
                  'foods': json['foods'],
                })
              : null,
        );
      case 'read_fitness_data':
        final section = json['dataSection'] as String? ?? '';
        final offset = (json['dataOffset'] as num? ?? 0).toInt();
        if (offset < 0 ||
            offset > 100000 ||
            !{
              'trainingAnalysis',
              'workouts',
              'workoutHistory',
              'dishes',
              'nutrition',
              'weight',
              'shopping',
              'health',
              'routes',
              'supplements',
            }.contains(section)) {
          throw const FormatException('Invalid data request');
        }
        final search = json['dataSearch'] as String? ?? '';
        if (search.length > 160) throw const FormatException('Invalid search');
        return AiChatAction(
          type: AiChatActionType.readFitnessData,
          dataSection: section,
          dataOffset: offset,
          dataSearch: search,
        );
      case 'remember':
        final memory = (json['memory'] as String? ?? '').trim();
        if (memory.isEmpty || memory.length > 600) {
          throw const FormatException('Invalid memory');
        }
        return AiChatAction(type: AiChatActionType.remember, memory: memory);
      case 'save_shopping_list':
        final name = (json['shoppingName'] as String? ?? '').trim();
        final items = (json['shoppingItems'] as List).cast<String>();
        if (name.isEmpty ||
            name.length > 120 ||
            items.isEmpty ||
            items.length > 80 ||
            items.any((s) => s.trim().isEmpty || s.length > 240)) {
          throw const FormatException('Invalid shopping list');
        }
        return AiChatAction(
          type: AiChatActionType.saveShoppingList,
          targetId: targetId,
          shoppingName: name,
          shoppingItems: items,
        );
      case 'save_dish':
      case 'log_meal':
        final foods = json['foods'] as List;
        return AiChatAction(
          type: json['type'] == 'save_dish'
              ? AiChatActionType.saveDish
              : AiChatActionType.logMeal,
          meal: MealDraft.fromJson({
            'name': json['mealName'],
            'assumptions': json['assumptions'],
            'recipe': json['recipe'],
            'foods': foods,
          }),
          targetId: targetId,
        );
      case 'save_workout':
      case 'log_workout':
        final category = json['workoutCategory'] as String;
        final duration = (json['durationMinutes'] as num).toInt();
        final exercises = (json['exercises'] as List)
            .map(
              (raw) => AiWorkoutExercise.fromJson(
                Map<String, dynamic>.from(raw as Map),
              ),
            )
            .toList();
        final name = (json['workoutName'] as String).trim();
        final totalReps = exercises.fold<int>(
          0,
          (sum, exercise) => sum + exercise.sets * exercise.reps,
        );
        if (name.isEmpty ||
            name.length > 120 ||
            !{'gym', 'calisthenics'}.contains(category) ||
            duration < 1 ||
            duration > 360 ||
            exercises.isEmpty ||
            exercises.length > 30 ||
            totalReps > 100000) {
          throw const FormatException('Invalid workout action');
        }
        return AiChatAction(
          type: json['type'] == 'save_workout'
              ? AiChatActionType.saveWorkout
              : AiChatActionType.logWorkout,
          workoutName: name,
          workoutCategory: category,
          durationMinutes: duration,
          exercises: exercises,
          targetId: targetId,
        );
      default:
        throw const FormatException('No action');
    }
  }
}

class ChatMessage {
  ChatMessage({
    required this.id,
    required this.role,
    required this.text,
    required this.createdAt,
    this.imageName,
    this.imageMime,
    this.meal,
    this.loggedAt,
    this.failed = false,
    this.frames = const [],
    this.videoSource,
    this.proposal,
    this.actionSaved = false,
    this.proposalSuperseded = false,
    this.sharedImportId,
  });
  final String id, role;
  String text;
  final DateTime createdAt;
  final String? imageName, imageMime;
  MealDraft? meal;
  DateTime? loggedAt;
  bool failed;
  final List<ChatFrame> frames;
  final String? videoSource, sharedImportId;
  AiChatAction? proposal;
  bool actionSaved, proposalSuperseded;
  Map<String, dynamic> toJson() => {
    'id': id,
    'role': role,
    'text': text,
    'createdAt': createdAt.toIso8601String(),
    'imageName': imageName,
    'imageMime': imageMime,
    'meal': meal?.toJson(),
    'loggedAt': loggedAt?.toIso8601String(),
    'failed': failed,
    'frames': frames.map((f) => f.toJson()).toList(),
    'videoSource': videoSource,
    'sharedImportId': sharedImportId,
    'proposal': proposal?.toJson(),
    'actionSaved': actionSaved,
    'proposalSuperseded': proposalSuperseded,
  };
  factory ChatMessage.fromJson(Map<String, dynamic> j) => ChatMessage(
    id: j['id'] as String,
    role: j['role'] as String,
    text: j['text'] as String,
    createdAt: DateTime.parse(j['createdAt'] as String),
    imageName: j['imageName'] as String?,
    imageMime: j['imageMime'] as String?,
    meal: j['meal'] == null
        ? null
        : MealDraft.fromJson(Map<String, dynamic>.from(j['meal'] as Map)),
    loggedAt: DateTime.tryParse(j['loggedAt']?.toString() ?? ''),
    failed: j['failed'] == true,
    frames: (j['frames'] as List? ?? [])
        .map((f) => ChatFrame.fromJson(Map<String, dynamic>.from(f as Map)))
        .toList(),
    videoSource: j['videoSource'] as String?,
    sharedImportId: j['sharedImportId'] as String?,
    proposal: j['proposal'] is Map
        ? AiChatAction.fromJson(Map<String, dynamic>.from(j['proposal'] as Map))
        : null,
    actionSaved: j['actionSaved'] == true,
    proposalSuperseded: j['proposalSuperseded'] == true,
  );
}

class ChatFrame {
  const ChatFrame({
    required this.imageName,
    required this.seconds,
    this.slideNumber,
    this.videoId,
    this.videoDuration,
  });
  final String imageName;
  final double seconds;
  final int? slideNumber;
  final String? videoId;
  final double? videoDuration;
  Map<String, dynamic> toJson() => {
    'imageName': imageName,
    'seconds': seconds,
    if (slideNumber != null) 'slideNumber': slideNumber,
    if (videoId != null) 'videoId': videoId,
    if (videoDuration != null) 'videoDuration': videoDuration,
  };
  factory ChatFrame.fromJson(Map<String, dynamic> json) => ChatFrame(
    imageName: json['imageName'] as String,
    seconds: (json['seconds'] as num).toDouble(),
    slideNumber: json['slideNumber'] as int?,
    videoId: json['videoId'] as String?,
    videoDuration: (json['videoDuration'] as num?)?.toDouble(),
  );
}

class ChatConversation {
  ChatConversation({
    required this.id,
    required this.provider,
    required this.model,
    required this.title,
    required this.messages,
  });
  final String id;
  final AiProvider provider;
  final String model;
  String title;
  final List<ChatMessage> messages;
  Map<String, dynamic> toJson() => {
    'id': id,
    'provider': provider.name,
    'model': model,
    'title': title,
    'messages': messages.map((m) => m.toJson()).toList(),
  };
  factory ChatConversation.fromJson(Map<String, dynamic> j) => ChatConversation(
    id: j['id'] as String,
    provider: AiProvider.parse(j['provider'] as String?),
    model: j['model'] as String,
    title: j['title'] as String,
    messages: (j['messages'] as List)
        .map((m) => ChatMessage.fromJson(Map<String, dynamic>.from(m as Map)))
        .toList(),
  );
}
