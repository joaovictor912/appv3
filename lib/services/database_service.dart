import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/aluno.dart';
import '../models/prova.dart';
import '../models/turma.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;
  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('app_database.v1.db'); // Adicionado .v1 para futuras migrações
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  /// CRIAÇÃO DE TODAS AS TABELAS DO APLICATIVO
  Future<void> _createDB(Database db, int version) async {
    // Tabela de Turmas
    await db.execute('''
      CREATE TABLE turmas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT NOT NULL,
        userId TEXT NOT NULL
      )
    ''');

    // Tabela de Provas
    await db.execute('''
      CREATE TABLE provas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT NOT NULL,
        data TEXT NOT NULL,
        numeroDeQuestoes INTEGER NOT NULL,
        gabaritoOficial TEXT NOT NULL,
        turmaId INTEGER NOT NULL,
        userId TEXT NOT NULL,
        FOREIGN KEY (turmaId) REFERENCES turmas (id) ON DELETE CASCADE
      )
    ''');

    // Tabela de Alunos
    await db.execute('''
      CREATE TABLE alunos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT NOT NULL,
        matricula TEXT,
        turmaId INTEGER NOT NULL,
        userId TEXT NOT NULL,
        FOREIGN KEY (turmaId) REFERENCES turmas (id) ON DELETE CASCADE
      )
    ''');
  }

  // --- MÉTODOS PARA TURMAS ---
  Future<Turma> createTurma(String nome) async {
    final db = await instance.database;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("Usuário não autenticado.");

    final turmaData = {'nome': nome, 'userId': user.uid};
    final id = await db.insert('turmas', turmaData);
    return Turma(id: id, nome: nome);
  }
  
  Future<int> updateTurma(Turma turma) async {
    final db = await instance.database;
    if (turma.id == null) throw Exception("ID da turma não pode ser nulo para atualizar.");
    return db.update('turmas', turma.toMap(), where: 'id = ?', whereArgs: [turma.id]);
  }

  Future<int> deleteTurma(int id) async {
    final db = await instance.database;
    return await db.delete('turmas', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Turma>> getTurmas() async {
  final db = await instance.database;
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return [];

  final maps = await db.query('turmas', where: 'userId = ?', whereArgs: [user.uid]);
  
  // AGORA, ele só retorna a lista de turmas, sem carregar os detalhes (alunos e provas).
  // Isso é muito mais rápido e eficiente.
  return List.generate(maps.length, (i) => Turma.fromMap(maps[i]));
}

  // --- MÉTODOS PARA PROVAS ---
  Future<int> createProva(Prova prova, int turmaId) async {
    final db = await instance.database;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("Usuário não autenticado.");
    
    final map = prova.toMap();
    map['turmaId'] = turmaId;
    map['userId'] = user.uid;
    
    // Remove o ID do mapa, pois ele será gerado pelo banco
    map.remove('id');

    return await db.insert('provas', map);
  }

  Future<List<Prova>> getProvasParaTurma(int turmaId) async {
    final db = await instance.database;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    final maps = await db.query('provas', where: 'turmaId = ? AND userId = ?', whereArgs: [turmaId, user.uid]);
    return List.generate(maps.length, (i) => Prova.fromMap(maps[i]));
  }

  Future<int> deleteProva(int id) async {
    final db = await instance.database;
    return await db.delete('provas', where: 'id = ?', whereArgs: [id]);
  }

  // --- MÉTODOS PARA ALUNOS (BÔNUS) ---
  // Adicionei os métodos para Alunos, pois você vai precisar deles em breve.
  Future<int> createAluno(Aluno aluno, int turmaId) async {
    final db = await instance.database;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("Usuário não autenticado.");

    final map = aluno.toMap();
    map['turmaId'] = turmaId;
    map['userId'] = user.uid;
    map.remove('id');

    return await db.insert('alunos', map);
  }

  Future<List<Aluno>> getAlunosParaTurma(int turmaId) async {
    final db = await instance.database;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];
    
    final maps = await db.query('alunos', where: 'turmaId = ? AND userId = ?', whereArgs: [turmaId, user.uid]);
    return List.generate(maps.length, (i) => Aluno.fromMap(maps[i]));
  }

  Future<int> deleteAluno(int id) async {
    final db = await instance.database;
    return await db.delete('alunos', where: 'id = ?', whereArgs: [id]);
  }

  // Fecha o banco de dados (útil para gerenciamento avançado de estado)
  Future close() async {
    final db = await instance.database;
    db.close();
  }
  Future<Turma> getTurmaById(int id) async {
  final db = await instance.database;
  final maps = await db.query(
    'turmas',
    where: 'id = ?',
    whereArgs: [id],
  );

  if (maps.isNotEmpty) {
    final turma = Turma.fromMap(maps.first);
    // Carrega os detalhes da turma
    turma.alunos = await getAlunosParaTurma(turma.id!);
    turma.provas = await getProvasParaTurma(turma.id!);
    return turma;
  } else {
    throw Exception('Turma com ID $id não encontrada.');
  }
}
}