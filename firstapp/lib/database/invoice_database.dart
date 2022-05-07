import 'dart:async';
import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class Header {
  String date;
  String time;
  String seller;
  String address;
  String inv_num;
  String barcode;
  String amount;

  Header({
    required this.date,
    required this.time,
    required this.seller,
    required this.address,
    required this.inv_num,
    required this.barcode,
    required this.amount,
  });
  factory Header.fromMap(Map<String, dynamic> json) => new Header(
        date: json['date'],
        time: json['time'],
        seller: json['seller'],
        address: json['address'],
        inv_num: json['inv_num'],
        barcode: json['barcode'],
        amount: json['amount'],
      );
  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'time': time,
      'seller': seller,
      'address': address,
      'inv_num': inv_num,
      'barcode': barcode,
      'amount': amount,
    };
  }
}

class HeaderHelper {
  HeaderHelper._privateConstructor();
  static final HeaderHelper instance = HeaderHelper._privateConstructor();

  static Database? _database;

  Future<Database> get database async => _database ??= await _initDatabase();

  Future<Database> _initDatabase() async {
    Directory documensDirectory = await getApplicationDocumentsDirectory();
    String path = join(documensDirectory.path, 'header.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE HEADER(id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,date TEXT,time TEXT,seller TEXT,address TEXT,inv_num TEXT,barcode TEXT,amount TEXT)
''');
  }

  Future<List<Header>> getHeader() async {
    Database db = await instance.database;
    var header = await db.query('header', orderBy: 'id');
    List<Header> headerList =
        header.isNotEmpty ? header.map((c) => Header.fromMap(c)).toList() : [];
    return headerList;
  }

  Future<int> add(Header header) async {
    Database db = await instance.database;
    return await db.insert('header', header.toMap());
  }

  Future<void> delete() async {
    Database db = await instance.database;
    await db.delete('header');
  }
}