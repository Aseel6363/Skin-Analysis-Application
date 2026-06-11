import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/product_model.dart';
import '../models/skin_analysis_result.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('glowup.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(
      path,
      version: 4, // ✅ version 4 adds userId column to analysis_sessions
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // Products table (shared)
    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        brand TEXT NOT NULL,
        category TEXT NOT NULL,
        description TEXT,
        imageUrl TEXT,
        suitableSkinTypes TEXT NOT NULL,
        targetConditions TEXT NOT NULL,
        rating REAL,
        reviewCount INTEGER
      )
    ''');

    // Analysis sessions table WITH userId column
    await db.execute('''
      CREATE TABLE analysis_sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId TEXT NOT NULL,
        analysisData TEXT NOT NULL,
        analysisDate TEXT NOT NULL,
        skinType TEXT NOT NULL,
        skinTone TEXT,
        undertone TEXT,
        confidenceScore REAL,
        summary TEXT,
        photoUrl TEXT
      )
    ''');

    // Beauty products table (shared)
    await db.execute('''
      CREATE TABLE beauty_products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        brand TEXT NOT NULL,
        category TEXT NOT NULL,
        shade TEXT,
        skinTone TEXT NOT NULL,
        undertone TEXT NOT NULL,
        imageUrl TEXT,
        description TEXT
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE analysis_sessions (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          analysisData TEXT NOT NULL,
          analysisDate TEXT NOT NULL,
          skinType TEXT NOT NULL,
          skinTone TEXT,
          undertone TEXT,
          confidenceScore REAL,
          summary TEXT,
          photoUrl TEXT
        )
      ''');
    }
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE beauty_products (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          brand TEXT NOT NULL,
          category TEXT NOT NULL,
          shade TEXT,
          skinTone TEXT NOT NULL,
          undertone TEXT NOT NULL,
          imageUrl TEXT,
          description TEXT
        )
      ''');
    }
    // ✅ Upgrade to version 4: add userId column to analysis_sessions
    if (oldVersion < 4) {
      await db.execute('ALTER TABLE analysis_sessions ADD COLUMN userId TEXT');
      // Set a default userId for existing rows (e.g., 'unknown')
      await db.execute(
        'UPDATE analysis_sessions SET userId = "unknown" WHERE userId IS NULL',
      );
    }
  }

  // --- Product Methods (shared) ---

  Future<int> create(Product product) async {
    final db = await instance.database;
    final map = product.toMap();
    map.remove('id');
    return await db.insert('products', map);
  }

  Future<Product?> readProduct(int id) async {
    final db = await instance.database;
    final maps = await db.query('products', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      return Product.fromMap(maps.first);
    }
    return null;
  }

  Future<List<Product>> readAllProducts() async {
    final db = await instance.database;
    final result = await db.query('products');
    return result.map((json) => Product.fromMap(json)).toList();
  }

  Future<int> update(Product product) async {
    final db = await instance.database;
    return db.update(
      'products',
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await instance.database;
    return await db.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Product>> queryProductsBySkinType(String skinType) async {
    final allProducts = await readAllProducts();
    return allProducts.where((product) {
      return product.suitableSkinTypes.any(
        (type) =>
            type.toLowerCase() == skinType.toLowerCase() ||
            type.toLowerCase() == 'all',
      );
    }).toList();
  }

  // --- Seed Products ---

  Future<void> seedProducts() async {
    final db = await instance.database;
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM products'),
    );

    if (count != null && count > 0) {
      print('✅ Products already exist in database. Skipping seed.');
      return;
    }

    print('🚀 Seeding local database with products...');

    final List<Map<String, dynamic>> products = [
      // --- Cleansers ---
      {
        "name": "Foaming Cleanser",
        "brand": "CeraVe",
        "category": "Cleanser",
        "description":
            "Helps remove excess oil and impurities without drying your skin.",
        "imageUrl": "assets/images/cerave_cleanser.png",
        "suitableSkinTypes": ["Oily", "Combination", "Normal", "Sensitive"],
        "targetConditions": ["Acne", "EnlargedPores"],
      },
      {
        "name": "Hydrating Cleanser",
        "brand": "CeraVe",
        "category": "Cleanser",
        "description":
            "Hydrating cleanser that removes dirt and oil while maintaining the skin barrier.",
        "imageUrl": "assets/images/cerave_hydrating_cleanser.png",
        "suitableSkinTypes": ["Sensitive", "Dry", "Normal"],
        "targetConditions": ["Redness", "Dryness"],
      },
      {
        "name": "Toleriane Gentle Cleanser",
        "brand": "La Roche-Posay",
        "category": "Cleanser",
        "description": "Gentle cleanser for sensitive skin.",
        "imageUrl": "assets/images/toleriane_cleanser.png",
        "suitableSkinTypes": ["Sensitive", "Normal", "Dry"],
        "targetConditions": ["Redness", "Irritation", "Dryness"],
      },
      // --- Serums ---
      {
        "name": "Niacinamide 10% + Zinc 1%",
        "brand": "The Ordinary",
        "category": "Serum",
        "description":
            "Supports oil balance and helps reduce the appearance of pores.",
        "imageUrl": "assets/images/niacinamide_serum.png",
        "suitableSkinTypes": ["Oily", "Combination", "Normal", "Sensitive"],
        "targetConditions": ["Acne", "EnlargedPores"],
      },
      {
        "name": "Vitamin C Serum",
        "brand": "CeraVe",
        "category": "Serum",
        "description": "Brightens skin and targets pigmentation.",
        "imageUrl": "assets/images/vitamin_c_serum.png",
        "suitableSkinTypes": ["Dry", "Normal", "Sensitive"],
        "targetConditions": ["Pigmentation"],
      },
      // --- Moisturizers ---
      {
        "name": "Hydro Boost Water Gel",
        "brand": "Neutrogena",
        "category": "Moisturizer",
        "description":
            "Keeps your skin hydrated while maintaining a light, non-greasy feel.",
        "imageUrl": "assets/images/moisturizer.png",
        "suitableSkinTypes": ["Oily", "Combination", "Normal", "Sensitive"],
        "targetConditions": ["Dryness", "EnlargedPores"],
      },
      {
        "name": "Calm + Restore Oat Gel Moisturizer",
        "brand": "Aveeno",
        "category": "Moisturizer",
        "description":
            "Lightweight gel moisturizer that soothes sensitive skin and reduces redness.",
        "imageUrl": "assets/images/aveeno_moisturizer.png",
        "suitableSkinTypes": ["Sensitive", "Normal", "Combination"],
        "targetConditions": ["Redness", "Irritation", "Dryness"],
      },
      // --- Sunscreens ---
      {
        "name": "Anthelios SPF 50",
        "brand": "La Roche-Posay",
        "category": "Sunscreen",
        "description":
            "Protects your skin from UV damage and helps prevent pigmentation.",
        "imageUrl": "assets/images/sunscreen.png",
        "suitableSkinTypes": ["All", "Normal", "Sensitive"],
        "targetConditions": ["Pigmentation"],
      },
      {
        "name": "Hydrating Mineral Sunscreen SPF 50",
        "brand": "CeraVe",
        "category": "Sunscreen",
        "description":
            "100% mineral sunscreen with SPF 50, safe for sensitive skin.",
        "imageUrl": "assets/images/cerave_hydrating_sunscreen.png",
        "suitableSkinTypes": ["Sensitive", "All"],
        "targetConditions": ["Redness", "Dryness"],
      },
    ];

    for (var product in products) {
      final Product p = Product(
        id: null,
        name: product['name'],
        brand: product['brand'],
        category: product['category'],
        description: product['description'],
        imageUrl: product['imageUrl'],
        suitableSkinTypes: List<String>.from(product['suitableSkinTypes']),
        targetConditions: List<String>.from(product['targetConditions']),
      );
      await create(p);
      print('   ✅ Added: ${p.name}');
    }

    print('🎉 Database seeding complete!');
  }

  // --- Analysis Session Methods (filtered by current user) ---

  Future<void> saveAnalysisSession(SkinAnalysisResult analysis) async {
    final db = await instance.database;
    final userId = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
    await db.insert('analysis_sessions', {
      'userId': userId,
      'analysisData': jsonEncode(analysis.toJson()),
      'analysisDate':
          analysis.analysisDate?.toIso8601String() ??
          DateTime.now().toIso8601String(),
      'skinType': analysis.skinType,
      'skinTone': analysis.skinTone,
      'undertone': analysis.undertone,
      'confidenceScore': analysis.confidenceScore,
      'summary': analysis.summary,
      'photoUrl': analysis.photoUrl,
    });
  }

  Future<SkinAnalysisResult?> getLatestAnalysisSession() async {
    final db = await instance.database;
    final userId = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
    final result = await db.query(
      'analysis_sessions',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'analysisDate DESC',
      limit: 1,
    );
    if (result.isEmpty) return null;
    final data = jsonDecode(result.first['analysisData'] as String);
    return SkinAnalysisResult.fromJson(data);
  }

  Future<List<SkinAnalysisResult>> getAllAnalysisSessions() async {
    final db = await instance.database;
    final userId = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
    final result = await db.query(
      'analysis_sessions',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'analysisDate DESC',
    );
    return result.map((row) {
      final data = jsonDecode(row['analysisData'] as String);
      return SkinAnalysisResult.fromJson(data);
    }).toList();
  }

  Future<void> deleteAnalysisSession(int id) async {
    final db = await instance.database;
    final userId = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
    await db.delete(
      'analysis_sessions',
      where: 'id = ? AND userId = ?',
      whereArgs: [id, userId],
    );
  }

  Future<void> clearAllSessions() async {
    final db = await instance.database;
    final userId = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
    await db.delete(
      'analysis_sessions',
      where: 'userId = ?',
      whereArgs: [userId],
    );
  }

  // --- Beauty Products Methods (shared) ---

  Future<void> seedBeautyProducts() async {
    final db = await instance.database;
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM beauty_products'),
    );

    if (count != null && count > 0) {
      print('✅ Beauty products already exist. Skipping seed.');
      return;
    }

    print('🚀 Seeding beauty products...');

    final List<Map<String, dynamic>> products = [
      // ----- Foundation -----
      // Fair + Cool
      {
        "name": "True Match Foundation",
        "brand": "L’Oréal",
        "category": "Foundation",
        "shade": "C1 Alabaster",
        "skinTone": "Fair",
        "undertone": "Cool",
        "imageUrl": "assets/images/foundation_fair_cool.png",
        "description":
            "Lightweight, hydrating foundation for fair skin with cool undertones.",
      },
      // Fair + Neutral
      {
        "name": "Skin Long-Wear Foundation",
        "brand": "Estée Lauder",
        "category": "Foundation",
        "shade": "1N0 Porcelain",
        "skinTone": "Fair",
        "undertone": "Neutral",
        "imageUrl": "assets/images/foundation_fair_neutral.png",
        "description": "24h wear, natural matte finish for fair neutral skin.",
      },
      // Fair + Warm
      {
        "name": "Fit Me Matte + Poreless",
        "brand": "Maybelline",
        "category": "Foundation",
        "shade": "110 Porcelain",
        "skinTone": "Fair",
        "undertone": "Warm",
        "imageUrl": "assets/images/foundation_fair_warm.png",
        "description":
            "Controls oil, minimizes pores – perfect for fair warm skin.",
      },

      // Medium + Cool
      {
        "name": "Studio Fix Fluid",
        "brand": "MAC",
        "category": "Foundation",
        "shade": "NC20",
        "skinTone": "Medium",
        "undertone": "Cool",
        "imageUrl": "assets/images/foundation_medium_cool.png",
        "description": "Medium buildable coverage with a natural satin finish.",
      },
      // Medium + Neutral
      {
        "name": "Double Wear Foundation",
        "brand": "Estée Lauder",
        "category": "Foundation",
        "shade": "2N1 Desert Beige",
        "skinTone": "Medium",
        "undertone": "Neutral",
        "imageUrl": "assets/images/foundation_medium_neutral.png",
        "description":
            "Oil‑free, long‑lasting foundation for medium neutral skin.",
      },
      // Medium + Warm
      {
        "name": "Radiant Liquid Foundation",
        "brand": "NARS",
        "category": "Foundation",
        "shade": "Santa Fe",
        "skinTone": "Medium",
        "undertone": "Warm",
        "imageUrl": "assets/images/foundation_medium_warm.png",
        "description": "Light diffusing, improves skin clarity.",
      },

      // Olive + Cool
      {
        "name": "Hydro Boost Tint",
        "brand": "Neutrogena",
        "category": "Foundation",
        "shade": "Olive Cool",
        "skinTone": "Olive",
        "undertone": "Cool",
        "imageUrl": "assets/images/foundation_olive_cool.png",
        "description": "Hydrating gel formula, sheer to medium coverage.",
      },
      // Olive + Neutral
      {
        "name": "Pro Filt’r Foundation",
        "brand": "Fenty Beauty",
        "category": "Foundation",
        "shade": "145",
        "skinTone": "Olive",
        "undertone": "Neutral",
        "imageUrl": "assets/images/foundation_olive_neutral.png",
        "description": "Soft matte, oil‑free, suits olive neutral skin.",
      },
      // Olive + Warm
      {
        "name": "Healthy Foundation",
        "brand": "Clinique",
        "category": "Foundation",
        "shade": "Olive Warm",
        "skinTone": "Olive",
        "undertone": "Warm",
        "imageUrl": "assets/images/foundation_olive_warm.png",
        "description": "Vitamin C enriched, evens skin tone.",
      },

      // Brown + Cool
      {
        "name": "ColorStay Foundation",
        "brand": "Revlon",
        "category": "Foundation",
        "shade": "Caramel",
        "skinTone": "Brown",
        "undertone": "Cool",
        "imageUrl": "assets/images/foundation_brown_cool.png",
        "description": "Long-wear, medium to full coverage.",
      },
      // Brown + Neutral
      {
        "name": "Born This Way Foundation",
        "brand": "Too Faced",
        "category": "Foundation",
        "shade": "Caramel",
        "skinTone": "Brown",
        "undertone": "Neutral",
        "imageUrl": "assets/images/foundation_brown_neutral.png",
        "description": "Coconut water infused, hydrating.",
      },
      // Brown + Warm
      {
        "name": "Match Perfection",
        "brand": "Rimmel",
        "category": "Foundation",
        "shade": "Warm Bronze",
        "skinTone": "Brown",
        "undertone": "Warm",
        "imageUrl": "assets/images/foundation_brown_warm.png",
        "description": "Soft focus effect, blurs imperfections.",
      },

      // Dark + Cool
      {
        "name": "Teint Idole Ultra",
        "brand": "Lancôme",
        "category": "Foundation",
        "shade": "500 Cool",
        "skinTone": "Dark",
        "undertone": "Cool",
        "imageUrl": "assets/images/foundation_dark_cool.png",
        "description": "Oil‑free, breathable full coverage.",
      },
      // Dark + Neutral
      {
        "name": "Superstay Foundation",
        "brand": "Maybelline",
        "category": "Foundation",
        "shade": "Dark Neutral",
        "skinTone": "Dark",
        "undertone": "Neutral",
        "imageUrl": "assets/images/foundation_dark_neutral.png",
        "description": "Up to 30h wear, matte finish.",
      },
      // Dark + Warm
      {
        "name": "Fenty Pro Filt’r",
        "brand": "Fenty Beauty",
        "category": "Foundation",
        "shade": "490",
        "skinTone": "Dark",
        "undertone": "Warm",
        "imageUrl": "assets/images/foundation_dark_warm.png",
        "description": "Rich pigment, sweat‑ and humidity‑resistant.",
      },

      // ----- Concealer (sensitive‑friendly) -----
      {
        "name": "Radiant Creamy Concealer",
        "brand": "NARS",
        "category": "Concealer",
        "shade": "Vanilla",
        "skinTone": "Fair",
        "undertone": "Neutral",
        "imageUrl": "assets/images/concealer_sensitive.png",
        "description":
            "Vitamin E & light‑diffusing powders – safe for sensitive eyes.",
      },
      {
        "name": "Fit Me Concealer",
        "brand": "Maybelline",
        "category": "Concealer",
        "shade": "Medium",
        "skinTone": "Medium",
        "undertone": "Neutral",
        "imageUrl": "assets/images/concealer_medium.png",
        "description":
            "Non‑comedogenic, fragrance‑free, suitable for sensitive skin.",
      },
      {
        "name": "Glow & Hide Concealer",
        "brand": "The Ordinary",
        "category": "Concealer",
        "shade": "Olive 1",
        "skinTone": "Olive",
        "undertone": "Neutral",
        "imageUrl": "assets/images/concealer_olive.png",
        "description": "High coverage, no alcohol or oil, sensitive‑approved.",
      },
      {
        "name": "Age Rewind Concealer",
        "brand": "Maybelline",
        "category": "Concealer",
        "shade": "Brown",
        "skinTone": "Brown",
        "undertone": "Neutral",
        "imageUrl": "assets/images/concealer_brown.png",
        "description": "Hypoallergenic, infused with goji berry.",
      },
      {
        "name": "Studio Fix Concealer",
        "brand": "MAC",
        "category": "Concealer",
        "shade": "NW50",
        "skinTone": "Dark",
        "undertone": "Cool",
        "imageUrl": "assets/images/concealer_dark.png",
        "description": "Dermatologist tested, suitable for sensitive skin.",
      },

      // ----- Powder (sensitive options) -----
      {
        "name": "Mineral Veil Powder",
        "brand": "bareMinerals",
        "category": "Powder",
        "shade": "Translucent",
        "skinTone": "All",
        "undertone": "All",
        "imageUrl": "assets/images/powder_sensitive.png",
        "description": "Talc‑free, non‑irritating, sets makeup without drying.",
      },
      {
        "name": "Stay Matte Powder",
        "brand": "Rimmel",
        "category": "Powder",
        "shade": "Transparent",
        "skinTone": "All",
        "undertone": "All",
        "imageUrl": "assets/images/powder_matte.png",
        "description":
            "Oil‑absorbing, fragrance‑free, safe for sensitive skin.",
      },
    ];

    for (var product in products) {
      await db.insert('beauty_products', product);
      print(
        '   ✅ Added: ${product['name']} (${product['skinTone']} / ${product['undertone']})',
      );
    }

    print('🎉 Beauty products seeding complete! (${products.length} items)');
  }

  Future<List<Map<String, dynamic>>> queryBeautyProducts(
    String skinTone,
    String undertone,
  ) async {
    final db = await instance.database;
    final normalizedTone = skinTone.toLowerCase();
    final normalizedUndertone = undertone.toLowerCase();

    return await db.query(
      'beauty_products',
      where:
          '(LOWER(skinTone) = ? OR LOWER(skinTone) = ?) AND (LOWER(undertone) = ? OR LOWER(undertone) = ?)',
      whereArgs: [normalizedTone, 'all', normalizedUndertone, 'all'],
      limit: 10,
    );
  }
}
