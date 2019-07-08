import 'dart:io';
import 'dart:typed_data';

import 'package:hive/src/adapters/date_time_adapter.dart';
import 'package:hive/src/adapters/uint8_list_adapter.dart';
import 'package:hive/src/hive_instance_impl.dart';
import 'package:test/test.dart';
import 'package:path/path.dart' as path;

import 'common.dart';

void main() {
  test("home", () {
    var hive = HiveInstanceImpl();

    expect(() => hive.home, throwsHiveError("not initialized"));

    hive.init("MYPATH");
    expect(hive.home.path, "MYPATH");
  });

  test("init", () {
    var hive = HiveInstanceImpl();

    hive.init("MYPATH");
    expect(hive.home.path, "MYPATH");

    hive.init("OTHERPATH");
    expect(hive.home.path, "OTHERPATH");

    expect(hive.findAdapterForType(Uint8List).adapter, isA<Uint8ListAdapter>());
    expect(hive.findAdapterForTypeId(16).adapter, isA<Uint8ListAdapter>());

    expect(hive.findAdapterForType(DateTime).adapter, isA<DateTimeAdapter>());
    expect(hive.findAdapterForTypeId(17).adapter, isA<DateTimeAdapter>());
  });

  group("box()", () {
    test("opened box is returned if it exists", () async {
      var tempDir = await getTempDir();
      var hive = HiveInstanceImpl();
      hive.init(tempDir.path);

      var testBox = await hive.box("testBox");
      var testBox2 = await hive.box("testBox");
      expect(testBox, testBox2);
    });

    test("home directory is created", () async {
      var tempDir = await getTempDir();
      var hive = HiveInstanceImpl();

      var hivePath = path.join(tempDir.path, "somePath");
      hive.init(hivePath);
      await hive.box("testBox");

      expect(await Directory(hivePath).exists(), true);
    });
  });

  test("closeAll()", () async {
    var tempDir = await getTempDir();
    var hive = HiveInstanceImpl();
    hive.init(tempDir.path);

    var box1 = await hive.box("box1");
    var box2 = await hive.box("box2");
    expect(box1.isOpen, true);
    expect(box2.isOpen, true);

    await hive.close();
    expect(box1.isOpen, false);
    expect(box2.isOpen, false);
  });

  test("generateSecureKey()", () {
    var hive = HiveInstanceImpl();

    var key1 = hive.generateSecureKey();
    var key2 = hive.generateSecureKey();

    expect(key1.length, 32);
    expect(key2.length, 32);
    expect(key1, isNot(key2));
  });

  test("deleteFromDisk", () async {
    var dir = await getTempDir();
    var hive = HiveInstanceImpl();
    hive.init(dir.path);

    var box1 = await hive.box("testBox1");
    await box1.put("key", "value");
    var box1File = box1.getBoxFile();

    var box2 = await hive.box("testBox2");
    await box2.put("key", "value");
    var box2File = box1.getBoxFile();

    await hive.deleteFromDisk();
    expect(await box1File.exists(), false);
    expect(await box2File.exists(), false);
    expect(hive.isBoxOpen("testBox1"), false);
    expect(hive.isBoxOpen("testBox2"), false);
  });
}